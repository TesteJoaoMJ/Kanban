<template>
  <v-layout
    @click.once="unlockAudio"
    @touchend.once="unlockAudio"
    :style="cssVars"
    class="w-100 h-100"
  >
    <div v-if="themeStore.currentMode === 'glass'" class="background-container" :style="{ backgroundImage: `url(${currentBackground})` }">
      <div class="particles-overlay"></div>
    </div>
    <div v-else class="background-solid" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-4'"></div>

    <audio ref="notificationSoundRef" src="https://cdn.shopify.com/s/files/1/0661/4574/6991/files/ding-101492.mp3?v=1755543134" preload="auto"></audio>
    <audio ref="alertSound" src="https://cdn.shopify.com/s/files/1/0661/4574/6991/files/new-notification-022-370046.mp3?v=1757327480" preload="auto" loop></audio>

    <audio ref="sendMessageSoundRef" :src="sendMessageSoundUrl" preload="auto"></audio>
    <audio ref="receiveMessageSoundRef" :src="receiveMessageSoundUrl" preload="auto"></audio>

    <teleport to="body">
        <div class="persistent-toast-wrapper">
          <transition-group name="toast-anim" tag="div" class="d-flex flex-column toast-container-gap">
            <div
              v-for="toast in persistentToasts"
              :key="toast.id"
              class="modern-toast"
              :class="toast.typeClass"
              @click="handleToastClick(toast)"
            >
              <div class="toast-content-wrapper">
                 <div class="d-flex align-center justify-space-between mb-1">
                    <div class="d-flex align-center gap-2">
                       <v-avatar v-if="toast.isChat" size="24" class="elevation-2 border-1 border-white border-opacity-50">
                           <v-img :src="toast.avatar"></v-img>
                       </v-avatar>
                       <v-icon v-else size="22" class="mr-1">{{ toast.icon }}</v-icon>
                       <span class="text-subtitle-2 font-weight-bold">
                          {{ toast.title }}
                       </span>
                    </div>
                    <div class="d-flex align-center">
                        <span class="text-[10px] font-weight-bold opacity-80 mr-2">
                            {{ formatDistance(toast.created_at) }}
                        </span>
                        <v-btn icon variant="text" size="x-small" @click.stop="closePersistentToast(toast.id)">
                            <v-icon size="16">mdi-close</v-icon>
                        </v-btn>
                    </div>
                 </div>

                 <div class="pl-1 mt-1">
                    <p class="text-body-2 opacity-90 mb-0 leading-tight">
                        {{ toast.message }}
                    </p>
                    <div v-if="toast.subtext" class="text-caption opacity-70 mt-1 font-italic">
                        {{ toast.subtext }}
                    </div>
                 </div>

                 <div v-if="toast.canContest" class="mt-3 d-flex justify-end border-t border-opacity-25 pt-2">
                    <v-btn
                        size="small"
                        color="white"
                        variant="outlined"
                        class="font-weight-bold bg-black-20"
                        density="compact"
                        :loading="toast.processing"
                        @click.stop="handleContest(toast)"
                    >
                        <v-icon start size="16">mdi-undo-variant</v-icon>
                        Contestar Ação
                    </v-btn>
                 </div>
              </div>
            </div>
          </transition-group>
        </div>
    </teleport>

    <teleport to="body">
      <div class="chat-toast-wrapper">
        <transition-group name="chat-toast-anim" tag="div" class="d-flex flex-column gap-2 w-100">
          <div
            v-for="toast in chatToasts"
            :key="toast.id"
            class="chat-glass-toast"
            @click="toast.isTask ? goToTasks() : openMiniChat(toast.channelId, toast.id)"
          >
            <div class="d-flex align-center w-100 overflow-hidden">
              <v-avatar size="36" class="flex-shrink-0 mr-3 elevation-3 border-thin border-white border-opacity-50" :color="toast.isTask ? 'warning' : ''">
                <v-img v-if="toast.avatar && !toast.isTask" :src="toast.avatar"></v-img>
                <v-icon v-else-if="toast.isTask" color="white">mdi-clipboard-check</v-icon>
              </v-avatar>

              <div class="d-flex flex-column flex-grow-1 overflow-hidden" style="min-width: 0;">
                <div class="d-flex justify-space-between align-center w-100 mb-1">
                  <span class="text-subtitle-2 font-weight-bold text-white text-truncate" style="font-size: 14px !important;">
                    {{ toast.title }}
                  </span>
                  <span class="text-white flex-shrink-0 ml-2" :class="toast.isTask ? 'text-warning' : ''" style="font-size: 8px !important; opacity: 0.8; letter-spacing: 0.5px; text-transform: uppercase; font-weight: 900;">
                    {{ toast.isTask ? 'Nova Tarefa' : 'Nova Mensagem' }}
                  </span>
                </div>
                <span class="text-white opacity-85 text-truncate d-block w-100" style="font-size: 13px;">
                  {{ toast.message }}
                </span>
              </div>
            </div>
          </div>
        </transition-group>
      </div>
    </teleport>

    <teleport to="body">
      <transition name="fade-overlay">
        <div v-if="isLoggingOut" class="logout-overlay-premium d-flex flex-column align-center justify-center">
          <v-progress-circular indeterminate size="64" color="primary" width="4" class="mb-6"></v-progress-circular>
          <h2 class="text-h4 font-weight-black text-white mb-2" style="letter-spacing: 1px;">Encerrando Sessão</h2>
          <p class="text-subtitle-1 text-white opacity-70">Limpando dados de forma segura...</p>
        </div>
      </transition>
    </teleport>

    <v-app-bar
      app
      elevation="0"
      height="64"
      class="border-b"
      :color="isLightMode ? 'rgba(255,255,255,0.95)' : 'rgba(20,20,25,0.9)'"
      :class="isLightMode ? 'border-grey-lighten-2' : 'border-grey-darken-3'"
      style="backdrop-filter: blur(12px);"
    >
      <div class="d-flex align-center justify-space-between w-100 px-2 px-md-4 position-relative">

      <v-btn icon variant="text" size="small" color="default" @click.stop="toggleRail" v-if="!isMobile">
        <v-icon>{{ rail ? 'mdi-menu' : 'mdi-menu-open' }}</v-icon>
      </v-btn>
        <v-app-bar-nav-icon v-else @click.stop="drawer = !drawer"></v-app-bar-nav-icon>

        <div class="elegant-search-wrapper shimmer-search" :class="{ 'mobile-search': isMobile, 'search-active-state': isSearchActive }">
           <v-text-field
             ref="searchInputRef"
             v-model="searchQuery"
             :placeholder="isMobile ? 'Buscar...' : 'Pesquisar telas e ferramentas...'"
             prepend-inner-icon="mdi-magnify"
             variant="outlined"
             density="compact"
             hide-details
             clearable
             class="elegant-search-input"
             @focus="isSearchActive = true"
             @click:clear="closeSearch"
             @keyup.esc="closeSearch"
           ></v-text-field>
        </div>

        <div class="d-flex align-center header-actions-container ml-auto" :class="{ 'opacity-0 pointer-events-none': isMobile && isSearchActive }" style="transition: opacity 0.3s ease;">

            <v-menu location="bottom end" offset="15" transition="slide-y-transition" :close-on-content-click="false" v-if="!isMobile">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" icon size="small" variant="text" :color="isLightMode ? 'primary' : 'blue-lighten-2'" class="mr-2 elegant-app-btn">
                  <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Hub de Aplicativos</v-tooltip>
                  <v-icon size="24">mdi-apps</v-icon>
                </v-btn>
              </template>

              <v-card :class="isLightMode ? 'glass-light-card' : 'glassmorphism-card-dialog'" width="440" class="border-thin shadow-xl rounded-xl overflow-hidden">
                <div class="px-5 py-4 border-b d-flex align-center justify-space-between" :class="isLightMode ? 'border-grey-lighten-2 bg-grey-50' : 'border-white-05 bg-white-02'">
                    <span class="text-[11px] font-weight-bold text-uppercase tracking-widest opacity-70" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">Launchpad de Módulos</span>
                    <v-icon size="16" class="opacity-40">mdi-rocket-launch-outline</v-icon>
                </div>

                <div class="pa-4 custom-scrollbar" style="max-height: 520px; overflow-y: auto;">

                  <div class="app-category-label">Módulos em Foco</div>

                  <div class="premium-app-card" @click="focusAppModule('design', 'DesignKanban')" v-if="userStore.hasPermission('des_kanban') || userStore.hasPermission('des_request') || userStore.hasPermission('mfg_approvals')" style="animation-delay: 0.05s">
                      <div class="app-icon-3d gradient-design">
                         <v-icon color="white">mdi-palette-swatch-outline</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Estúdio de Design</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Aprovações e Catálogo</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <div class="premium-app-card" @click="focusAppModule('storefront', 'StorefrontManager')" v-if="userStore.hasPermission('admin_integrations')" style="animation-delay: 0.1s">
                      <div class="app-icon-3d gradient-storefront">
                         <v-icon color="white">mdi-storefront-outline</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Marketplace B2B</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Portal de Vendas e Leads</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <div class="premium-app-card" @click="focusAppModule('rh', 'EmployeeManagement')" v-if="userStore.hasPermission('cad_employees') || userStore.hasPermission('rh_ponto')" style="animation-delay: 0.15s">
                      <div class="app-icon-3d gradient-rh">
                         <v-icon color="white">mdi-account-group-outline</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Recursos Humanos</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Dossiês, Ponto e Benefícios</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <div class="premium-app-card" @click="focusAppModule('fleet', 'FleetVehicles')" v-if="userStore.hasPermission('fleet_vehicles')" style="animation-delay: 0.2s">
                      <div class="app-icon-3d gradient-fleet">
                         <v-icon color="white">mdi-car-multiple</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Gestão de Frota</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Veículos e Abastecimento</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <v-divider class="my-4 border-opacity-10"></v-divider>
                  <div class="app-category-label">Ferramentas & Integrações</div>

                  <div class="premium-app-card" @click="goToApp('EmailManager')" v-if="userStore.hasPermission('admin_general')" style="animation-delay: 0.25s">
                      <div class="app-icon-3d gradient-email">
                         <v-icon color="white">mdi-email-fast-outline</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Correio Eletrônico</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Gestão de E-mails e Campanhas</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <div class="premium-app-card" @click="focusAppModule('finance', 'FinancialAccounts')" v-if="userStore.hasPermission('fin_accounts')" style="animation-delay: 0.3s">
                      <div class="app-icon-3d gradient-finance">
                         <v-icon color="white">mdi-bank-outline</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Bancos e Contas</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Cora, Sicredi e Conciliação</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-chevron-right</v-icon>
                  </div>

                  <a href="https://gestaoclick.com/login" target="_blank" class="premium-app-card text-decoration-none" style="animation-delay: 0.35s">
                      <div class="app-icon-3d gradient-erp">
                         <v-icon color="white">mdi-link-variant</v-icon>
                      </div>
                      <div class="app-text">
                          <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">GestãoClick ERP</span>
                          <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">Acesso ao sistema legado externo</span>
                      </div>
                      <v-icon class="ml-auto opacity-30" size="18">mdi-open-in-new</v-icon>
                  </a>

                  <template v-if="userStore.isSuperAdmin">
                    <v-divider class="my-4 border-opacity-10"></v-divider>
                    <div class="app-category-label">Sistema Avançado</div>

                    <div class="premium-app-card" @click="companyStore.toggleDemoMode()" style="animation-delay: 0.4s">
                        <div class="app-icon-3d transition-all" :class="companyStore.isDemoMode ? 'gradient-demo-active pulse-demo-border' : 'gradient-demo'">
                          <v-icon color="white">{{ companyStore.isDemoMode ? 'mdi-incognito' : 'mdi-presentation-play' }}</v-icon>
                        </div>
                        <div class="app-text">
                            <span class="title" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Modo Apresentação</span>
                            <span class="subtitle" :class="isLightMode ? 'text-grey-darken-2' : 'text-white-70'">{{ companyStore.isDemoMode ? 'Ativo (Dados Sensíveis Ocultos)' : 'Ocultar dados para demonstração' }}</span>
                        </div>
                    </div>
                  </template>
                </div>
              </v-card>
            </v-menu>

            <v-btn icon size="small" variant="text" :color="isLightMode ? 'orange-darken-1' : 'yellow-accent-2'" @click="toggleTheme" v-if="!isMobile">
              <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Alternar Tema</v-tooltip>
              <v-icon size="22">{{ isLightMode ? 'mdi-white-balance-sunny' : 'mdi-moon-waning-crescent' }}</v-icon>
            </v-btn>

            <v-btn v-if="userStore.currentModule === 'mj' && userStore.hasPermission('admin_general')" :to="{ name: 'Admin' }" icon size="small" variant="text" :color="isLightMode ? 'grey-darken-3' : 'grey-lighten-1'">
              <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Admin MJ</v-tooltip>
              <v-icon size="22">mdi-security</v-icon>
            </v-btn>

            <v-btn v-if="userStore.currentModule === 'cajuia' && userStore.hasPermission('cajuia_admin')" :to="{ name: 'CajuiaAdmin' }" icon size="small" variant="text" :color="isLightMode ? 'grey-darken-3' : 'grey-lighten-1'">
              <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Admin Cajuia</v-tooltip>
              <v-icon size="22">mdi-store-cog-outline</v-icon>
            </v-btn>

            <div style="width: 1px; height: 20px; background-color: currentColor; opacity: 0.15; margin: 0 4px;" v-if="!isMobile"></div>

            <v-btn v-if="canAccessChat" icon size="small" variant="text" :color="isLightMode ? 'grey-darken-3' : 'grey-lighten-1'" :to="{ name: 'Chat' }">
              <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Chat Interno</v-tooltip>
              <v-badge :content="chatStore.totalUnreadCount" color="primary" :model-value="chatStore.totalUnreadCount > 0">
                <v-icon size="22">mdi-forum-outline</v-icon>
              </v-badge>
            </v-btn>

            <v-btn icon size="small" variant="text" :color="isLightMode ? 'grey-darken-3' : 'grey-lighten-1'" @click="notificationDrawer = !notificationDrawer">
              <v-tooltip activator="parent" location="bottom" content-class="custom-tooltip bg-grey-darken-4 text-white">Notificações</v-tooltip>
              <v-badge :content="unreadNotifications" color="error" :model-value="unreadNotifications > 0" dot>
                <v-icon size="22" :class="{ 'bell-ringing': isBellRinging }">mdi-bell-outline</v-icon>
              </v-badge>
            </v-btn>

            <div style="width: 1px; height: 20px; background-color: currentColor; opacity: 0.15; margin: 0 4px;" v-if="!isMobile"></div>

            <v-menu location="bottom end" offset="10">
              <template v-slot:activator="{ props }">
                <div v-bind="props" class="d-flex align-center cursor-pointer ml-1">
                  <v-avatar :image="profile?.avatar_url || ''" size="36" class="elevation-2 border-1" :class="isLightMode ? 'border-grey-lighten-2' : 'border-grey-darken-2'"></v-avatar>
                </div>
              </template>
              <v-card width="220" class="pa-3 border-thin shadow-xl" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-4'">
                <div class="text-center mb-3">
                  <v-avatar :image="profile?.avatar_url || ''" size="64" class="mb-2 shadow-sm"></v-avatar>
                  <div class="font-weight-black text-body-2" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ profile?.full_name || 'Usuário' }}</div>
                  <div class="text-caption opacity-70" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">{{ userStore.user?.email }}</div>
                  <v-chip size="x-small" density="compact" class="mt-2 text-uppercase font-weight-bold" :color="isLightMode ? 'primary' : 'success'" variant="tonal">{{ userCustomRoleName || profile?.role || userStore.cajuiaRole || 'Usuário' }}</v-chip>
                </div>

                <v-list density="compact" nav class="bg-transparent" v-if="isMobile">
                  <v-divider class="mb-1 border-opacity-25"></v-divider>
                  <v-list-item @click="toggleTheme" rounded="lg">
                    <template #prepend><v-icon size="18" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ isLightMode ? 'mdi-moon-waning-crescent' : 'mdi-white-balance-sunny' }}</v-icon></template>
                    <v-list-item-title class="text-caption font-weight-bold" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ isLightMode ? 'Modo Escuro' : 'Modo Claro' }}</v-list-item-title>
                  </v-list-item>
                </v-list>

            <v-list density="compact" nav class="bg-transparent">
              <v-list-item @click="router.push({ name: 'UserProfile' })" rounded="sm">
                <template #prepend><v-icon size="18">mdi-account-circle-outline</v-icon></template>
                <v-list-item-title class="text-caption font-weight-bold">Meu Perfil</v-list-item-title>
              </v-list-item>
              <v-divider class="mb-1 border-opacity-25"></v-divider>
              </v-list>

                <v-btn block size="small" color="error" variant="flat" class="font-weight-bold" @click="handleLogout">
                  <v-icon start size="16">mdi-logout</v-icon> Sair
                </v-btn>
              </v-card>
            </v-menu>

        </div>
      </div>
    </v-app-bar>

    <v-navigation-drawer
      v-model="drawer"
      app
      :permanent="!isMobile"
      :temporary="isMobile"
      class="glassmorphism-sidebar premium-drawer"
      :class="[isLightMode ? 'glass-light' : 'glass-dark', { 'rail-mode': rail }]"
      :width="320"
      :rail="rail"
      expand-on-hover
      border="0"
      @click="handleDrawerClick"
    >
      <div
        class="logo-container d-flex justify-center align-center py-4 overflow-hidden"
        :class="{'rail-logo': rail}"
        @click.stop="router.push(logoRoute)"
        style="cursor: pointer;"
      >
          <div class="logo-wrapper transition-all d-flex align-center justify-center">
              <img
                :src="displayLogo"
                class="logo-img"
                :class="{'logo-img-rail': rail}"
                alt="Logo"
              />
          </div>
      </div>

      <div class="px-3 py-2 transition-all" style="flex-shrink: 0;">
        <v-menu
            location="bottom center"
            offset="4"
            :close-on-content-click="true"
            transition="slide-y-transition"
            :disabled="!canChangeCompany"
        >
            <template v-slot:activator="{ props }">
                <div v-bind="props" class="context-selector-minimal" :class="{'rail-context': rail, 'cursor-pointer': canChangeCompany}">
                    <div v-if="rail" class="d-flex justify-center align-center w-100">
                        <v-avatar size="28" :color="companyStore.isGlobalView ? 'purple-darken-1' : 'blue-darken-1'" variant="tonal">
                           <v-icon size="14">{{ companyStore.isGlobalView ? 'mdi-earth' : 'mdi-domain' }}</v-icon>
                        </v-avatar>
                    </div>

                    <v-card
                        v-else
                        variant="flat"
                        class="pa-2 rounded-lg d-flex align-center justify-space-between border-thin"
                        :class="[isLightMode ? 'border-grey-lighten-2 bg-white' : 'border-grey-darken-3 bg-grey-darken-4', canChangeCompany ? 'bg-transparent-hover' : 'bg-transparent']"
                        style="transition: 0.2s;"
                        height="44"
                    >
                        <div class="d-flex align-center overflow-hidden">
                            <div class="icon-box-mini rounded mr-2 d-flex align-center justify-center flex-shrink-0"
                                :class="companyStore.isGlobalView ? 'bg-purple-subtle' : 'bg-blue-subtle'" style="width: 24px; height: 24px;">
                                <v-icon size="14" :color="companyStore.isGlobalView ? 'purple' : 'blue'">
                                    {{ companyStore.isGlobalView ? 'mdi-earth' : 'mdi-domain' }}
                                </v-icon>
                            </div>

                            <div class="d-flex flex-column overflow-hidden" style="line-height: 1.1;">
                                <span class="font-weight-bold text-truncate"
                                      :class="isLightMode ? 'text-grey-darken-4' : 'text-white'"
                                      style="font-size: 11px;">
                                  {{ companyStore.currentCompanyName }}
                                </span>
                                <span v-if="companyStore.currentCompanyCnpj" class="font-mono opacity-60 text-truncate mt-0" style="font-size: 8px;">
                                  {{ companyStore.currentCompanyCnpj }}
                                </span>
                                <span v-else class="text-[8px] font-weight-medium text-uppercase opacity-50 tracking-wider mt-0">
                                  {{ companyStore.isGlobalView ? 'HOLDING' : 'UNIDADE' }}
                                </span>
                            </div>
                        </div>
                        <v-icon v-if="canChangeCompany" size="14" class="opacity-40" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">mdi-chevron-down</v-icon>
                        <v-icon v-else size="12" class="opacity-50" color="success">mdi-lock-outline</v-icon>
                    </v-card>
                </div>
            </template>

            <v-card width="260" class="rounded-xl elevation-10 border-thin overflow-hidden" :class="isLightMode ? 'bg-white' : 'bg-grey-darken-4'">
                <v-list density="compact" nav class="py-0 bg-transparent">
                    <div class="px-3 py-2 bg-surface-variant d-flex align-center justify-space-between">
                        <span class="text-[9px] font-weight-bold text-uppercase tracking-widest opacity-70" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Alternar Contexto</span>
                    </div>

                    <v-list-item @click="companyStore.setContext('global')" value="global" class="py-2 px-3" min-height="40">
                        <template v-slot:prepend>
                            <v-avatar size="24" color="purple-lighten-5" class="mr-3 text-purple-darken-2">
                                <v-icon size="14">mdi-earth</v-icon>
                            </v-avatar>
                        </template>
                        <v-list-item-title class="font-weight-bold text-caption" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Visão Global</v-list-item-title>
                        <template v-slot:append v-if="companyStore.isGlobalView">
                           <v-icon color="success" size="16" class="check-pop-animation">mdi-check-circle</v-icon>
                        </template>
                    </v-list-item>

                    <v-divider :class="isLightMode ? 'border-grey-lighten-2' : 'border-grey-darken-2'"></v-divider>

                    <div class="max-h-250 overflow-y-auto custom-scrollbar">
                        <v-list-item
                            v-for="company in companyStore.availableCompanies"
                            :key="company.id"
                            @click="companyStore.setContext(company.id)"
                            :value="company.id"
                            class="py-2 px-3"
                            min-height="40"
                        >
                            <template v-slot:prepend>
                                <v-avatar size="24" color="blue-lighten-5" class="mr-3 text-blue-darken-2">
                                    <v-icon size="14">mdi-office-building</v-icon>
                                </v-avatar>
                            </template>
                            <div class="d-flex flex-column lh-1">
                                <span class="font-weight-bold text-caption" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'" style="font-size: 11px !important;">
                                    {{ company.trade_name || company.name }}
                                </span>
                                <span class="font-mono opacity-60 mt-0" style="font-size: 8px;">{{ company.cnpj || 'CNPJ N/A' }}</span>
                            </div>
                            <template v-slot:append v-if="companyStore.context === company.id">
                               <v-icon color="success" size="16" class="check-pop-animation">mdi-check-circle</v-icon>
                            </template>
                        </v-list-item>
                    </div>
                </v-list>
            </v-card>
        </v-menu>
      </div>

      <v-divider class="mb-2 mt-1 mx-4" :class="isLightMode ? 'border-opacity-25' : 'border-opacity-10'"></v-divider>

      <div class="main-nav-list-wrapper custom-scrollbar px-2">
        <v-list dense nav class="pa-0 main-nav-list bg-transparent flat-hierarchy-list" v-model:opened="openedGroups">

          <template v-for="(group, i) in navigationGroups" :key="i">

            <v-list-item
                v-if="group.isBackButton"
                @click="clearAppFocus"
                rounded="lg"
                density="compact"
                class="mb-4 parent-item sidebar-3d-l0 bg-primary"
            >
                <template v-slot:prepend>
                    <div class="d-flex justify-center" style="width: 24px;">
                        <v-icon :icon="group.icon" class="small-icon fixed-size-icon text-white"></v-icon>
                    </div>
                </template>
                <v-list-item-title class="font-weight-bold text-uppercase ls-1 text-white force-small-header fixed-font-size ml-2">
                    {{ group.title }}
                </v-list-item-title>
            </v-list-item>

            <div v-else class="nav-group-wrapper mb-1">
                <v-list-group v-if="group.items && group.items.length > 0" :value="group.value" class="parent-group unified-block-group">
                  <template v-slot:activator="{ props, isOpen }">
                    <v-list-item
                        v-bind="props"
                        rounded="lg"
                        density="compact"
                        class="parent-item group-header-item mb-2 nav-level-0 sidebar-3d-l0"
                        :class="{'block-active-header': isOpen}"
                    >
                      <template v-slot:prepend>
                        <div class="d-flex justify-center" style="width: 24px;">
                            <v-icon :icon="group.icon" class="small-icon fixed-size-icon" :class="[isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-1']"></v-icon>
                        </div>
                      </template>
                      <v-list-item-title class="font-weight-bold text-uppercase ls-1 force-small-header fixed-font-size ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-2'">
                        {{ group.title }}
                      </v-list-item-title>
                    </v-list-item>
                  </template>

                  <div class="children-container mt-1">
                      <template v-for="(item, j) in group.items" :key="j">

                          <v-list-group v-if="item.children && item.children.length > 0" :value="item.title" class="sub-group nested-block-group">
                              <template v-slot:activator="{ props, isOpen }">
                                <v-list-item
                                    v-bind="props"
                                    rounded="lg"
                                    density="compact"
                                    class="child-item mb-1 nav-level-1 sidebar-3d-l1"
                                    :class="{'nested-block-active-header': isOpen}"
                                >
                                    <template v-slot:prepend>
                                        <div class="d-flex justify-center" style="width: 24px;">
                                            <v-icon :icon="item.icon" size="18" class="opacity-80" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'"></v-icon>
                                        </div>
                                    </template>
                                    <v-list-item-title class="font-weight-bold force-small-text fixed-font-size text-truncate ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-1'">
                                        {{ item.title }}
                                    </v-list-item-title>
                                </v-list-item>
                              </template>

                              <v-list-item
                                v-for="(subItem, k) in item.children"
                                :key="k"
                                :to="subItem.to"
                                :active="isRouteActive(subItem.to)"
                                rounded="lg"
                                density="compact"
                                class="grandchild-item mb-1 nav-level-2 sidebar-3d-l2"
                              >
                                <template v-slot:prepend>
                                    <div class="d-flex justify-center" style="width: 24px;">
                                        <v-icon :icon="subItem.icon || 'mdi-subdirectory-arrow-right'" size="16" class="opacity-70"></v-icon>
                                    </div>
                                </template>
                                <v-list-item-title class="font-weight-medium text-caption fixed-font-size text-truncate ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-2'">
                                    {{ subItem.title }}
                                </v-list-item-title>
                              </v-list-item>
                          </v-list-group>

                          <v-list-item
                            v-else
                            :to="item.to"
                            :active="isRouteActive(item.to)"
                            :value="item.title"
                            rounded="lg"
                            density="compact"
                            class="child-item mb-1 nav-level-1 sidebar-3d-l1"
                            :class="{
                              'highlight-red': item.highlight === 'red',
                              'highlight-green': item.highlight === 'green',
                              'hover-effect': item.highlight
                            }"
                          >
                            <template v-slot:prepend>
                                <div class="d-flex justify-center" style="width: 24px;">
                                    <v-icon :icon="item.icon" size="18" class="opacity-80" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'"></v-icon>
                                </div>
                            </template>
                            <v-list-item-title class="font-weight-bold force-small-text fixed-font-size text-truncate ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-1'">
                              {{ item.title }}
                            </v-list-item-title>
                            <template v-slot:append v-if="item.badgeCount">
                                <v-badge :content="item.badgeCount" color="error" inline size="small" class="ml-1"></v-badge>
                            </template>
                          </v-list-item>

                      </template>
                  </div>
                </v-list-group>

                <v-list-item
                    v-else-if="group.type === 'single'"
                    :to="group.to"
                    :active="isRouteActive(group.to)"
                    :value="group.value"
                    rounded="lg"
                    density="compact"
                    class="nav-item mb-2 group-header-item nav-level-0 sidebar-3d-l0"
                >
                  <template v-slot:prepend>
                    <div class="d-flex justify-center" style="width: 24px;">
                        <v-icon :icon="group.icon" class="small-icon fixed-size-icon" :class="[isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-1']"></v-icon>
                    </div>
                  </template>
                  <v-list-item-title class="font-weight-bold force-small-text fixed-font-size ml-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-grey-lighten-2'">
                    {{ group.title }}
                  </v-list-item-title>
                </v-list-item>

            </div>

            <v-divider v-if="i < navigationGroups.length - 1 && !group.isBackButton" class="mb-2 mt-1 border-opacity-10 mx-4"></v-divider>

          </template>
        </v-list>
      </div>
    </v-navigation-drawer>

    <v-navigation-drawer
      v-model="notificationDrawer"
      location="right"
      app
      :temporary="true"
      :width="isMobile ? 320 : 360"
      :class="isLightMode ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'"
      elevation="4"
      border="0"
    >
      <div class="d-flex flex-column h-100">
        <v-toolbar color="transparent" density="compact" height="64" class="px-4 border-b" :class="isLightMode ? 'border-grey-lighten-3' : 'border-grey-darken-3'">
          <v-icon size="24" class="mr-3" :color="isLightMode ? 'grey-darken-3' : 'white'">mdi-bell-outline</v-icon>
          <span class="text-h6 font-weight-bold" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">Notificações</span>
          <v-spacer></v-spacer>
          <v-btn v-if="notifications.length > 0" size="small" variant="text" color="error" class="font-weight-bold" @click="startClearAnimation" :disabled="isClearing">
            Limpar
          </v-btn>
        </v-toolbar>

        <div class="flex-grow-1 overflow-y-auto pa-4 custom-scrollbar">
          <div v-if="notifications.length === 0 && !isClearing" class="h-100 d-flex flex-column align-center justify-center opacity-60">
            <v-icon size="64" class="mb-4" :color="isLightMode ? 'grey-darken-1' : 'white'">mdi-check-circle-outline</v-icon>
            <span class="text-subtitle-1 font-weight-bold" :class="isLightMode ? 'text-grey-darken-1' : 'text-white'">Tudo limpo!</span>
            <span class="text-caption text-center mt-1" :class="isLightMode ? 'text-grey-darken-1' : 'text-white'">Nenhuma notificação nova no momento.</span>
          </div>

          <transition-group name="cascade-slide" tag="div" class="d-flex flex-column gap-3">
            <div
              v-for="(notification, index) in notifications"
              :key="notification.id"
              class="sidebar-toast"
              :class="[getSidebarToastColor(notification), { 'cascading-out': isClearing }]"
              :style="{ animationDelay: `${index * 0.08}s` }"
              @click="handleNotificationClick(notification)"
            >
              <div class="d-flex align-start gap-3">
                <v-avatar v-if="getNotificationDetails(notification).isChat || getNotificationDetails(notification).isTask" size="36" class="mt-1 elevation-2 border-1 border-white border-opacity-50">
                    <v-img v-if="getNotificationDetails(notification).avatar" :src="getNotificationDetails(notification).avatar"></v-img>
                    <v-icon v-else>mdi-clipboard-check</v-icon>
                </v-avatar>
                <div v-else class="mt-1">
                     <v-icon size="24">{{ getNotificationDetails(notification).icon }}</v-icon>
                </div>

                <div class="d-flex flex-column flex-grow-1 overflow-hidden">
                  <div class="d-flex justify-space-between align-start">
                      <span class="text-subtitle-2 font-weight-bold text-truncate mr-2">{{ getNotificationDetails(notification).title }}</span>
                      <span class="text-[10px] font-weight-bold opacity-70 mt-1 flex-shrink-0">{{ formatDistance(notification.created_at) }}</span>
                  </div>
                  <span class="text-caption opacity-90 mt-1" style="line-height: 1.3;">{{ getNotificationDetails(notification).message }}</span>
                </div>

                <v-btn icon variant="text" size="x-small" class="opacity-50 hover-opacity-100 mt-1" @click.stop="dismissNotification(notification.id)">
                    <v-icon size="16">mdi-close</v-icon>
                </v-btn>
              </div>
            </div>
          </transition-group>
        </div>
      </div>
    </v-navigation-drawer>

    <v-main :class="{ 'global-viewer-mode': isViewerMode }" class="h-100">

      <transition name="screen-fade" mode="out-in">

          <div v-if="isSearchActive" class="search-overlay-container w-100 h-100 overflow-y-auto d-flex flex-column">
             <div class="search-results-wrapper w-100 mx-auto py-6 py-md-10 px-4 px-md-8" style="max-width: 1300px; flex-grow: 1;">

                 <div class="text-center mb-10 position-relative pt-4">
                     <h2 class="text-h4 font-weight-black mb-2" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        {{ searchQuery ? 'Resultados para:' : 'Explorar Módulos' }}
                        <span v-if="searchQuery" class="text-primary">"{{ searchQuery }}"</span>
                     </h2>
                     <p class="text-subtitle-1 opacity-70" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">
                        {{ searchQuery ? `Encontramos ${filteredScreens.length} recurso(s).` : 'Digite para filtrar ou selecione abaixo.' }}
                     </p>

                     <v-btn
                        icon="mdi-close"
                        variant="tonal"
                        color="error"
                        class="position-absolute right-0 top-0 mt-4 d-none d-sm-flex"
                        @click="closeSearch"
                     ></v-btn>
                 </div>

                 <transition name="fade-fast" mode="out-in">
                     <div v-if="filteredScreens.length === 0" key="empty-state" class="d-flex flex-column align-center justify-center py-16 opacity-60">
                         <v-avatar size="100" color="surface-variant" class="mb-6">
                            <v-icon size="50">mdi-database-search-outline</v-icon>
                         </v-avatar>
                         <span class="text-h5 font-weight-bold" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">Nenhum resultado encontrado.</span>
                         <span class="text-body-1 mt-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'">Verifique se o termo está correto ou tente palavras mais simples.</span>
                         <v-btn variant="outlined" rounded="pill" class="mt-6" @click="searchQuery = ''">Limpar Busca</v-btn>
                     </div>

                     <transition-group v-else name="search-anim" tag="div" class="search-grid-container" key="grid-state">
                         <div v-for="screen in filteredScreens" :key="screen.title + screen.to" class="search-grid-item">
                             <v-card
                                class="h-100 modern-search-card rounded-xl text-center border-thin d-flex flex-column cursor-pointer"
                                :class="isLightMode ? 'bg-white' : 'glassmorphism-card-dialog'"
                                elevation="2"
                                @click="goToSearchScreen(screen)"
                             >
                                 <v-card-text class="pa-6 d-flex flex-column h-100 align-center">
                                     <v-avatar size="64" :color="screen.color || 'primary'" variant="tonal" class="mb-4 search-card-avatar">
                                         <v-icon size="32">{{ screen.icon }}</v-icon>
                                     </v-avatar>

                                     <h3 class="text-subtitle-1 font-weight-black mb-1 lh-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ screen.title }}</h3>

                                     <v-chip size="x-small" variant="flat" :color="isLightMode ? 'grey-lighten-4 text-grey-darken-3' : 'white-05'" class="mb-3 font-weight-bold text-uppercase tracking-widest">
                                         {{ screen.group }}
                                     </v-chip>

                                     <p class="text-caption opacity-80 mb-6 px-2" :class="isLightMode ? 'text-grey-darken-3' : 'text-white'" style="line-height: 1.4;">
                                         {{ screen.description }}
                                     </p>

                                     <v-btn
                                        variant="tonal"
                                        :color="screen.color || 'primary'"
                                        size="small"
                                        rounded="pill"
                                        class="mt-auto font-weight-bold w-100 search-btn-hover"
                                        elevation="0"
                                     >
                                        Acessar Módulo
                                     </v-btn>
                                 </v-card-text>
                             </v-card>
                         </div>
                     </transition-group>
                 </transition>
             </div>
          </div>

          <div v-else class="h-100 w-100 d-flex flex-column overflow-y-auto overflow-x-hidden" style="min-height: 0;">
          <router-view v-slot="{ Component }">
                <v-fade-transition mode="out-in">
                     <component :is="Component" />
                </v-fade-transition>
              </router-view>
          </div>

      </transition>
    </v-main>

    <ChatWidget ref="chatWidgetRef" />

    <FinancialDailyModal v-if="showFinancialDaily" />

    <PendingApprovalAlertModal v-if="currentPendingApprovalAlert" :show="showPendingApprovalAlert" :title="currentPendingApprovalAlert.title" :message="currentPendingApprovalAlert.message" @close="handleGoToApproval" />

    <teleport to="body">
      <transition name="fade-overlay">
        <div v-if="centralTaskAlerts.length > 0" class="central-task-overlay d-flex align-center justify-center">
          <div class="central-task-modal mj-glass mj-border d-flex flex-column align-center text-center pa-8 rounded-xl shadow-2xl">
            <div class="pulsing-bell bg-warning-lighten-4 rounded-circle pa-4 mb-4">
              <v-icon size="48" color="warning" class="bell-shake">mdi-bell-ring</v-icon>
            </div>
            <h2 class="text-h4 font-weight-black text-white mb-2">Lembrete de Tarefa</h2>
            <p class="text-h6 text-white opacity-80 mb-6">{{ centralTaskAlerts[0].message }}</p>
            <div class="d-flex gap-4 w-100">
               <v-btn block color="warning" size="x-large" variant="flat" class="font-weight-black rounded-pill" @click="dismissCentralAlert">Estou Ciente</v-btn>
            </div>
          </div>
        </div>
      </transition>
    </teleport>

  </v-layout>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch, reactive } from 'vue';
import { useDisplay } from 'vuetify';
import { supabase } from '@/api/supabase';
import { useRouter, useRoute } from 'vue-router';
import type { RealtimeChannel } from '@supabase/supabase-js';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import { useChatStore } from '@/stores/chat';
import { useOnlineStatusStore } from '@/stores/onlineStatus';
import { useCompanyStore } from '@/stores/company';
import { useThemeStore } from '@/stores/theme';
import { storeToRefs } from 'pinia';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import PendingApprovalAlertModal from '@/components/admin/PendingApprovalAlertModal.vue';
import ChatWidget from '@/components/ChatWidget.vue';
import FinancialDailyModal from '@/components/admin/FinancialDailyModal.vue';

import logoImage from '@/assets/logo.png';
import logoMj from '@/assets/logomjlm.png';

import sendMessageSoundUrl from '@/assets/send_message.mp3';
import receiveMessageSoundUrl from '@/assets/message_notification.mp3';

const router = useRouter();
const route = useRoute();
const userStore = useUserStore();
const appStore = useAppStore();
const chatStore = useChatStore();
const onlineStatusStore = useOnlineStatusStore();
const companyStore = useCompanyStore();
const themeStore = useThemeStore();

const { profile, isAdmin } = storeToRefs(userStore);

const { mobile } = useDisplay();
const isMobile = computed(() => mobile.value);
const drawer = ref(!isMobile.value);
const rail = ref(true);
const chatWidgetRef = ref<any>(null);

const activeAppFocus = ref<string | null>(null);
const openedGroups = ref<string[]>(['main', 'sales']);
const isLightMode = computed(() => themeStore.currentMode === 'light');
const isLoggingOut = ref(false);

const notificationSoundRef = ref<HTMLAudioElement | null>(null);
const alertSound = ref<HTMLAudioElement | null>(null);
const sendMessageSoundRef = ref<HTMLAudioElement | null>(null);
const receiveMessageSoundRef = ref<HTMLAudioElement | null>(null);
const lowStockAlerts = ref<any[]>([]);

const showFinancialDaily = computed(() => {
  return ['FinancialReceivables', 'FinancialPayables', 'FinancialAccounts', 'SalesPayments', 'AdminMjAccountsPayable', 'AdminMjReceivables'].includes(String(route.name));
});

const displayLogo = computed(() => {
  if (companyStore.isGlobalView) {
    return isLightMode.value ? logoMj : logoImage;
  }
  const name = (companyStore.currentCompanyName || '').toLowerCase();
  if (name.includes('mr jacky') || name.includes('mjprocess') || companyStore.context === 'mjprocess' || !companyStore.currentCompanyLogo) {
    return isLightMode.value ? logoMj : logoImage;
  }
  return companyStore.currentCompanyLogo;
});

const chatToasts = ref<any[]>([]);
const isMiniChatOpen = ref(false);

const openMiniChat = async (channelId: number | null | undefined, toastId: string) => {
    const idx = chatToasts.value.findIndex(t => t.id === toastId);
    if (idx > -1) chatToasts.value.splice(idx, 1);

    if (channelId) {
        await chatStore.setActiveChannel(channelId);
        if (chatWidgetRef.value) {
            chatWidgetRef.value.openChat();
        }
    } else {
        router.push({ name: 'Chat' });
    }
};

const goToTasks = () => {
    router.push({ name: 'Tasks' });
};

const testAllAlerts = () => {
    addPersistentToast({
        id: `mock-${Date.now()}`,
        content: `[ALERT_TEST]::Isto é um teste de notificação do sistema. Tudo funcionando perfeitamente!`,
        recipient_id: userStore.user?.id || null,
        redirect_url: null,
        is_read: false,
        created_at: new Date().toISOString()
    });

    chatToasts.value.push({
        id: `task-mock-${Date.now()}`,
        title: 'Nova Tarefa Recebida',
        message: 'Você recebeu uma tarefa simulada para testar a interface de vidro.',
        avatar: null,
        isTask: true,
        channelId: null
    });

    playThrottledSound('chat_receive');
};

const goToApp = (routeName: string) => { router.push({ name: routeName }); };

const focusAppModule = (moduleKey: string, defaultRouteName: string) => {
  activeAppFocus.value = moduleKey;
  openedGroups.value = [moduleKey];

  // 1. Pega os grupos do módulo atual
  const currentGroups = userStore.currentModule === 'cajuia' ? cajuiaNavigationGroups : mjNavigationGroups;
  const group = currentGroups.find(g => g.value === moduleKey);

  let targetRoute = defaultRouteName;

  // 2. Se o grupo existir, vamos escanear as permissões inteligentemente
  if (group && group.items) {
      // Achata a lista caso existam sub-menus (ex: Fiscal > NFe)
      let flatItems: any[] = [];
      group.items.forEach((i: any) => {
          if (i.children) flatItems.push(...i.children);
          else flatItems.push(i);
      });

      // 3. Verifica se o usuário tem acesso à rota padrão (ex: DesignKanban)
      const defaultItem = flatItems.find((i: any) => i.to && i.to.name === defaultRouteName);
      const hasDefaultPerm = defaultItem && (!defaultItem.permission || userStore.hasPermission(defaultItem.permission));

      // 4. Se ele NÃO tiver acesso à rota padrão, fazemos o fallback automático!
      if (!hasDefaultPerm) {
          // Pega a primeira rota que ele tiver permissão dentro do módulo
          const firstAllowed = flatItems.find((i: any) => !i.permission || userStore.hasPermission(i.permission));
          if (firstAllowed && firstAllowed.to && firstAllowed.to.name) {
              targetRoute = firstAllowed.to.name;
          }
      }
  }

  // 5. Navega com segurança para a rota garantida
  router.push({ name: targetRoute });
};

const clearAppFocus = () => {
  activeAppFocus.value = null;
  openedGroups.value = ['main', 'sales'];
  router.push({ name: 'Home' });
};

// --- FUNÇÃO PARA MANTER HIGHLIGHT DA ROTA EXATA (BUGFIX) ---
const isRouteActive = (toObj: any) => {
    if (!toObj || !toObj.name) return false;
    if (toObj.name !== route.name) return false;

    // Se o item tem query params configurados, exige que a rota atual os tenha também
    if (toObj.query) {
        for (const key in toObj.query) {
            if (route.query[key] !== String(toObj.query[key])) return false;
        }
    }
    return true;
};

const mjNavigationGroups = [
  {
    title: 'Visão Geral',
    value: 'main',
    type: 'group',
    icon: 'mdi-view-dashboard-outline',
    items: [
      { title: 'Dashboard', icon: 'mdi-view-dashboard', to: { name: 'Home' }, permission: 'view_dashboard' },
      { title: 'Tarefas', icon: 'mdi-checkbox-marked-circle-outline', to: { name: 'Tasks' }, permission: 'view_tasks', badgeCount: 0 },
      { title: 'Painel Cortadora', icon: 'mdi-content-cut', to: { name: 'CajuiaCortadoraDashboard' }, permission: 'prod_stock_mgmt' },
      { title: 'Gestão de Cortes', icon: 'mdi-format-list-checks', to: { name: 'CajuiaCortadoraManagement' }, permission: 'prod_stock_mgmt' },
    ]
  },
  {
    title: 'Cadastros',
    value: 'registrations',
    type: 'group',
    icon: 'mdi-database-edit',
    items: [
      { title: 'Clientes', icon: 'mdi-account-group', to: { name: 'ClientManagement' }, permission: 'cad_clients' },
      { title: 'Fornecedores', icon: 'mdi-truck-delivery', to: { name: 'SupplierManagement' }, permission: 'cad_suppliers' },
      { title: 'Máquinas', icon: 'mdi-cog-box', to: { name: 'MachinesManagement' }, permission: 'cad_machines' }
    ]
  },
  {
    title: 'Vendas',
    value: 'sales',
    type: 'group',
    icon: 'mdi-storefront-outline',
    items: [
      { title: 'Gestão de Pedidos', icon: 'mdi-earth', to: { name: 'OrderManagement' }, permission: 'sales_management' },
      { title: 'Vendas Balcão (Loja)', icon: 'mdi-store', to: { name: 'StoreSalesManagement' }, permission: 'sales_store' },
      { title: 'Gráfico de Vendas', icon: 'mdi-chart-areaspline', to: { name: 'SalesArea' }, permission: 'admin_sales_area' },
      { title: 'Consulta Ref. Vendidas', icon: 'mdi-cloud-search-outline', to: { name: 'GlobalOrders' }, permission: 'sales_global_consult' },
      { title: 'Tabela de Preços', icon: 'mdi-currency-usd', to: { name: 'PriceList' }, permission: 'sales_price_list' },
      { title: 'Didático', icon: 'mdi-school-outline', to: { name: 'Didatico' }, permission: 'sales_didatic' },
    ]
  },
  {
    title: 'Produtos',
    value: 'products',
    type: 'group',
    icon: 'mdi-package-variant-closed',
    items: [
      {
        title: 'Estoque',
        icon: 'mdi-warehouse',
        to: { name: 'Stock' },
        permission: 'prod_stock'
      },
      {
        title: 'Gestão de Estoque',
        icon: 'mdi-cog-box',
        to: { name: 'StockManagement' },
        permission: 'prod_stock_mgmt'
      },
      {
        title: 'Compras',
        icon: 'mdi-cart-outline',
        children: [
            { title: 'Cotações', to: { name: 'Quotations' }, icon: 'mdi-file-document-edit', permission: 'pur_quotations' },
            { title: 'Produtos', to: { name: 'ProductPurchases' }, icon: 'mdi-cart-arrow-down', permission: 'pur_products' },
            { title: 'Serviços', to: { name: 'ServicePurchases' }, icon: 'mdi-handshake', permission: 'pur_services' }
        ]
      }
    ]
  },
  {
    title: 'Design',
    value: 'design',
    type: 'group',
    icon: 'mdi-palette-swatch-outline',
    items: [
      { title: 'Kanban Design', icon: 'mdi-trello', to: { name: 'DesignKanban' }, permission: 'des_kanban' },
      { title: 'Solicitar Desenv.', icon: 'mdi-flask-outline', to: { name: 'NewDevelopmentRequest' }, permission: 'des_request' },
      { title: 'Aprovações', icon: 'mdi-check-decagram-outline', to: { name: 'Approvals' }, highlight: 'red', permission: 'mfg_approvals' },
      { title: 'Catálogo', icon: 'mdi-image-multiple-outline', to: { name: 'StampCatalog' }, permission: 'des_catalog' },
    ]
  },
{
    title: 'Produção',
    value: 'production',
    type: 'group',
    icon: 'mdi-factory',
    items: [
      { title: 'Lançamentos', icon: 'mdi-rocket-launch-outline', to: { name: 'Launches' }, permission: 'mfg_launches' },
      { title: 'Kanban Coleção', icon: 'mdi-palette-swatch-outline', to: { name: 'KanbanColecao' }, highlight: 'green', permission: 'mfg_control' },
      { title: 'Kanban Produção', icon: 'mdi-view-dashboard-outline', to: { name: 'KanbanProducao' }, highlight: 'green', permission: 'mfg_control' },
      { title: 'Gestão PCP', icon: 'mdi-console-network', to: { name: 'ProductionControl' }, highlight: 'green', permission: 'mfg_control' },
      { title: 'PCP Dinâmico (V2)', icon: 'mdi-robot-industrial', to: { name: 'DynamicProductionControl' }, highlight: 'blue', permission: 'mfg_control' },
      { title: 'Estação Impressão', icon: 'mdi-printer-3d-nozzle', to: { name: 'PrintingStation' }, permission: 'mfg_printing' },
      { title: 'Liberação', icon: 'mdi-clipboard-check-outline', to: { name: 'Liberacao' }, permission: 'mfg_release' },
      { title: 'Em Produção', icon: 'mdi-cog-sync-outline', to: { name: 'InProduction' }, permission: 'mfg_in_production' },
    ]
  },
  {
    title: 'Expedição',
    value: 'logistics',
    type: 'group',
    icon: 'mdi-truck-fast-outline',
    items: [
      { title: 'Entregas', icon: 'mdi-truck-delivery-outline', to: { name: 'Delivery' }, highlight: 'green', permission: 'log_delivery' },
    ]
  },
  {
    title: 'Frota',
    value: 'fleet',
    type: 'group',
    icon: 'mdi-car-multiple',
    items: [
      { title: 'Gestão de Veículos', icon: 'mdi-car-cog', to: { name: 'FleetVehicles' }, permission: 'fleet_vehicles' },
      { title: 'Abastecimento', icon: 'mdi-gas-station', to: { name: 'FleetRefueling' }, permission: 'fleet_refueling' },
    ]
  },
  {
    title: 'Financeiro',
    value: 'finance',
    type: 'group',
    icon: 'mdi-finance',
    items: [
      { title: 'Contas a Receber', icon: 'mdi-cash-multiple', to: { name: 'FinancialReceivables' }, permission: 'fin_receivables' },
      { title: 'Contas a Pagar', icon: 'mdi-cash-minus', to: { name: 'FinancialPayables' }, permission: 'fin_payables' },
      { title: 'Contas Bancárias', icon: 'mdi-bank', to: { name: 'FinancialAccounts' }, permission: 'fin_accounts' },
      { title: 'Extrato Bancário', icon: 'mdi-bank-transfer', to: { name: 'SalesPayments' }, permission: 'fin_statement' },
    ]
  },
  {
    title: 'Fiscal e Tributário',
    value: 'fiscal',
    type: 'group',
    icon: 'mdi-file-document-multiple-outline',
    items: [
      {
        title: 'NFe (Nota Fiscal)',
        icon: 'mdi-file-document-check',
        children: [
            { title: 'Venda de Produto', to: { name: 'AdminNfeIssuer' }, icon: 'mdi-arrow-up-bold-box-outline', permission: 'fisc_nfe_sell' },
            { title: 'Compra de Produto', to: { name: 'FiscalMonitor' }, icon: 'mdi-arrow-down-bold-box-outline', permission: 'fisc_nfe_buy' }
        ]
      },
      {
        title: 'NFCe (Consumidor)',
        icon: 'mdi-receipt-text',
        children: [
            { title: 'Venda Consumidor', to: { name: 'AdminNfceIssuer' }, icon: 'mdi-account-cash', permission: 'fisc_nfce_sell' }
        ]
      },
      {
        title: 'CT-e (Transporte)',
        icon: 'mdi-truck-fast',
        children: [
            { title: 'Emissão de CT-e', to: { name: 'AdminCteIssuer' }, icon: 'mdi-file-send-outline', permission: 'fisc_cte_issuer' }
        ]
      },
      {
        title: 'Empresas e Filiais',
        icon: 'mdi-domain',
        children: [
            { title: 'Empresas (Matriz)', to: { name: 'FiscalCompanies' }, icon: 'mdi-office-building', permission: 'fisc_companies' },
            { title: 'Lojas (Filiais)', to: { name: 'FiscalStores' }, icon: 'mdi-store', permission: 'fisc_stores' }
        ]
      },
      {
        title: 'Mais Detalhes',
        icon: 'mdi-dots-horizontal',
        children: [
            { title: 'Plano de Contas', to: { name: 'ChartOfAccounts' }, icon: 'mdi-file-tree', permission: 'fisc_chart' },
            { title: 'Formas de Pagamento', to: { name: 'AdminPaymentMethods' }, icon: 'mdi-credit-card-settings-outline', permission: 'fisc_pay_methods' },
            { title: 'Regras Tributárias', to: { name: 'FiscalTaxRules' }, icon: 'mdi-scale-balance', permission: 'fisc_tax_rules' }
        ]
      }
    ]
  },
  {
    title: 'Relatórios',
    value: 'reports_hub',
    type: 'single',
    icon: 'mdi-chart-box-outline',
    to: { name: 'AdminReports', params: { reportType: 'hub' } },
    permission: 'view_reports'
  },
  {
    title: 'Marketplace B2B',
    value: 'storefront',
    type: 'group',
    icon: 'mdi-storefront-outline',
    items: [
      { title: 'Páginas & Layout', icon: 'mdi-view-quilt-outline', to: { name: 'StorefrontManager', query: { tab: 'builder' } }, permission: 'admin_integrations' },
      { title: 'Loja (Editor)', icon: 'mdi-palette-outline', to: { name: 'StorefrontManager', query: { tab: 'themes' } }, permission: 'admin_integrations' },
      { title: 'Estampas & R2', icon: 'mdi-texture', to: { name: 'StorefrontManager', query: { tab: 'stamps' } }, permission: 'admin_integrations' },
      { title: 'Categorias', icon: 'mdi-folder-outline', to: { name: 'StorefrontManager', query: { tab: 'categories' } }, permission: 'admin_integrations' },
      { title: 'Bases Têxteis', icon: 'mdi-layers-triple-outline', to: { name: 'StorefrontManager', query: { tab: 'fabrics' } }, permission: 'admin_integrations' },
      { title: 'Mockups 3D', icon: 'mdi-tshirt-crew-outline', to: { name: 'StorefrontManager', query: { tab: 'mockups' } }, permission: 'admin_integrations' },
      {
        title: 'Clientes B2B',
        icon: 'mdi-account-group-outline',
        children: [
            { title: 'Aprovar Contas', to: { name: 'StorefrontManager', query: { tab: 'account_approvals' } }, icon: 'mdi-account-check-outline', permission: 'admin_integrations' },
            { title: 'Pipeline Kanban', to: { name: 'StorefrontManager', query: { tab: 'leads_kanban' } }, icon: 'mdi-view-column', permission: 'admin_integrations' },
            { title: 'Leads & Base', to: { name: 'StorefrontManager', query: { tab: 'leads' } }, icon: 'mdi-account-details-outline', permission: 'admin_integrations' },
            { title: 'Estúdio & Cofre', to: { name: 'StorefrontManager', query: { tab: 'design_clients' } }, icon: 'mdi-draw-pen', permission: 'admin_integrations' }
        ]
      }
    ]
  },
  {
    title: 'Recursos Humanos',
    value: 'rh',
    type: 'group',
    icon: 'mdi-card-account-details-outline',
    items: [
      { title: 'Dossiê Colaboradores', icon: 'mdi-folder-account', to: { name: 'EmployeeManagement' }, permission: 'cad_employees' },
      { title: 'Gestão de Ponto', icon: 'mdi-clock-check-outline', to: { name: 'AdminTimeTracking' }, permission: 'rh_ponto' },
      { title: 'Totem Facial (Kiosk)', icon: 'mdi-face-recognition', to: { name: 'TimeKiosk' }, highlight: 'blue', permission: 'rh_ponto' },
    ]
  },
  {
    title: 'Controle Multi-Empresa',
    icon: 'mdi-source-branch-sync',
    to: { name: 'SalesTenantControl' },
    permission: 'admin_general' // ou 'admin_sales_tenant'
}
];

const cajuiaNavigationGroups = [
  {
    title: 'Loja',
    value: 'store',
    type: 'group',
    icon: 'mdi-store',
    items: [
      { title: 'Dashboard', icon: 'mdi-view-dashboard-variant', to: { name: 'CajuiaDashboard' }, permission: 'cajuia_dashboard' },
    ]
  },
  {
    title: 'Vendas',
    value: 'sales_cajuia',
    type: 'group',
    icon: 'mdi-clipboard-list-outline',
    items: [
      { title: 'Meus Pedidos', icon: 'mdi-file-document-outline', to: { name: 'CajuiaOrders' }, permission: 'cajuia_orders' },
      { title: 'Emissor NFe', icon: 'mdi-file-document-edit-outline', to: { name: 'SellerNfeIssuer' }, permission: 'cajuia_nfe' },
      { title: 'Clientes', icon: 'mdi-account-group', to: { name: 'CajuiaClients' }, permission: 'cajuia_clients' },
    ]
  },
  {
    title: 'Gestão',
    value: 'management',
    type: 'group',
    icon: 'mdi-chart-box-outline',
    items: [
      { title: 'Financeiro', icon: 'mdi-cash-register', to: { name: 'CajuiaFinancial' }, permission: 'cajuia_financial' },
      { title: 'Administração', icon: 'mdi-shield-account', to: { name: 'CajuiaAdmin' }, permission: 'cajuia_admin' },
    ]
  }
];

const hiddenInDefaultMode = ['design', 'fleet', 'rh', 'storefront'];

const navigationGroups = computed(() => {
  const currentGroups = userStore.currentModule === 'cajuia' ? cajuiaNavigationGroups : mjNavigationGroups;

  let filteredGroups = currentGroups.map(group => {
    if (group.type === 'single') {
      if (group.permission && !userStore.hasPermission(group.permission)) return null;
      return group;
    }

    const filteredItems = (group.items || []).map(item => {
      if (item.permission && !userStore.hasPermission(item.permission)) return null;

      const newItem = { ...item };

      if (group.value === 'main' && newItem.title === 'Tarefas') {
          newItem.badgeCount = chatStore.totalUnreadCount;
      }

      if (newItem.children) {
        const filteredChildren = newItem.children.filter(child => {
          if (!child.permission) return true;
          return userStore.hasPermission(child.permission);
        });

        if (filteredChildren.length === 0) return null;
        newItem.children = filteredChildren;
      }
      return newItem;
    }).filter(item => item !== null);

    if (filteredItems.length > 0) {
      return { ...group, items: filteredItems };
    }
    return null;
  }).filter(g => g !== null);

  if (activeAppFocus.value) {
     const focusGroup = filteredGroups.find(g => g?.value === activeAppFocus.value);
     if (focusGroup) {
        return [
           {
              title: 'Voltar ao Hub',
              isBackButton: true,
              icon: 'mdi-arrow-left-circle',
              type: 'single'
           },
           focusGroup
        ];
     }
  }

  return filteredGroups.filter(g => g && !hiddenInDefaultMode.includes(g.value));
});

const searchQuery = ref('');
const isSearchActive = ref(false);
const searchInputRef = ref<any>(null);

const closeSearch = () => {
    isSearchActive.value = false;
    searchQuery.value = '';
    if (document.activeElement instanceof HTMLElement) {
        document.activeElement.blur();
    }
};

const getScreenDescription = (title: string, group: string) => {
    const t = title.toLowerCase();

    if (t.includes('dashboard') || t.includes('painel')) return 'Visualize os principais gráficos, métricas e indicadores de desempenho deste setor.';
    if (t.includes('cliente') || t.includes('fornecedor') || t.includes('empresas') || t.includes('filiais')) return 'Área dedicada ao gerenciamento completo de cadastros, históricos e informações de contato.';
    if (t.includes('venda') || t.includes('pedido') || t.includes('orçamento') || t.includes('cotação')) return 'Controle centralizado de orçamentos, negociações comerciais e acompanhamento de pedidos.';
    if (t.includes('estoque') || t.includes('produto')) return 'Ferramenta para controle de inventário, reposições, catálogo e movimentações de produtos.';
    if (t.includes('financeiro') || t.includes('conta') || t.includes('extrato') || t.includes('dre')) return 'Gestão estruturada de fluxo de caixa, relatórios de DRE, contas a pagar, receber e auditorias.';
    if (t.includes('produção') || t.includes('pcp') || t.includes('impressão') || t.includes('lançamento')) return 'Acompanhamento em tempo real do chão de fábrica, ordens de produção e etapas de fabricação.';
    if (t.includes('design') || t.includes('arte') || t.includes('catálogo')) return 'Gerenciamento visual do fluxo de solicitação e aprovação de artes e biblioteca de estampas.';
    if (t.includes('fiscal') || t.includes('nfe') || t.includes('cte') || t.includes('tributário')) return 'Painel para emissão, validação e monitoramento de notas fiscais e documentos de transporte.';
    if (t.includes('relatório') || t.includes('ranking') || t.includes('didático')) return 'Extração de dados analíticos, consolidação de resultados e listagens operacionais detalhadas.';
    if (t.includes('rh') || t.includes('colaborador') || t.includes('ponto')) return 'Administração de recursos humanos, registro de ponto eletrônico, benefícios e dossiês.';
    if (t.includes('frota') || t.includes('veículo') || t.includes('entregas')) return 'Painel logístico para monitoramento de rotas, manutenções, abastecimento e status de frota.';
    if (t.includes('tarefa') || t.includes('kanban')) return 'Organização e controle de atividades pendentes, responsabilidades e produtividade diária.';

    return `Acesse este módulo para visualizar as informações e executar as operações referentes a este recurso.`;
};

const allAvailableScreens = computed(() => {
    const screens: any[] = [];
    const colors = ['primary', 'success', 'info', 'warning', 'purple', 'indigo', 'teal', 'deep-orange'];

    const baseGroups = userStore.currentModule === 'cajuia' ? cajuiaNavigationGroups : mjNavigationGroups;

    baseGroups.forEach((group: any, index: number) => {
        const groupColor = colors[index % colors.length];

        if (group.type === 'single' && group.to) {
            // TRAVA DE PERMISSÃO
            if (group.permission && !userStore.hasPermission(group.permission)) return;

            screens.push({
                title: group.title,
                icon: group.icon,
                to: group.to,
                group: group.title,
                color: groupColor,
                description: getScreenDescription(group.title, group.title)
            });
        } else if (group.items) {
            group.items.forEach((item: any) => {
                if (item.children) {
                    item.children.forEach((child: any) => {
                        // TRAVA DE PERMISSÃO
                        if (child.permission && !userStore.hasPermission(child.permission)) return;

                        screens.push({
                            title: child.title,
                            icon: child.icon || item.icon,
                            to: child.to,
                            group: `${group.title} > ${item.title}`,
                            color: groupColor,
                            description: getScreenDescription(child.title, group.title)
                        });
                    });
                } else if (item.to) {
                    // TRAVA DE PERMISSÃO
                    if (item.permission && !userStore.hasPermission(item.permission)) return;

                    screens.push({
                        title: item.title,
                        icon: item.icon,
                        to: item.to,
                        group: group.title,
                        color: groupColor,
                        description: getScreenDescription(item.title, group.title)
                    });
                }
            });
        }
    });
    return screens;
});

const filteredScreens = computed(() => {
    if (!searchQuery.value) return allAvailableScreens.value;

    const query = searchQuery.value.toLowerCase().trim();
    const normalize = (str: string) => str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    const normalizedQuery = normalize(query);

    return allAvailableScreens.value.filter(screen =>
        normalize(screen.title).includes(normalizedQuery) ||
        normalize(screen.group).includes(normalizedQuery)
    );
});

const goToSearchScreen = (screen: any) => {
    if (screen.to) {
        activeAppFocus.value = null;
        router.push(screen.to);
        closeSearch();
    }
};

const customRoleTags = ref<string[]>([]);
const userCustomRoleName = ref<string>('');

const fetchRolePermissions = async () => {
    if (!userStore.profile?.custom_role_id) {
        userCustomRoleName.value = '';
        return;
    }
    const { data } = await supabase
        .from('custom_roles')
        .select('name, read_only_permissions')
        .eq('id', userStore.profile.custom_role_id)
        .single();

    if (data) {
        if (data.read_only_permissions) customRoleTags.value = data.read_only_permissions;
        if (data.name) userCustomRoleName.value = data.name;
    }
};

watch(() => userStore.profile?.custom_role_id, () => fetchRolePermissions());

const isViewerMode = computed(() => {
  if (userStore.profile?.role === 'super_admin') return false;
  const currentPermission = route.meta?.permission as string;
  if (!currentPermission) return false;
  const readOnlyList = userStore.profile?.read_only_permissions || [];
  return readOnlyList.includes(currentPermission);
});

const canChangeCompany = computed(() => {
    return userStore.isAdmin || userStore.hasPermission('fin_receivables') || userStore.hasPermission('fin_payables');
});

const canApprove = computed(() => {
    return userStore.hasPermission('mfg_approvals') || userStore.isAdmin;
});

watch(() => userStore.profile?.company_id, (newCompanyId) => {
    if (!canChangeCompany.value && newCompanyId) {
        companyStore.setContext(newCompanyId);
    }
}, { immediate: true });

const canAccessChat = computed(() => {
    return true;
});

watch(rail, (val) => {
    if (val) openedGroups.value = [];
});

const toggleRail = () => {
    rail.value = !rail.value;
};

const handleDrawerClick = () => {
    if (rail.value) {
        rail.value = false;
    }
};

const toggleTheme = () => {
    themeStore.setMode(isLightMode.value ? 'dark' : 'light');
};

const sidebarFontSize = ref(14);
const sidebarIconSize = ref(22);

const saveSidebarSettings = () => {
    localStorage.setItem('sidebarFontSize', String(sidebarFontSize.value));
    localStorage.setItem('sidebarIconSize', String(sidebarIconSize.value));
};

const cssVars = computed(() => {
    return {
        '--sidebar-font-size': `${sidebarFontSize.value}px`,
        '--sidebar-icon-size': `${sidebarIconSize.value}px`
    }
});

type Notification = { id: string; content: string; recipient_id: string | null; redirect_url: string | null; is_read: boolean; created_at: string; type?: string; sender_avatar?: string };

const logoRoute = computed(() => {
  if (userStore.currentModule === 'cajuia') {
    return userStore.hasPermission('cajuia_dashboard') ? { name: 'CajuiaDashboard' } : { name: 'CajuiaSellerDashboard' };
  }
  return { name: 'Home' };
});

const notifications = ref<Notification[]>([]);
const unreadNotifications = computed(() => notifications.value.filter(n => !n.is_read).length); // CORREÇÃO CRÍTICA APLICADA AQUI
const notificationDrawer = ref(false);
const isClearing = ref(false);

// CONTROLE DO MODAL DE TAREFAS CENTRALIZADO
const centralTaskAlerts = ref<any[]>([]);

const dismissCentralAlert = () => {
    centralTaskAlerts.value.shift();
    if (alertSound.value) {
        alertSound.value.pause();
        alertSound.value.currentTime = 0;
    }
};

// O MOTOR DE RECORRÊNCIA (RODA NO FUNDO A CADA 1 MINUTO)
const checkRecurringTasks = async () => {
    if (!userStore.user) return;
    try {
        const { data } = await supabase.from('app_tasks')
            .select('id, title, alert_interval')
            .eq('assigned_to', userStore.user.id)
            .in('status', ['pendente', 'em_andamento'])
            .eq('requires_alert', true)
            .gt('alert_interval', 0);

        if (data) {
            const now = Date.now();
            data.forEach(task => {
                const lastAlert = localStorage.getItem(`task_alert_${task.id}`);
                const intervalMs = task.alert_interval * 60 * 1000;

                if (!lastAlert || (now - parseInt(lastAlert)) > intervalMs) {
                    centralTaskAlerts.value.push({
                        id: `rec_${task.id}_${now}`,
                        title: 'Lembrete Recorrente',
                        message: `Você tem uma tarefa pendente: "${task.title}"`
                    });
                    localStorage.setItem(`task_alert_${task.id}`, now.toString());

                    try {
                        if (alertSound.value && isAudioUnlocked.value) {
                            alertSound.value.currentTime = 0;
                            alertSound.value.play().catch(e => {});
                        }
                    } catch(e) {}
                }
            });
        }
    } catch(e) {}
};

let recurrenceInterval: NodeJS.Timeout;

const notificationListener = ref<RealtimeChannel | null>(null);
let messageListener: RealtimeChannel | null = null;

const isBellRinging = ref(false);
const showPendingApprovalAlert = ref(false);
const currentPendingApprovalAlert = ref<{title: string, message: string, redirectUrl: string | null} | null>(null);

let reconnectTimer: NodeJS.Timeout;
let stockCheckInterval: NodeJS.Timeout;

const isAudioUnlocked = ref(false);
const backgrounds = ref([
 'https://sgspnoxsqdwbdqsvjdei.supabase.co/storage/v1/object/public/media//3.jpg',
 'https://sgspnoxsqdwbdqsvjdei.supabase.co/storage/v1/object/public/media//MJ%20(1).jpg',
 'https://sgspnoxsqdwbdqsvjdei.supabase.co/storage/v1/object/public/media//2.jpg',
 'https://sgspnoxsqdwbdqsvjdei.supabase.co/storage/v1/object/public/media//4.jpg',
 'https://sgspnoxsqdwbdqsvjdei.supabase.co/storage/v1/object/public/media//5.jpg',
]);
const currentBackground = ref('');

let lastSoundPlayedAt = 0;
let lastChatSoundPlayedAt = 0;

const isBootingAudioReady = ref(false);
setTimeout(() => {
  isBootingAudioReady.value = true;
}, 3000);

const playThrottledSound = (type: 'notification' | 'chat_receive' | 'chat_send' = 'notification') => {
    if (!isBootingAudioReady.value) return;

    const now = Date.now();

    try {
        if (type === 'chat_send') {
            if (sendMessageSoundRef.value && isAudioUnlocked.value) {
                sendMessageSoundRef.value.currentTime = 0;
                sendMessageSoundRef.value.play().catch(() => {});
            }
            return;
        }

        if (type === 'chat_receive') {
            if (now - lastChatSoundPlayedAt > 1500) {
                lastChatSoundPlayedAt = now;

                if (typeof navigator !== 'undefined' && navigator.userActivation && !navigator.userActivation.hasBeenActive) return;

                if (receiveMessageSoundRef.value && isAudioUnlocked.value) {
                    receiveMessageSoundRef.value.currentTime = 0;
                    receiveMessageSoundRef.value.play().catch(() => {});
                } else {
                    chatStore.playNotificationSound();
                }
            }
            return;
        }

        if (now - lastSoundPlayedAt > 1500) {
            lastSoundPlayedAt = now;

            if (typeof navigator !== 'undefined' && navigator.userActivation && !navigator.userActivation.hasBeenActive) return;

            if (notificationSoundRef.value && isAudioUnlocked.value) {
                notificationSoundRef.value.currentTime = 0;
                notificationSoundRef.value.play().catch(() => {});
            }
        }
    } catch(e) {}
};

watch(notificationDrawer, (isOpen) => {
    if (isOpen && persistentToasts.value.length > 0) {
        persistentToasts.value = [];
    }
});

const getNotificationDetails = (notification: Notification) => {
  const content = notification.content || '';

  if (content.includes('[TASK_DELEGATED]')) {
      const parts = content.replace('[TASK_DELEGATED]', '').split('::');
      return {
          title: 'Nova Tarefa Recebida',
          message: parts[1] || 'Você recebeu uma nova atividade.',
          avatar: null,
          channelId: null,
          color: 'warning',
          isChat: false,
          isTask: true,
          icon: 'mdi-clipboard-check'
      };
  }

  // NOVA TRAVA PARA A TAREFA CONCLUÍDA
  if (content.includes('[TASK_COMPLETED]')) {
      const parts = content.replace('[TASK_COMPLETED]', '').split('::');
      return {
          title: 'Tarefa Concluída! 🎉',
          message: parts[1] || 'Uma tarefa delegada foi finalizada.',
          avatar: null,
          channelId: null,
          color: 'success',
          isChat: false,
          isTask: false,
          icon: 'mdi-check-decagram'
      };
  }

  if (notification.type === 'chat' || content.includes('[CHAT]')) {
      const rawMsg = content.replace('[CHAT]', '');
      if (rawMsg.includes('||')) {
          const parts = rawMsg.split('||');
          return {
              title: parts[0] || 'Nova Mensagem',
              avatar: parts[1] || 'https://ui-avatars.com/api/?name=Chat',
              message: parts[2] || 'Nova mensagem de chat.',
              channelId: parts[3] ? parseInt(parts[3]) : null,
              color: 'chat',
              isChat: true,
              icon: 'mdi-forum-outline'
          };
      }
      let msg = rawMsg;
      if (msg.includes('::')) msg = msg.split('::').pop() || msg;
      return {
          title: 'Nova Mensagem',
          message: msg,
          avatar: notification.sender_avatar || 'https://ui-avatars.com/api/?name=Chat',
          channelId: null,
          color: 'chat',
          isChat: true,
          icon: 'mdi-forum-outline'
      };
  }

  if (content.startsWith('[ALERT_PENDING_APPROVAL]')) {
    const parts = content.replace('[ALERT_PENDING_APPROVAL]', '').split('::');
    return { title: parts[0] || 'Alerta de Aprovação', message: parts[1] || 'Um novo pedido requer análise.', icon: 'mdi-alert-decagram', color: 'warning', isChat: false };
  }

  if (notification.type === 'financial_audit' || (notification.redirect_url && notification.redirect_url.includes('FinancialAuditView'))) {
      let msg = content;
      if (msg.includes('::')) msg = msg.split('::').pop() || msg;
      return { title: 'Auditoria Financeira', message: msg, icon: 'mdi-shield-alert', color: 'warning', isChat: false };
  }

  let title = 'Notificação';
  let message = content;
  if(content.includes('::')) {
      const parts = content.split('::');
      title = parts[0];
      message = parts[1];
  }

  const lowerTitleMsg = (title + message).toLowerCase();

  if (lowerTitleMsg.includes('cotação') || lowerTitleMsg.includes('cotacao')) {
      return { title: title !== 'Notificação' ? title : 'Nova Cotação', message, icon: 'mdi-file-document-edit', color: 'primary', isChat: false };
  }
  if (lowerTitleMsg.includes('serviço') || lowerTitleMsg.includes('servico')) {
      return { title: title !== 'Notificação' ? title : 'Ordem de Serviço', message, icon: 'mdi-handshake', color: 'primary', isChat: false };
  }
  if (lowerTitleMsg.includes('compra')) {
      return { title: title !== 'Notificação' ? title : 'Nova Compra', message, icon: 'mdi-cart', color: 'primary', isChat: false };
  }
  if (lowerTitleMsg.includes('baixa') || lowerTitleMsg.includes('recebi') || lowerTitleMsg.includes('pago') || lowerTitleMsg.includes('sucesso') || lowerTitleMsg.includes('confirm')) {
      return { title: title !== 'Notificação' ? title : 'Sucesso', message, icon: 'mdi-check-decagram', color: 'success', isChat: false };
  }
  if (lowerTitleMsg.includes('estorno') || lowerTitleMsg.includes('exclui') || lowerTitleMsg.includes('erro') || lowerTitleMsg.includes('delet') || lowerTitleMsg.includes('falha')) {
      return { title: title !== 'Notificação' ? title : 'Ação Revertida/Erro', message, icon: 'mdi-alert-octagon', color: 'error', isChat: false };
  }
  if (lowerTitleMsg.includes('edi') || lowerTitleMsg.includes('alter') || lowerTitleMsg.includes('atenção') || lowerTitleMsg.includes('lança')) {
      return { title: title !== 'Notificação' ? title : 'Atenção', message, icon: 'mdi-alert', color: 'warning', isChat: false };
  }

  return { title, message, icon: 'mdi-bell-outline', color: 'grey', isChat: false };
};

const isSuperAdminRestrictedNotif = (content: string) => {
  if (!content) return false;
  const lower = content.toLowerCase();
  return lower.includes('cotação') || lower.includes('cotacao') ||
         lower.includes('serviço') || lower.includes('servico') ||
         lower.includes('compra');
};

const getSidebarToastColor = (notification: Notification) => {
    const details = getNotificationDetails(notification);
    if (details.color === 'chat') return 'bg-blue-darken-2';
    if (details.color === 'success') return 'bg-emerald-green';
    if (details.color === 'error') return 'bg-red-accent-3';
    if (details.color === 'warning' || details.color === 'orange') return 'bg-orange-darken-1';
    if (details.color === 'primary') return 'bg-blue-darken-1';
    return 'bg-blue-grey-darken-2';
};

const persistentToasts = ref<any[]>([]);

const addPersistentToast = (notif: Notification) => {
    const details = getNotificationDetails(notif);
    let subtext = '';
    if(notif.content && notif.content.includes('::')) {
        const parts = notif.content.split('::');
        if (parts[2]) subtext = parts[2];
    }
    const canContest = notif.type === 'financial_audit' || (notif.redirect_url && notif.redirect_url.includes('FinancialAuditView'));

    let typeClass = 'neon-info';
    if (details.color === 'success') typeClass = 'neon-success';
    if (details.color === 'error') typeClass = 'neon-error';
    if (details.color === 'warning') typeClass = 'neon-warning';
    if (details.color === 'primary') typeClass = 'neon-primary';
    if (details.color === 'chat') typeClass = 'neon-chat';

    persistentToasts.value.push({
        id: notif.id,
        title: details.title,
        message: details.message,
        subtext: subtext,
        redirect_url: notif.redirect_url,
        created_at: notif.created_at,
        typeClass: typeClass,
        icon: details.icon,
        avatar: details.avatar,
        isChat: details.isChat,
        canContest: canContest,
        processing: false,
        isAudit: canContest
    });

    playThrottledSound('notification');
};

const closePersistentToast = async (id: string) => {
    const index = persistentToasts.value.findIndex(t => t.id === id);
    if(index !== -1) persistentToasts.value.splice(index, 1);
    await dismissNotification(id);
};

const handleContest = async (toast: any) => {
    const confirmed = confirm(`ATENÇÃO: Deseja realmente CONTESTAR esta ação?\n\nIsso irá reverter a operação financeira feita pelo vendedor imediatamente (exceto anexos).\n\nDeseja prosseguir?`);
    if (!confirmed) return;
    toast.processing = true;
    try {
        const { error } = await supabase.rpc('revert_financial_audit', { notification_id: toast.id });
        if (error) throw error;
        appStore.showSnackbar('Ação contestada e revertida com sucesso!', 'success');
        closePersistentToast(toast.id);
    } catch (e: any) {
        appStore.showSnackbar('Erro ao contestar: ' + (e.message || 'Erro desconhecido'), 'error');
    } finally {
        toast.processing = false;
    }
};

const handleToastClick = async (toast: any) => {
    if (toast.isAudit) {
        try { await router.push({ name: 'FinancialAuditView' }); } catch (e) {}
        await closePersistentToast(toast.id);
        return;
    }
    if(toast.redirect_url && toast.redirect_url !== 'null' && toast.redirect_url !== 'undefined') {
        try { await router.push(toast.redirect_url); } catch (e) {}
    }
    await closePersistentToast(toast.id);
};

const currentLowStockAlert = computed(() => lowStockAlerts.value.length > 0 ? lowStockAlerts.value[0] : null);
const dismissCurrentStockAlert = () => { if (currentLowStockAlert.value) appStore.dismissAlert(currentLowStockAlert.value.id); };

const unlockAudio = () => {
  if (!isAudioUnlocked.value) {
    const unlockSilently = (audio: HTMLAudioElement | null) => {
      if (audio) {
        audio.muted = true;
        audio.play().then(() => {
          audio.pause();
          audio.currentTime = 0;
          audio.muted = false;
        }).catch(() => {
          audio.muted = false;
        });
      }
    };

    unlockSilently(notificationSoundRef.value);
    unlockSilently(alertSound.value);
    unlockSilently(sendMessageSoundRef.value);
    unlockSilently(receiveMessageSoundRef.value);

    isAudioUnlocked.value = true;
  }
};

async function syncBlockedSitesWithElectron() {
 const api = (window as any).electronApi;
 if (api && typeof api.updateBlockedSites === 'function') {
  const { data: rules, error } = await supabase.from('productivity_rules').select('term').eq('classification', 'bloqueado');
  if (error) return;
  const sitesToBlock = rules.map(rule => rule.term);
  try { api.updateBlockedSites(sitesToBlock); } catch (e) {}
 }
}
(window as any).triggerElectronSiteSync = syncBlockedSitesWithElectron;

let presenceChannel: RealtimeChannel | null = null;
let inactivityTimer: number;

const updateStatus = async (status: 'online' | 'away' | 'offline') => {
 if (presenceChannel && userStore.profile) {
  try {
   if (status === 'offline') { await presenceChannel.untrack(); } else {
    await presenceChannel.track({ user_id: userStore.profile.id, status: status });
   }
   await supabase.from('user_presences').upsert({ user_id: userStore.profile.id, status, last_seen: new Date().toISOString() });
  } catch (error) {}
 }
};

const handleVisibilityChange = () => {
 if (document.visibilityState === 'visible') { resetInactivityTimer(); } else { updateStatus('away'); }
};

const resetInactivityTimer = () => {
 clearTimeout(inactivityTimer);
 updateStatus('online');
 inactivityTimer = setTimeout(() => updateStatus('away'), 3 * 60 * 1000);
};

const setupGlobalPresence = () => {
 if (!userStore.profile || presenceChannel) return;
 presenceChannel = supabase.channel('online-users', { config: { presence: { key: userStore.profile.id } } });
 presenceChannel.on('presence', { event: 'sync' }, () => {
   const presenceState = presenceChannel?.presenceState();
   if (presenceState) onlineStatusStore.setOnlineUsers(presenceState);
 }).subscribe(async (status) => {
   if (status === 'SUBSCRIBED') {
    resetInactivityTimer();
    window.addEventListener('mousemove', resetInactivityTimer);
    window.addEventListener('keydown', resetInactivityTimer);
    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('beforeunload', cleanupGlobalPresence);
   }
 });
};

const cleanupGlobalPresence = async () => {
 if (userStore.profile) await updateStatus('offline');
 if (presenceChannel) supabase.removeChannel(presenceChannel);
 window.removeEventListener('mousemove', resetInactivityTimer);
 window.removeEventListener('keydown', resetInactivityTimer);
 document.removeEventListener('visibilitychange', handleVisibilityChange);
 window.removeEventListener('beforeunload', cleanupGlobalPresence);
 clearTimeout(inactivityTimer);
 presenceChannel = null;
};

let isSystemBooted = false;
let isBooting = false;

const handleLogout = async () => {
  isLoggingOut.value = true;
  localStorage.setItem('explicit_logout', 'true');

  try {
    await cleanupGlobalPresence();
    await supabase.removeAllChannels();
  } catch (e) {}

  notificationListener.value = null;
  messageListener = null;
  isSystemBooted = false;

  await userStore.signOut();

  setTimeout(() => {
    window.location.href = '/login';
  }, 400);
};

const fetchNotifications = async () => {
  if (!userStore.user) return;
  try {
    const [{ data, error }, { data: dismissals, error: dismissalsError }] = await Promise.all([
      supabase.from('notifications')
        .select('*')
        .or(`recipient_id.is.null,recipient_id.eq.${userStore.user.id}`)
        .order('created_at', { ascending: false })
        .limit(50),
      supabase.from('user_notification_dismissals').select('notification_id').eq('user_id', userStore.user.id)
    ]);
    if (error) throw error;
    if (dismissalsError) throw dismissalsError;

    const dismissedIds = (dismissals || []).map((d: any) => d.notification_id);

    notifications.value = (data || [])
        .filter((n: any) => !dismissedIds.includes(n.id))
        .filter((n: any) => {
            const isChatNotif = n.type === 'chat' || (n.content && n.content.includes('[CHAT]'));
            if (isChatNotif && !canAccessChat.value) return false;

            const isApproval = n.content && n.content.startsWith('[ALERT_PENDING_APPROVAL]');
            if (isApproval && !canApprove.value) return false;

            const isRestricted = isSuperAdminRestrictedNotif(n.content);
            if (isRestricted && !userStore.isSuperAdmin) return false;

            return true;
        });
  } catch (error) {}
}

const handleNotificationClick = async (notification: Notification) => {
  if (!notification.is_read) {
    try {
      await supabase.from('notifications').update({ is_read: true }).eq('id', notification.id);
      const index = notifications.value.findIndex(n => n.id === notification.id);
      if (index !== -1) notifications.value[index].is_read = true;
    } catch(error) {}
  }
  await dismissNotification(notification.id);

  if (notification.redirect_url && notification.redirect_url.includes('FinancialAuditView')) {
      router.push({ name: 'FinancialAuditView' });
      notificationDrawer.value = false;
      return;
  }

  if (notification.redirect_url) {
      if (notification.redirect_url.startsWith('/cajuia')) {
        userStore.setModule('cajuia');
        companyStore.setContext('cajuia');
      } else {
        userStore.setModule('mj');
        companyStore.setContext('mjprocess');
      }
    notificationDrawer.value = false;
    router.push(notification.redirect_url);
  }
};

const dismissNotification = async (notificationId: string) => {
  if(!userStore.user) return;
  try {
    const { error } = await supabase.from('user_notification_dismissals').insert({ user_id: userStore.user.id, notification_id: notificationId });
    if (error && error.code !== '23505') throw error;
    notifications.value = notifications.value.filter(n => n.id !== notificationId);
  } catch (err) {}
};

const startClearAnimation = () => {
    if (notifications.value.length === 0) return;
    isClearing.value = true;
    const totalDelay = (notifications.value.length * 80) + 400;
    setTimeout(() => {
        clearAllNotifications();
        isClearing.value = false;
    }, totalDelay);
};

const clearAllNotifications = async () => {
  if(!userStore.user) return;
  try {
    const dismissals = notifications.value.map(n => ({ user_id: userStore.user!.id, notification_id: n.id }));
    if (dismissals.length === 0) return;
    const { error } = await supabase.from('user_notification_dismissals').insert(dismissals);
    if (error && error.code !== '23505') throw error;
    notifications.value = [];
  } catch (err) {}
};

const formatDistance = (dateString: string) => {
  if (!dateString) return '';
  return formatDistanceToNow(new Date(dateString), { addSuffix: false, locale: ptBR });
};

const setupMessageListener = () => {
    if (!userStore.user) return;
    if (messageListener) return;

    messageListener = supabase.channel(`global_messages_${userStore.user.id}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, async (payload) => {
          const newMsg = payload.new as any;
          const myId = userStore.user?.id;

          if (!myId) return;

          if (newMsg.profile_id === myId) {
             playThrottledSound('chat_send');
             return;
          }

          if (newMsg.message_type === 'system' || newMsg.message_type === 'text') return;

          let channel = chatStore.channels.find(c => c.id === newMsg.channel_id);
          if (!channel) {
              const { data: member } = await supabase.from('channel_members').select('channel_id').eq('channel_id', newMsg.channel_id).eq('profile_id', myId).single();
              if (!member) return;
              await chatStore.fetchChannels(myId);
          }

          const isAlreadyInChat = (isMiniChatOpen.value || route.name === 'Chat') && chatStore.activeChannel?.id === newMsg.channel_id;
          if (isAlreadyInChat) {
             playThrottledSound('chat_receive');
             return;
          }

          let msgPreview = newMsg.content || '';
          if (newMsg.message_type === 'audio') msgPreview = '🎵 Áudio de voz';
          else if (newMsg.message_type === 'image') msgPreview = '📷 Enviou uma foto';
          else if (newMsg.message_type === 'video') msgPreview = '🎥 Enviou um vídeo';
          else if (newMsg.message_type === 'document' || newMsg.message_type === 'file' || newMsg.message_type === 'media') msgPreview = '📎 Enviou um arquivo';

          if (newMsg.caption) {
              msgPreview = `📎 ${newMsg.caption}`;
          }

          if (!msgPreview || msgPreview.trim() === '') {
              msgPreview = '📎 Enviou um anexo';
          }

          let senderName = 'Usuário';
          let senderAvatar = 'https://ui-avatars.com/api/?name=Chat';
          const { data: profile } = await supabase.from('profiles').select('full_name, avatar_url').eq('id', newMsg.profile_id).single();
          if (profile) {
              senderName = profile.full_name || 'Usuário';
              senderAvatar = profile.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(senderName)}&background=1976D2&color=fff`;
          }

          chatToasts.value.push({
              id: `msg-${newMsg.id}`,
              title: senderName,
              message: msgPreview,
              avatar: senderAvatar,
              channelId: newMsg.channel_id,
              isTask: false
          });

          playThrottledSound('chat_receive');

          setTimeout(() => {
              const idx = chatToasts.value.findIndex(t => t.id === `msg-${newMsg.id}`);
              if (idx > -1) chatToasts.value.splice(idx, 1);
          }, 5000);
      })
      .subscribe((status) => {
         if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
          if (isLoggingOut.value) return;
             supabase.removeChannel(messageListener as RealtimeChannel);
             messageListener = null;
             setTimeout(() => setupMessageListener(), 3000);
         }
      });
};

const setupNotificationListener = () => {
  if (!userStore.user) return;
  if (notificationListener.value) return;

  notificationListener.value = supabase.channel(`notif_channel_${userStore.user.id}`)
    .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `recipient_id=eq.${userStore.user.id}`
    }, (payload) => {
      const newNotification = payload.new as any;
      const isChatNotif = newNotification.type === 'chat' || (newNotification.content && newNotification.content.includes('[CHAT]'));
      const isTaskNotif = newNotification.content && newNotification.content.includes('[TASK_DELEGATED]');

      const isForAll = newNotification.recipient_id === null;
      const isForMe = newNotification.recipient_id === userStore.user?.id;

      if (isForAll || isForMe) {
        const isApproval = newNotification.content && newNotification.content.startsWith('[ALERT_PENDING_APPROVAL]');
        if (isApproval && !canApprove.value) return;

        if (!isChatNotif && !isTaskNotif) {
            const isRestricted = isSuperAdminRestrictedNotif(newNotification.content);
            if (isRestricted && !userStore.isSuperAdmin) return;
        }

        if (notifications.value.some(n => n.id === newNotification.id)) return;
        notifications.value.unshift(newNotification);
        isBellRinging.value = true;

        if (isChatNotif || isTaskNotif) {
            const details = getNotificationDetails(newNotification) as any;

            if (isChatNotif) {
                const isAlreadyInChat = (isMiniChatOpen.value || route.name === 'Chat') && chatStore.activeChannel?.id === details.channelId;
                playThrottledSound('chat_receive');

                if (!isAlreadyInChat) {
                    chatToasts.value.push({
                        id: newNotification.id,
                        title: details.title,
                        message: details.message,
                        avatar: details.avatar,
                        channelId: details.channelId,
                        isTask: false
                    });

                    setTimeout(() => {
                        const idx = chatToasts.value.findIndex(t => t.id === newNotification.id);
                        if (idx > -1) chatToasts.value.splice(idx, 1);
                    }, 5000);
                }
            } else if (isTaskNotif) {
                // SE FOR TAREFA, JOGA PRO MODAL GIGANTE DE VIDRO
                centralTaskAlerts.value.push({
                    id: newNotification.id,
                    title: details.title,
                    message: details.message
                });

                try {
                    if (alertSound.value && isAudioUnlocked.value) {
                        alertSound.value.currentTime = 0;
                        alertSound.value.play().catch(e => {});
                    }
                } catch(e) {}
            }

        } else if (newNotification.content.startsWith('[ALERT_PENDING_APPROVAL]')) {
            const parts = newNotification.content.replace('[ALERT_PENDING_APPROVAL]', '').split('::');
            currentPendingApprovalAlert.value = { title: parts[0] || 'Aprovação Pendente', message: parts[1] || 'Um pedido requer sua atenção.', redirectUrl: newNotification.redirect_url };
            showPendingApprovalAlert.value = true;
            try {
                if (alertSound.value && isAudioUnlocked.value) {
                    alertSound.value.currentTime = 0;
                    alertSound.value.play().catch(e => {});
                }
            } catch(e) {}
        } else {
            addPersistentToast(newNotification);
        }
      }
    })
    .subscribe((status) => {
      if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
        if (isLoggingOut.value) return;
          supabase.removeChannel(notificationListener.value as RealtimeChannel);
          notificationListener.value = null;
          clearTimeout(reconnectTimer);
          reconnectTimer = setTimeout(() => setupNotificationListener(), 3000);
      }
    });
};

const handleGoToApproval = () => {
 if (currentPendingApprovalAlert.value?.redirectUrl) { router.push(currentPendingApprovalAlert.value.redirectUrl); }
 showPendingApprovalAlert.value = false;
 currentPendingApprovalAlert.value = null;
 if (alertSound.value) { alertSound.value.pause(); alertSound.value.currentTime = 0; }
};

const bootSystem = async () => {
    if (isSystemBooted || isBooting) return;
    if (!userStore.user) return;

    isBooting = true;

    try {
        await companyStore.initialize();

        if (!canChangeCompany.value && userStore.profile?.company_id) {
            companyStore.setContext(userStore.profile.company_id);
        }

        await fetchRolePermissions();

        const api = (window as any).electronApi;
        if (api && typeof api.setUserId === 'function') { api.setUserId(userStore.user.id); }
        await syncBlockedSitesWithElectron();

        await fetchNotifications();
        setupNotificationListener();
        setupMessageListener();
        setupGlobalPresence();

        isSystemBooted = true;
    } finally {
        isBooting = false;
    }
};

const checkStock = async () => {
  if (!userStore.profile) {
    await userStore.fetchProfile()
  }
  if (userStore.profile) {
    await appStore.fetchGlobalConfigs()
    await appStore.checkConsolidatedLowStock(userStore.profile)
  }
}

onMounted(async () => {
 const savedBg = localStorage.getItem('mjprocess-background');
 currentBackground.value = savedBg || backgrounds.value[0];

 const savedFont = localStorage.getItem('sidebarFontSize');
 const savedIcon = localStorage.getItem('sidebarIconSize');
 if (savedFont) sidebarFontSize.value = Number(savedFont);
 if (savedIcon) sidebarIconSize.value = Number(savedIcon);

 if (notificationSoundRef.value) { chatStore.initializeSound(notificationSoundRef.value); }

 if (userStore.isLoggedIn && userStore.user?.id) {
    await bootSystem();
 }

 supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' && session) {
      bootSystem();
    } else if (event === 'SIGNED_OUT') {
      isSystemBooted = false;
    }
 });

 stockCheckInterval = setInterval(() => {
    if (userStore.user) { checkStock(); }
 }, 10 * 60 * 1000);

 recurrenceInterval = setInterval(() => {
    if (userStore.user) checkRecurringTasks();
 }, 60 * 1000); // Roda a cada 1 minuto
});

onUnmounted(() => {
 delete (window as any).triggerElectronSiteSync;
 const api = (window as any).electronApi;
 if (api && typeof api.setUserId === 'function') { api.setUserId(null); }
 cleanupGlobalPresence();
 if (notificationListener.value) supabase.removeChannel(notificationListener.value);
 if (messageListener) supabase.removeChannel(messageListener);
 clearTimeout(reconnectTimer);
 if (stockCheckInterval) clearInterval(stockCheckInterval);
 if (recurrenceInterval) clearInterval(recurrenceInterval);
});
</script>

<style lang="scss">
.background-container { position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; background-color: #121212; background-size: cover; background-position: center; transition: background-image 1.5s ease-in-out; }
.background-solid { position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; }
.particles-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background-color: rgba(18, 18, 18, 0.6); }
.v-application, .v-application__wrap { background: transparent !important; }

.v-overlay-container .v-tooltip > .v-overlay__content,
.custom-tooltip,
.v-tooltip > .v-overlay__content {
    background-color: rgba(20, 20, 25, 0.95) !important;
    color: #ffffff !important;
    font-size: 11px !important;
    font-weight: 600 !important;
    border-radius: 6px !important;
    opacity: 1 !important;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2) !important;
}

.v-theme--light .custom-tooltip,
.v-theme--light .v-tooltip > .v-overlay__content {
    background-color: #212121 !important;
    color: #ffffff !important;
}

.modern-toast, .sidebar-toast { color: #ffffff !important; }
.modern-toast span, .modern-toast p, .modern-toast i, .sidebar-toast span, .sidebar-toast p, .sidebar-toast i, .modern-toast .v-icon, .sidebar-toast .v-icon { color: #ffffff !important; }
.persistent-toast-wrapper { position: fixed; bottom: 30px; right: 30px; z-index: 999999; display: flex; flex-direction: column; width: 380px; max-width: 90vw; pointer-events: none; }
.toast-container-gap { gap: 14px; }
.modern-toast { pointer-events: auto; position: relative; overflow: hidden; border-radius: 8px; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15), 0 4px 8px rgba(0, 0, 0, 0.1) !important; border: none; cursor: pointer; min-height: 80px; display: flex; flex-direction: column; transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); margin-bottom: 12px; }
.modern-toast:hover { transform: translateY(-4px) scale(1.01); box-shadow: 0 14px 40px rgba(0, 0, 0, 0.2), 0 5px 10px rgba(0, 0, 0, 0.1) !important; }
.toast-content-wrapper { flex-grow: 1; padding: 16px; position: relative; z-index: 2; }
.modern-toast.neon-success { background-color: #10B981 !important; }
.modern-toast.neon-error   { background-color: #EF4444 !important; }
.modern-toast.neon-warning { background-color: #F59E0B !important; }
.modern-toast.neon-info    { background-color: #3B82F6 !important; }
.modern-toast.neon-primary { background-color: #1E88E5 !important; }
.modern-toast.neon-chat    { background-color: #0288D1 !important; }
.bg-black-20 { background-color: rgba(0, 0, 0, 0.15) !important; border-color: rgba(255, 255, 255, 0.3) !important; }
.sidebar-toast { padding: 16px; border-radius: 8px; cursor: pointer; box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1), 0 2px 4px rgba(0,0,0,0.05); transition: all 0.3s ease; border: 1px solid rgba(255,255,255,0.1); }
.sidebar-toast:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15); filter: brightness(1.05); }

.gap-3 { gap: 12px; }
.hover-opacity-100:hover { opacity: 1 !important; }
.bg-emerald-green { background-color: #10B981 !important; }
.bg-red-accent-3 { background-color: #EF5350 !important; }
.bg-orange-darken-1 { background-color: #F57C00 !important; }
.bg-blue-grey-darken-2 { background-color: #455A64 !important; }
.bg-blue-darken-1 { background-color: #1E88E5 !important; }
.bg-blue-darken-2 { background-color: #0288D1 !important; }

.toast-anim-leave-active { transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275); position: absolute; width: 100%; }

@keyframes slideOutRightCascading { 0% { transform: translateX(0); opacity: 1; } 100% { transform: translateX(120%); opacity: 0; } }
.cascading-out { animation: slideOutRightCascading 0.4s cubic-bezier(0.55, 0.085, 0.68, 0.53) forwards; pointer-events: none; }
.cascade-slide-enter-active, .cascade-slide-leave-active { transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1); }
.cascade-slide-enter-from, .cascade-slide-leave-to { opacity: 0; transform: translateX(30px); }
.header-actions-container { gap: 8px; }

.premium-drawer { border-right: 1px solid rgba(255, 255, 255, 0.08) !important; transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important; }
.glassmorphism-sidebar.glass-dark { background-color: rgba(15, 15, 20, 0.85) !important; backdrop-filter: blur(25px); -webkit-backdrop-filter: blur(25px); border-right: 1px solid rgba(255, 255, 255, 0.05) !important; }
.glassmorphism-sidebar.glass-light { background-color: rgba(255, 255, 255, 0.92) !important; backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); border-right: 1px solid rgba(0, 0, 0, 0.05) !important; }
.logo-container { height: 80px; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; cursor: pointer; }
.rail-logo { height: 60px; padding: 0 !important; }
.logo-wrapper { width: 100%; height: 100%; transition: all 0.3s ease; }
.logo-img { height: 100%; max-height: 50px; width: auto; object-fit: contain; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.logo-img-rail { max-height: 32px; max-width: 32px; }

.context-selector-minimal { transition: all 0.2s ease; }
.context-selector-minimal:hover .bg-transparent-hover { background-color: rgba(128,128,128,0.05) !important; }
.icon-box-mini { width: 28px; height: 28px; }
.bg-purple-subtle { background: rgba(123, 31, 162, 0.1); }
.bg-blue-subtle { background: rgba(25, 118, 210, 0.1); }
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.2); border-radius: 4px; }
.custom-scrollbar:hover::-webkit-scrollbar-thumb { background: rgba(128, 128, 128, 0.4); }

.v-navigation-drawer:not(.v-navigation-drawer--rail) .v-list-group__items .v-list-item { padding-inline-start: 12px !important; }
.unified-block-group.v-list-group--open { transition: background-color 0.2s ease; border-radius: 8px; margin-bottom: 4px; }
.v-theme--light .unified-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.035); }
.v-theme--dark .unified-block-group.v-list-group--open { background-color: rgba(255, 255, 255, 0.035); }
.block-active-header { background-color: transparent !important; opacity: 1 !important; }
.nested-block-group.v-list-group--open { margin: 2px 4px 2px 8px; border-radius: 6px; }
.v-theme--light .nested-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.04); }
.v-theme--dark .nested-block-group.v-list-group--open { background-color: rgba(255, 255, 255, 0.04); }
.rail-mode .v-list-item__prepend { margin-right: 0 !important; justify-content: center; }
.rail-mode .v-list-group__items .v-list-item { padding-left: 0 !important; justify-content: center; }

.fixed-font-size { font-size: var(--sidebar-font-size) !important; }
.fixed-size-icon { font-size: var(--sidebar-icon-size) !important; }
.v-navigation-drawer > .v-navigation-drawer__content { display: flex; flex-direction: column; overflow: hidden; }
.main-nav-list-wrapper { flex: 1; overflow-y: auto; overflow-x: hidden; }

@keyframes checkPop { 0% { transform: scale(0); opacity: 0; } 50% { transform: scale(1.2); } 100% { transform: scale(1); opacity: 1; } }
.check-pop-animation { animation: checkPop 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
.bell-ringing { animation: ring 1.5s ease-in-out infinite; }
@keyframes ring { 0% { transform: rotate(0); } 10% { transform: rotate(25deg); } 20% { transform: rotate(-25deg); } 30% { transform: rotate(20deg); } 40% { transform: rotate(-20deg); } 50% { transform: rotate(15deg); } 60% { transform: rotate(-15deg); } 70% { transform: rotate(5deg); } 80% { transform: rotate(-5deg); } 90%, 100% { transform: rotate(0); } }

.toast-anim-enter-active, .toast-anim-leave-active { transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.toast-anim-enter-from, .toast-anim-leave-to { opacity: 0; transform: translateX(40px) scale(0.95); }
.toast-anim-move { transition: transform 0.4s ease; }
.glassmorphism-card-dialog { backdrop-filter: blur(20px) !important; background-color: rgba(30, 30, 35, 0.95) !important; border-radius: 12px !important; border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
.glass-light-card { backdrop-filter: blur(20px) !important; background-color: rgba(255, 255, 255, 0.95) !important; border-radius: 12px !important; border: 1px solid rgba(0, 0, 0, 0.05); box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1); }

.global-viewer-mode .v-btn:not(.v-btn--variant-text):not(.v-pagination__item) { filter: grayscale(100%) !important; opacity: 0.5 !important; pointer-events: none !important; }
.global-viewer-mode input, .global-viewer-mode textarea, .global-viewer-mode .v-select, .global-viewer-mode .v-autocomplete, .global-viewer-mode .v-switch, .global-viewer-mode .v-checkbox { pointer-events: none !important; }
.global-viewer-mode .v-card { opacity: 0.95; }
.global-viewer-mode .search-wrap input, .global-viewer-mode .search-wrap .v-btn, .global-viewer-mode .v-pagination .v-btn, .global-viewer-mode .v-tab { pointer-events: auto !important; filter: none !important; opacity: 1 !important; }

/* ======== APP LAUNCHER STYLES ======== */
.elegant-app-btn { transition: transform 0.2s ease; }
.elegant-app-btn:hover { transform: scale(1.08); background-color: rgba(var(--v-theme-primary), 0.1); }

.premium-app-card {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 12px;
    border-radius: 16px;
    margin-bottom: 8px;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
    background: rgba(128,128,128,0.03);
    border: 1px solid rgba(128,128,128,0.05);
    animation: slideUpFade 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) both;
}
.premium-app-card:hover {
    transform: scale(1.02) translateY(-2px);
    background: rgba(128,128,128,0.08);
    box-shadow: 0 8px 24px rgba(0,0,0,0.08);
}
.premium-app-card:active {
    transform: scale(0.98);
}

.app-icon-3d {
    width: 44px;
    height: 44px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    box-shadow: 0 6px 12px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2), inset 0 -2px 0 rgba(0,0,0,0.1);
    position: relative;
    overflow: hidden;
    flex-shrink: 0;
}
.app-icon-3d::after {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0; height: 50%;
    background: linear-gradient(to bottom, rgba(255,255,255,0.2), transparent);
    border-radius: 12px 12px 0 0;
}

.app-text {
    display: flex;
    flex-direction: column;
    line-height: 1.2;
}
.app-text .title {
    font-size: 13px;
    font-weight: 800;
}
.app-text .subtitle {
    font-size: 11px;
    opacity: 0.6;
    margin-top: 2px;
    font-weight: 500;
}
.app-category-label {
    font-size: 10px;
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 1px;
    opacity: 0.5;
    margin-bottom: 8px;
    padding-left: 4px;
}

@keyframes slideUpFade {
    0% { opacity: 0; transform: translateY(15px); }
    100% { opacity: 1; transform: translateY(0); }
}

/* Gradients for App Icons */
.gradient-design { background: linear-gradient(135deg, #EC407A, #C2185B); }
.gradient-rh { background: linear-gradient(135deg, #AB47BC, #512DA8); }
.gradient-fleet { background: linear-gradient(135deg, #FFA726, #E65100); }
.gradient-storefront { background: linear-gradient(135deg, #FF7043, #BF360C); }
.gradient-email { background: linear-gradient(135deg, #42A5F5, #1565C0); }
.gradient-finance { background: linear-gradient(135deg, #26A69A, #00695C); }
.gradient-erp { background: linear-gradient(135deg, #66BB6A, #2E7D32); }
.gradient-demo { background: linear-gradient(135deg, #B0BEC5, #455A64); }
.gradient-demo-active { background: linear-gradient(135deg, #EF5350, #C62828); }

.pulse-demo-border { box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4); animation: pulse-border 1.5s infinite cubic-bezier(0.66, 0, 0, 1); }
@keyframes pulse-border { to { box-shadow: 0 0 0 10px rgba(244, 67, 54, 0); } }

/* ===================================== */

.elegant-search-wrapper { position: absolute; left: 50%; transform: translateX(-50%); width: 100%; max-width: 380px; transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1); z-index: 10; }
.elegant-search-wrapper.mobile-search { position: relative; left: auto; transform: none; max-width: 100%; flex-grow: 1; margin: 0 12px; }
.elegant-search-wrapper.search-active-state { max-width: 480px; }
.elegant-search-input .v-field__outline { display: none !important; }

.shimmer-search .v-field { border-radius: 40px !important; background: rgba(var(--v-theme-surface), 0.6) !important; backdrop-filter: blur(12px) !important; -webkit-backdrop-filter: blur(12px) !important; border: 1px solid rgba(var(--v-theme-primary), 0.3) !important; box-shadow: 0 4px 12px rgba(var(--v-theme-primary), 0.08) !important; transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1) !important; padding-right: 8px; position: relative; overflow: hidden; }
.shimmer-search .v-field::before { content: ''; position: absolute; top: 0; left: -100%; width: 50%; height: 100%; background: linear-gradient(to right, transparent, rgba(var(--v-theme-primary), 0.15), transparent); transform: skewX(-20deg); animation: shimmer 4s infinite; }
@keyframes shimmer { 0% { left: -100%; } 20% { left: 200%; } 100% { left: 200%; } }

.v-theme--dark .shimmer-search .v-field { background: rgba(0, 0, 0, 0.3) !important; border: 1px solid rgba(var(--v-theme-primary), 0.4) !important; box-shadow: 0 4px 15px rgba(var(--v-theme-primary), 0.15) !important; }
.shimmer-search .v-field::before { background: linear-gradient(to right, transparent, rgba(255,255,255, 0.15), transparent); }

.elegant-search-input .v-field--focused { background: rgba(var(--v-theme-surface), 0.95) !important; border-color: rgba(var(--v-theme-primary), 0.8) !important; box-shadow: 0 6px 20px rgba(var(--v-theme-primary), 0.15), 0 0 0 4px rgba(var(--v-theme-primary), 0.1) !important; transform: translateY(-1px); }
.v-theme--dark .elegant-search-input .v-field--focused { background: rgba(20, 20, 25, 0.95) !important; }
.elegant-search-input .v-field__input { min-height: 38px !important; padding-top: 0px !important; padding-bottom: 0px !important; font-size: 0.9rem !important; font-weight: 600 !important; letter-spacing: 0.3px; color: rgba(var(--v-theme-on-surface), 0.9) !important; }
.elegant-search-input .v-icon { opacity: 0.6; font-size: 1.2rem !important; transition: all 0.3s ease; }
.elegant-search-input .v-field--focused .v-icon { opacity: 1; color: rgb(var(--v-theme-primary)) !important; }

.screen-fade-enter-active, .screen-fade-leave-active { transition: opacity 0.3s ease-out, transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1); }
.screen-fade-enter-from { opacity: 0; transform: scale(0.98) translateY(10px); }
.screen-fade-leave-to { opacity: 0; transform: scale(1.02) translateY(-10px); }

.search-overlay-container { background: rgba(var(--v-theme-surface), 0.75); backdrop-filter: blur(18px); -webkit-backdrop-filter: blur(18px); z-index: 5; }
.fade-fast-enter-active, .fade-fast-leave-active { transition: opacity 0.2s ease; }
.fade-fast-enter-from, .fade-fast-leave-to { opacity: 0; }

.search-grid-container { display: flex; flex-wrap: wrap; justify-content: center; gap: 24px; width: 100%; position: relative; }
.search-grid-item { flex: 1 1 calc(25% - 24px); max-width: calc(25% - 24px); min-width: 250px; display: flex; flex-direction: column; }
@media (max-width: 960px) { .search-grid-item { flex: 1 1 calc(33.333% - 24px); max-width: calc(33.333% - 24px); } }
@media (max-width: 600px) { .search-grid-item { flex: 1 1 100%; max-width: 100%; } }

.search-anim-enter-active { transition: opacity 0.5s ease, transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1); }
.search-anim-leave-active { transition: opacity 0.15s ease, transform 0.15s ease; position: absolute !important; pointer-events: none; z-index: -1; }
.search-anim-move { transition: transform 0.5s cubic-bezier(0.34, 1.56, 0.64, 1); }
.search-anim-enter-from { opacity: 0; transform: scale(0.6) translateY(40px); }
.search-anim-leave-to { opacity: 0; transform: scale(0.8); }

.modern-search-card { transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1); background: linear-gradient(145deg, rgba(var(--v-theme-surface), 1) 0%, rgba(var(--v-theme-surface), 0.8) 100%) !important; }
.v-theme--dark .modern-search-card { background: linear-gradient(145deg, rgba(30,30,35, 0.9) 0%, rgba(20,20,25, 0.95) 100%) !important; }
.modern-search-card:hover { transform: translateY(-6px) scale(1.03); box-shadow: 0 20px 40px rgba(0,0,0,0.12), 0 0 0 1px rgba(var(--v-theme-primary), 0.3) !important; }
.search-card-avatar { transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); }
.modern-search-card:hover .search-card-avatar { transform: scale(1.15) rotate(-5deg); }
.search-btn-hover { transition: transform 0.2s ease, background-color 0.2s; }
.modern-search-card:hover .search-btn-hover { transform: translateY(-2px); background-color: rgb(var(--v-theme-primary)) !important; color: white !important; }

.tracking-widest { letter-spacing: 0.1em !important; }
.lh-1 { line-height: 1.1 !important; }

/* CHAT TOAST TOP-CENTER */
.chat-toast-wrapper { position: fixed; top: 24px; left: 50%; transform: translateX(-50%); z-index: 999999; display: flex; flex-direction: column; align-items: center; pointer-events: none; width: 100%; max-width: 400px; padding: 0 16px; }
.chat-glass-toast { pointer-events: auto; background: rgba(30, 30, 35, 0.85); backdrop-filter: blur(25px); -webkit-backdrop-filter: blur(25px); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 16px; padding: 14px 18px; width: 100%; cursor: pointer; box-shadow: 0 12px 40px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.05); transition: transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1), background 0.2s; }
.chat-glass-toast:hover { transform: translateY(-2px) scale(1.02); background: rgba(40, 40, 45, 0.95); border-color: rgba(var(--v-theme-primary), 0.6); }
.chat-toast-anim-enter-active, .chat-toast-anim-leave-active { transition: all 0.5s cubic-bezier(0.34, 1.56, 0.64, 1); }
.chat-toast-anim-enter-from { opacity: 0; transform: translateY(-30px) scale(0.9); }
.chat-toast-anim-leave-to { opacity: 0; transform: translateY(-30px) scale(0.9); position: absolute; }

.sidebar-3d-l0, .sidebar-3d-l1, .sidebar-3d-l2 { border: none !important; box-shadow: none !important; background-color: transparent; margin-bottom: 4px; transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1) !important; }
.sidebar-3d-l0:active, .sidebar-3d-l1:active, .sidebar-3d-l2:active { transform: scale(0.98) !important; }
.unified-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.02) !important; box-shadow: inset 0 6px 14px -6px rgba(0, 0, 0, 0.12), inset 0 1px 3px rgba(0, 0, 0, 0.04) !important; border-radius: 8px; margin-bottom: 6px; padding-bottom: 4px; border-top: 1px solid rgba(0, 0, 0, 0.03); }
.v-theme--light .unified-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.035); }
.v-theme--dark .unified-block-group.v-list-group--open { background-color: rgba(255, 255, 255, 0.035); }
.block-active-header { background-color: rgba(255, 255, 255, 0.4) !important; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.08), 0 4px 8px -4px rgba(0, 0, 0, 0.04) !important; position: relative; z-index: 2; border-radius: 8px; transform: translateY(-1px); }
.nested-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.035) !important; box-shadow: inset 0 8px 16px -6px rgba(0, 0, 0, 0.15), inset 0 2px 4px rgba(0, 0, 0, 0.05) !important; border-radius: 6px; margin: 2px 4px 4px 8px; padding-bottom: 2px; border-top: 1px solid rgba(0, 0, 0, 0.04); }
.nested-block-active-header { background-color: rgba(255, 255, 255, 0.3) !important; box-shadow: 0 6px 12px -4px rgba(0, 0, 0, 0.1), 0 3px 6px -3px rgba(0, 0, 0, 0.05) !important; position: relative; z-index: 2; border-radius: 6px; transform: translateY(-1px); }

.v-theme--dark {
    .unified-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.2) !important; box-shadow: inset 0 10px 20px -5px rgba(0, 0, 0, 0.5), inset 0 2px 5px rgba(0, 0, 0, 0.3) !important; border-top: 1px solid rgba(0, 0, 0, 0.4); border-bottom: 1px solid rgba(255, 255, 255, 0.02); }
    .block-active-header { background-color: rgba(255, 255, 255, 0.04) !important; box-shadow: 0 12px 20px -4px rgba(0, 0, 0, 0.5), 0 4px 8px -2px rgba(0, 0, 0, 0.3) !important; border-top: 1px solid rgba(255, 255, 255, 0.05); }
    .nested-block-group.v-list-group--open { background-color: rgba(0, 0, 0, 0.35) !important; box-shadow: inset 0 12px 25px -5px rgba(0, 0, 0, 0.7), inset 0 3px 8px rgba(0, 0, 0, 0.5) !important; border-top: 1px solid rgba(0, 0, 0, 0.6); border-bottom: 1px solid rgba(255, 255, 255, 0.015); }
    .nested-block-active-header { background-color: rgba(255, 255, 255, 0.03) !important; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.6), 0 3px 6px -2px rgba(0, 0, 0, 0.4) !important; border-top: 1px solid rgba(255, 255, 255, 0.04); }
}

.logout-overlay-premium { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(10, 10, 12, 0.85); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); z-index: 9999999; }
.fade-overlay-enter-active, .fade-overlay-leave-active { transition: opacity 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); }
.fade-overlay-enter-from, .fade-overlay-leave-to { opacity: 0; }

.central-task-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999999;
  background: rgba(10, 10, 12, 0.4);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}

.central-task-modal {
  width: 90%;
  max-width: 480px;
  background: rgba(30, 30, 35, 0.85);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 30px 60px rgba(0, 0, 0, 0.6);
}

.bell-shake {
  animation: shake 0.8s cubic-bezier(.36,.07,.19,.97) both infinite;
}

@keyframes shake {
  10%, 90% { transform: translate3d(-2px, 0, 0) rotate(-5deg); }
  20%, 80% { transform: translate3d(4px, 0, 0) rotate(5deg); }
  30%, 50%, 70% { transform: translate3d(-6px, 0, 0) rotate(-10deg); }
  40%, 60% { transform: translate3d(6px, 0, 0) rotate(10deg); }
}
</style>
