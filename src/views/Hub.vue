<template>
  <v-theme-provider :theme="currentThemeName" with-background class="fill-height">
    <div class="hub-wrapper d-flex flex-column" :class="themeClass">

      <div class="global-carousel-container">
        <div
          v-for="(bg, index) in backgrounds"
          :key="index"
          class="bg-slide"
          :style="{ backgroundImage: `url(${bg})` }"
          :class="{ 'active': currentBgIndex === index }"
        ></div>
        <div class="bg-overlay"></div>
      </div>

      <div class="welcome-container d-flex flex-column align-center text-center" :class="{ 'hide-up': isNavigating }">
          <v-chip size="small" variant="flat" :color="isLightMode ? 'rgba(0,0,0,0.05)' : 'rgba(255,255,255,0.1)'" class="font-weight-bold mb-4 backdrop-blur border-white-sm text-uppercase" :class="textPrimaryClass">
              <v-icon start size="small" :color="isLightMode ? 'green-darken-3' : 'green-accent-3'">mdi-shield-check</v-icon>
              Ambiente Seguro
          </v-chip>
          <h1 class="text-h3 font-weight-black mb-1" :class="[textPrimaryClass, !isLightMode ? 'text-shadow-lg' : '']" style="letter-spacing: -1px;">
              Olá, {{ userFirstName }} <span class="waving-hand d-inline-block ml-2">👋</span>
          </h1>
          <h2 class="text-subtitle-1 font-weight-medium text-uppercase tracking-widest opacity-80" :class="textPrimaryClass">
              {{ customRoleName || userRoleFormatted }}
          </h2>
      </div>

      <div class="absolute-header-layer" :class="{ 'hide-up': isNavigating }">
        <div class="system-ticker d-flex align-center justify-center px-4" :class="headerBarClass">
          <v-icon size="x-small" :color="isLightMode ? 'amber-darken-2' : 'amber-accent-3'" class="mr-3 blink">mdi-alert-decagram</v-icon>
          <v-fade-transition mode="out-in">
            <span :key="currentTickerIndex" class="ticker-text text-caption font-weight-medium tracking-wide text-uppercase text-truncate" :class="textPrimaryClass">
              {{ systemNotices[currentTickerIndex] }}
            </span>
          </v-fade-transition>
        </div>

        <div class="left-controls">
          <div class="d-flex flex-column gap-3">
             <v-tooltip text="Alterar Tema" location="right" content-class="custom-tooltip">
               <template v-slot:activator="{ props }">
                 <div class="glass-icon-btn shadow-sm" :class="iconBtnClass" v-bind="props" @click="cycleTheme">
                   <v-icon size="small" :color="isLightMode ? 'primary' : 'white'">{{ themeIcon }}</v-icon>
                 </div>
               </template>
             </v-tooltip>

             <v-tooltip text="App Marketplace" location="right" content-class="custom-tooltip">
               <template v-slot:activator="{ props }">
                 <div class="glass-icon-btn shadow-sm" :class="iconBtnClass" v-bind="props" @click="marketplaceDialog = true">
                   <v-icon size="small" :color="isLightMode ? 'grey-darken-2' : 'cyan-accent-2'">mdi-view-grid-plus-outline</v-icon>
                 </div>
               </template>
             </v-tooltip>
          </div>
        </div>

        <div class="weather-widget">
          <v-menu v-model="weatherMenu" location="bottom end" transition="slide-y-transition" :close-on-content-click="false" width="280">
            <template v-slot:activator="{ props }">
              <div class="glass-pill clickable weather-pill d-flex align-center px-4 py-2 shadow-md" :class="pillClass" v-bind="props">
                <div class="d-flex flex-column align-end mr-3 text-right hidden-xs">
                  <span class="text-subtitle-2 font-weight-bold lh-1" :class="textPrimaryClass">{{ selectedCity.name }}</span>
                  <span class="text-caption lh-1 text-uppercase font-weight-medium opacity-70" :class="textPrimaryClass" style="font-size: 10px;">
                    {{ currentDayOfWeek }} • {{ weatherCondition }}
                  </span>
                </div>
                <div class="text-h5 font-weight-light mr-3" :class="textPrimaryClass">{{ weatherTemp }}°</div>
                <v-icon :color="weatherIconColor" size="28" class="weather-icon-anim drop-shadow-sm">{{ weatherIcon }}</v-icon>
              </div>
            </template>
            <v-card class="rounded-xl pa-0 overflow-hidden" :class="menuCardClass">
               <div class="pa-4 d-flex align-center justify-space-between" :class="isLightMode ? 'bg-grey-lighten-3' : 'bg-glass-header'">
                <span class="text-caption font-weight-bold text-uppercase tracking-wide" :class="textPrimaryClass">Localização</span>
                <v-btn icon size="x-small" variant="text" @click="weatherMenu = false"><v-icon>mdi-close</v-icon></v-btn>
              </div>
              <div class="pa-2">
                <v-list bg-color="transparent" density="compact">
                  <v-list-item v-for="city in predefinedCities" :key="city.name" @click="changeCity(city)" rounded="lg" class="mb-1 city-item" :class="{ 'active-city': selectedCity.name === city.name, 'light-hover': isLightMode }">
                    <template v-slot:prepend><v-icon size="small" :color="selectedCity.name === city.name ? 'amber-accent-3' : (isLightMode ? 'grey-darken-1' : 'grey')">mdi-map-marker</v-icon></template>
                    <v-list-item-title class="text-caption font-weight-bold" :class="textPrimaryClass">{{ city.name }}</v-list-item-title>
                  </v-list-item>
                </v-list>
                <v-divider class="my-2 border-opacity-25"></v-divider>
                <div class="d-flex justify-space-between align-center px-4 pb-2">
                  <div class="text-center"><v-icon color="blue-lighten-3" size="small">mdi-water</v-icon><div class="text-caption mt-1" :class="textSecondaryClass">{{ weatherHumidity }}%</div></div>
                  <div class="text-center"><v-icon :color="isLightMode ? 'grey-darken-1' : 'grey-lighten-3'" size="small">mdi-weather-windy</v-icon><div class="text-caption mt-1" :class="textSecondaryClass">{{ weatherWind }}km/h</div></div>
                  <div class="text-center"><v-icon color="orange-lighten-3" size="small">mdi-thermometer</v-icon><div class="text-caption mt-1" :class="textSecondaryClass">{{ weatherFeelsLike }}°</div></div>
                </div>
              </div>
            </v-card>
          </v-menu>
        </div>
      </div>

      <div v-if="loadingCompanies" class="flex-grow-1 d-flex flex-column align-center justify-center relative z-index-10">
         <v-progress-circular indeterminate :color="isLightMode ? 'primary' : 'white'" size="40"></v-progress-circular>
         <div class="mt-4 font-weight-bold text-caption text-uppercase" :class="textPrimaryClass">Buscando Unidades...</div>
      </div>

      <v-fade-transition>
        <div v-if="!isNavigating && !loadingCompanies" class="hub-main-content">
          <div class="scene-3d-wrapper" :class="{ 'fade-out-scale': isNavigating }">

            <div class="nav-arrow left-arrow" @click.stop="rotateCarousel('prev')" v-if="mappedCompanies.length > 1">
              <div class="large-arrow"><v-icon size="36" :color="isLightMode ? 'grey-darken-3' : 'white'">mdi-chevron-left</v-icon></div>
            </div>

            <div class="scene-3d">
              <div class="carousel-platform">

                <div
                  v-for="(panel, index) in mappedCompanies"
                  :key="panel.id"
                  class="card-3d-container"
                  :class="getCardClass(index)"
                  @click="handleCardClick(panel, index)"
                >
                  <div class="card-3d-wrapper">
                    <div class="glass-card-3d d-flex flex-column justify-space-between pa-6"
                         :class="[card3DClass, { 'restricted-card': panel.restricted }]">

                      <div v-if="!panel.restricted && !isLightMode" class="card-glow" :class="panel.glowClass"></div>

                      <div class="professional-lock-overlay" v-if="panel.restricted">
                         <div class="lock-circle">
                           <v-icon size="32" :color="isLightMode ? 'grey-darken-2' : 'white'">mdi-lock</v-icon>
                         </div>
                         <div class="text-subtitle-1 font-weight-black text-uppercase tracking-wide mt-2">Acesso Restrito</div>
                         <div class="text-caption mt-1 px-6 text-center opacity-80 lh-1-4">
                           Seu perfil não possui permissão para acessar esta unidade.
                         </div>
                      </div>

                      <div class="card-content d-flex flex-column h-100 justify-space-between text-center" :class="{ 'opacity-20': panel.restricted }">
                        <div>
                          <div class="d-flex justify-space-between align-start w-100 mb-6">
                            <v-chip size="x-small" :color="panel.restricted ? 'grey' : panel.chipColor" variant="flat" class="font-weight-bold tracking-wide">{{ panel.chipText }}</v-chip>
                            <v-icon size="small" :color="panel.restricted ? 'grey' : 'green-accent-3'">
                              {{ panel.restricted ? 'mdi-minus-circle-outline' : 'mdi-wifi' }}
                            </v-icon>
                          </div>

                          <div class="logo-area mb-6 d-flex align-center justify-center" style="height: 60px;">
                            <v-img :src="panel.logo" max-height="60" contain class="mx-auto drop-shadow-logo"></v-img>
                          </div>

                          <h2 class="text-h5 font-weight-black mb-1" :class="textPrimaryClass">{{ panel.trade_name || panel.name }}</h2>
                          <p class="text-caption font-mono mb-4 opacity-70" :class="textSecondaryClass">CNPJ: {{ panel.cnpj }}</p>
                        </div>

                        <div>
                            <v-btn
                                block
                                :variant="panel.restricted ? 'tonal' : (isLightMode ? 'flat' : 'outlined')"
                                :color="panel.restricted ? 'grey' : (isLightMode ? panel.btnLightColor : 'white')"
                                class="glass-btn text-capitalize font-weight-bold mb-2"
                                rounded="lg"
                                height="44"
                                :disabled="panel.restricted"
                                @click.stop="selectCompanyPanel(panel)"
                            >
                                {{ panel.restricted ? 'Não Autorizado' : 'Acessar Unidade' }}
                                <v-icon end size="small" class="ml-2">{{ panel.restricted ? 'mdi-lock' : 'mdi-arrow-right' }}</v-icon>
                            </v-btn>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

              </div>
            </div>

            <div class="nav-arrow right-arrow" @click.stop="rotateCarousel('next')" v-if="mappedCompanies.length > 1">
              <div class="large-arrow"><v-icon size="36" :color="isLightMode ? 'grey-darken-3' : 'white'">mdi-chevron-right</v-icon></div>
            </div>

          </div>
        </div>
      </v-fade-transition>

      <v-fade-transition>
        <div v-if="isNavigating" class="navigation-loading d-flex flex-column justify-center align-center">
          <div class="loading-backdrop" :class="isLightMode ? 'light-blur' : 'dark-blur'"></div>

          <div class="loading-center-content d-flex flex-column align-center">
             <v-img :src="activePanelData?.logo" width="140" height="140" contain class="breathing-logo mb-6 mx-auto"></v-img>

             <h2 class="text-h4 font-weight-black mb-8 text-center text-uppercase" :class="[textPrimaryClass, !isLightMode ? 'text-shadow-lg' : '']" style="letter-spacing: 2px;">
               {{ activePanelData?.trade_name || activePanelData?.name }}
             </h2>

             <div class="fancy-progress-track mx-auto" style="width: 320px; max-width: 80%;">
               <div class="fancy-progress-bar" :class="activePanelData?.progressGlow" :style="{ width: navigationProgress + '%' }">
                 <div class="shimmer-effect"></div>
               </div>
             </div>

             <div class="status-text-container mt-6 text-center">
                <span class="text-subtitle-2 font-mono typing-effect opacity-90" :class="textPrimaryClass">{{ currentLoadingMessage }}</span>
                <span class="cursor-blink" :class="textPrimaryClass">_</span>
             </div>

             <div class="text-center mt-10" style="height: 40px;">
                <v-btn v-if="showCancelButton" variant="outlined" :color="isLightMode ? 'grey-darken-3' : 'white'" class="font-weight-bold hover-bg-white border-white-50" rounded="pill" @click="cancelNavigation">
                    Cancelar Conexão
                </v-btn>
             </div>
          </div>
        </div>
      </v-fade-transition>

      <div class="hub-footer flex-shrink-0" :class="[headerBarClass, { 'hide-down': isNavigating }]" style="z-index: 50;">
          <v-container class="py-2">
            <v-row align="center" no-gutters class="flex-column-reverse flex-md-row">
              <v-col cols="12" md="4" class="d-flex align-center justify-center justify-md-start mt-2 mt-md-0">
                <span class="text-caption mr-3 hidden-sm-and-down" :class="textSecondaryClass">
                  © {{ new Date().getFullYear() }} MJProcess ERP
                </span>
                <v-divider vertical class="mx-2 hidden-sm-and-down border-opacity-25" length="12"></v-divider>
                <v-btn variant="text" size="x-small" :color="isLightMode ? 'green-darken-3' : 'green-lighten-2'" prepend-icon="mdi-whatsapp" href="https://wa.me/5515991876055" target="_blank" class="text-capitalize font-weight-bold">
                  Falar com Suporte
                </v-btn>
              </v-col>
              <v-col cols="12" md="4" class="d-flex align-center justify-center mb-2 mb-md-0">
                  <div class="user-badge d-flex align-center px-3 py-1 rounded-pill elevation-2" :class="isLightMode ? 'bg-white text-black' : 'bg-white-10'">
                    <v-avatar size="24" class="mr-2" :class="isLightMode ? 'border' : 'border-white-sm'">
                      <v-img :src="userStore.profile?.avatar_url || ''"></v-img>
                    </v-avatar>
                    <span class="text-caption font-weight-bold mr-2 text-truncate" :class="textPrimaryClass" style="max-width: 150px;">
                      {{ userFirstName }}
                    </span>
                    <v-tooltip text="Sair" location="top" content-class="custom-tooltip">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" icon size="x-small" variant="text" color="red-lighten-2" @click="handleLogout">
                          <v-icon>mdi-power</v-icon>
                        </v-btn>
                      </template>
                    </v-tooltip>
                  </div>
              </v-col>
              <v-col cols="12" md="4" class="d-flex align-center justify-center justify-md-end mb-2 mb-md-0">
                <v-menu location="top end" transition="scale-transition" :close-on-content-click="false">
                  <template v-slot:activator="{ props }">
                    <div class="d-flex align-center cursor-pointer hover-brightness" v-bind="props">
                      <v-icon size="x-small" :color="isLightMode ? 'green-darken-2' : 'green-accent-3'" class="mr-2 blink">mdi-circle-medium</v-icon>
                      <span class="text-caption font-weight-bold mr-4" :class="textPrimaryClass">Sistemas Online</span>
                    </div>
                  </template>
                  <v-list density="compact" class="elevation-10" rounded="lg" width="250" :class="menuCardClass">
                    <v-list-subheader class="text-uppercase font-weight-bold text-caption" :class="textSecondaryClass">Status dos Serviços</v-list-subheader>
                    <v-list-item density="compact" title="MJ Process (ERP)" subtitle="Online" :class="textPrimaryClass">
                      <template v-slot:prepend><v-icon color="blue" size="small">mdi-factory</v-icon></template>
                    </v-list-item>
                    <v-list-item density="compact" title="Servidores DB" subtitle="Estável" :class="textPrimaryClass">
                      <template v-slot:prepend><v-icon color="purple" size="small">mdi-database</v-icon></template>
                    </v-list-item>
                    <v-divider class="my-1 border-opacity-25"></v-divider>
                    <v-list-item density="compact">
                      <v-list-item-subtitle class="text-caption text-center opacity-70" :class="textSecondaryClass">
                        Atualizado: {{ new Date().toLocaleTimeString() }}
                      </v-list-item-subtitle>
                    </v-list-item>
                  </v-list>
                </v-menu>
              </v-col>
            </v-row>
          </v-container>
      </div>

      <v-snackbar v-model="showError" color="red-darken-4" location="top" elevation="10" rounded="pill" timeout="5000">
        <div class="d-flex align-center justify-center px-4">
          <v-icon class="mr-3">mdi-shield-lock-outline</v-icon>
          <span class="font-weight-bold">{{ errorMessage }}</span>
        </div>
      </v-snackbar>

      <AppMarketplaceModal v-model="marketplaceDialog" />

    </div>
  </v-theme-provider>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { useCompanyStore } from '@/stores/company';
import { useDisplay } from 'vuetify';
import AppMarketplaceModal from '@/components/AppMarketplaceModal.vue';

// Logos
import logoDark from '@/assets/logo.png';
import logoLight from '@/assets/logomjlm.png';
import logoCajuia from '@/assets/logocajuia.png';

// Imagens Locais (Carrossel)
import bg1 from '@/assets/1.jpg';
import bg2 from '@/assets/2.jpg';
import bg3 from '@/assets/3.jpg';
import bg4 from '@/assets/4.jpg';
import bg5 from '@/assets/5.jpg';

const router = useRouter();
const userStore = useUserStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const { mobile } = useDisplay();
const isMobile = computed(() => mobile.value);

// --- THEME LOGIC ---
const isLightMode = computed(() => themeStore.currentMode === 'light');
const isGlassMode = computed(() => themeStore.currentMode === 'glass');
const isDarkMode = computed(() => themeStore.currentMode === 'dark');
const currentThemeName = computed(() => isLightMode.value ? 'light' : 'dark');

const themeIcon = computed(() => {
  if (isLightMode.value) return 'mdi-white-balance-sunny';
  if (isGlassMode.value) return 'mdi-blur';
  return 'mdi-moon-waning-crescent';
});

function cycleTheme() {
  if (isLightMode.value) themeStore.setMode('dark');
  else if (isDarkMode.value) themeStore.setMode('glass');
  else themeStore.setMode('light');
}

const themeClass = computed(() => ({ 'theme-glass': isGlassMode.value, 'theme-light': isLightMode.value, 'theme-dark': isDarkMode.value }));
const headerBarClass = computed(() => isLightMode.value ? 'glass-bar-light' : 'glass-bar-dark');
const pillClass = computed(() => isLightMode.value ? 'glass-pill-light' : 'glass-pill-dark');
const menuCardClass = computed(() => isLightMode.value ? 'bg-white elevation-5' : 'glass-menu');
const textPrimaryClass = computed(() => isLightMode.value ? 'text-grey-darken-4' : 'text-white');
const textSecondaryClass = computed(() => isLightMode.value ? 'text-grey-darken-1' : 'text-grey-lighten-2');
const iconBtnClass = computed(() => isLightMode.value ? 'glass-icon-light' : 'glass-icon-dark');
const card3DClass = computed(() => isLightMode.value ? 'light-card-3d' : 'dark-card-3d');

const backgrounds = ref([bg1, bg2, bg3, bg4, bg5]);
const currentBgIndex = ref(0);
let bgInterval: any;

// --- DADOS DO USUÁRIO ---
const userFirstName = computed(() => {
  let rawName = userStore.profile?.full_name;

  if (!rawName) {
    const email = userStore.user?.email;
    return email ? email.split('@') : 'Usuário';
  }

  if (Array.isArray(rawName)) return rawName.join(' ');

  if (typeof rawName === 'string') {
    if (rawName.trim().startsWith('[')) {
      try {
        const parsed = JSON.parse(rawName);
        if (Array.isArray(parsed)) return parsed.join(' ');
      } catch (e) {
        return rawName.replace(/[\[\]"']/g, '').replace(/,/g, ' ');
      }
    }
    return rawName;
  }

  return 'Usuário';
});

const userRoleFormatted = computed(() => userStore.profile?.role?.substring(0, 8).toUpperCase() || 'ACESSO PADRÃO');
const customRoleName = ref('');

// --- MULTI-TENANT & CAROUSEL CONFIG ---
const loadingCompanies = ref(true);
const activeModuleIndex = ref(0);

const mappedCompanies = computed(() => {
    let comps = companyStore.availableCompanies;

    if (!comps || comps.length === 0) {
        comps = [
            { id: 'mock1', name: 'MJ Process', trade_name: 'MJ Process Indústria', cnpj: '00.000.000/0001-00' },
            { id: 'mock2', name: 'Cajuia Store', trade_name: 'Santos & Lopes Varejo', cnpj: '11.111.111/0001-11' }
        ];
    }

    const userCompanyId = userStore.profile?.company_id;
    const isAdmin = userStore.profile?.role === 'admin' || userStore.profile?.role === 'super_admin';

    return comps.map((c) => {
        const searchName = (c.name + ' ' + (c.trade_name || '')).toLowerCase();
        const isCajuia = searchName.includes('cajuia') || searchName.includes('santos') || searchName.includes('lopes');

        const isRestricted = userCompanyId && userCompanyId !== c.id && !isAdmin;

        return {
            ...c,
            isCajuia,
            restricted: isRestricted,
            // 👇 AQUI ESTÁ A CORREÇÃO: Prioriza a logo_url do banco!
            logo: c.logo_url || (isCajuia ? logoCajuia : (isLightMode.value ? logoLight : logoDark)),
            chipText: isCajuia ? 'VAREJO' : 'INDÚSTRIA',
            chipColor: isCajuia ? 'orange' : 'blue',
            glowClass: isCajuia ? 'orange-glow' : 'blue-glow',
            progressGlow: isCajuia ? 'glow-orange' : 'glow-blue',
            btnLightColor: isCajuia ? 'orange-darken-1' : 'blue-darken-1'
        };
    });
});

function mod(n: number, m: number) { return ((n % m) + m) % m; }

function rotateCarousel(direction: 'prev' | 'next') {
  const len = mappedCompanies.value.length;
  if (direction === 'next') activeModuleIndex.value = mod(activeModuleIndex.value + 1, len);
  else activeModuleIndex.value = mod(activeModuleIndex.value - 1, len);
}

function getCardClass(index: number) {
  const len = mappedCompanies.value.length;
  if (len === 1) return 'item-center';

  const diff = mod(index - activeModuleIndex.value, len);

  if (diff === 0) return 'item-center';
  if (diff === 1) return 'item-right';
  if (diff === len - 1) return 'item-left';

  return 'item-hidden';
}

function handleCardClick(panel: any, index: number) {
  if (index === activeModuleIndex.value) {
    selectCompanyPanel(panel);
  } else {
    const len = mappedCompanies.value.length;
    const diff = mod(index - activeModuleIndex.value, len);
    if (diff === 1) rotateCarousel('next');
    else rotateCarousel('prev');
  }
}

// --- NAVIGATION STATE ---
const activePanelId = ref<string | null>(null);
const activePanelData = ref<any>(null);
const isNavigating = ref(false);
const showCancelButton = ref(false);
const navigationProgress = ref(0);
const currentLoadingMessage = ref('');
const showError = ref(false);
const errorMessage = ref('');
const marketplaceDialog = ref(false);
const currentMessages = ref<string[]>([]);

const mjMessages = ['Verificando permissões de acesso...', 'Estabelecendo conexão segura...', 'Sincronizando dados da indústria...', 'Acesso Autorizado'];
const cajuiaMessages = ['Verificando permissões de loja...', 'Conectando ao sistema PDV...', 'Carregando módulo financeiro...', 'Acesso Autorizado'];

async function selectCompanyPanel(panel: any) {
  if (isNavigating.value || panel.restricted) return;

  activePanelId.value = panel.id;
  activePanelData.value = panel;
  isNavigating.value = true;
  showCancelButton.value = false;

  userStore.setModule('mj');

  if (panel.id && !panel.id.startsWith('mock')) {
      companyStore.setContext(panel.id);
  }

  currentMessages.value = panel.isCajuia ? cajuiaMessages : mjMessages;

  setTimeout(() => { showCancelButton.value = true; }, 3500);
  runNavigationSequence();
}

function cancelNavigation() {
    isNavigating.value = false;
    activePanelId.value = null;
    activePanelData.value = null;
    userStore.setModule(null);
}

function runNavigationSequence() {
  let routeName = 'Home';
  let step = 0;
  navigationProgress.value = 0;

  const interval = setInterval(() => {
    if (step >= currentMessages.value.length) {
      clearInterval(interval);
      router.push({ name: routeName }).catch(err => {
          isNavigating.value = false;
          activePanelId.value = null;
          errorMessage.value = 'Permissão Negada: Você não possui acesso à tela inicial do sistema.';
          showError.value = true;
      });
      return;
    }
    currentLoadingMessage.value = currentMessages.value[step];
    navigationProgress.value = ((step + 1) / currentMessages.value.length) * 100;
    step++;
  }, 900);
}

// --- UTILS (Weather, Ticker, Logout) ---
const systemNotices = ref(['SISTEMA ERP MULTI-TENANT ATIVO', 'AMBIENTE SEGURO 256-BITS', 'TODAS AS UNIDADES ONLINE']);
const currentTickerIndex = ref(0);
const weatherMenu = ref(false);
const weatherTemp = ref(0);
const weatherCode = ref(0);
const weatherHumidity = ref(0);
const weatherWind = ref(0);
const weatherFeelsLike = ref(0);
const predefinedCities = [{ name: 'São Paulo', lat: -23.55, lon: -46.63 }, { name: 'Tietê', lat: -23.10, lon: -47.71 }, { name: 'Capibaribe', lat: -7.94, lon: -36.20 }];
const selectedCity = ref(predefinedCities[1]);
let tickerInterval: any;
const currentDayOfWeek = computed(() => new Date().toLocaleDateString('pt-BR', { weekday: 'short' }));

const weatherIcon = computed(() => {
  if (weatherCode.value <= 1) return 'mdi-weather-sunny';
  if (weatherCode.value <= 3) return 'mdi-weather-partly-cloudy';
  return 'mdi-weather-cloudy';
});
const weatherCondition = computed(() => {
  if (weatherCode.value <= 1) return 'Céu Limpo';
  if (weatherCode.value <= 3) return 'Nublado';
  return 'Nublado';
});
const weatherIconColor = computed(() => weatherCode.value <= 1 ? 'amber-accent-3' : (isLightMode.value ? 'grey-darken-1' : 'grey-lighten-2'));

async function changeCity(city: any) { selectedCity.value = city; await fetchWeather(); }
async function fetchWeather() {
  try {
    const { lat, lon } = selectedCity.value;
    const res = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true&hourly=relativehumidity_2m,apparent_temperature,windspeed_10m`);
    const data = await res.json();
    if (data.current_weather) {
      weatherTemp.value = Math.round(data.current_weather.temperature);
      weatherCode.value = data.current_weather.weathercode;
      weatherWind.value = data.current_weather.windspeed;
      const hourIndex = new Date().getHours();
      if(data.hourly) { weatherHumidity.value = data.hourly.relativehumidity_2m[hourIndex] || 0; weatherFeelsLike.value = Math.round(data.hourly.apparent_temperature[hourIndex]) || weatherTemp.value; }
    }
  } catch (e) { console.error("Weather Error:", e); }
}
async function handleLogout() { await userStore.signOut(); router.push({ name: 'Login' }); }

onMounted(async () => {
  themeStore.initTheme();

  bgInterval = setInterval(() => {
      currentBgIndex.value = (currentBgIndex.value + 1) % backgrounds.value.length;
  }, 10000);

  tickerInterval = setInterval(() => { currentTickerIndex.value = (currentTickerIndex.value + 1) % systemNotices.value.length; }, 5000);
  fetchWeather();

  if (!userStore.profile) {
    try { await userStore.fetchSession(); } catch (e) {}
  }

  if (userStore.profile?.custom_role_id) {
      const { data } = await supabase.from('custom_roles').select('name').eq('id', userStore.profile.custom_role_id).single();
      if (data) customRoleName.value = data.name;
  }

  if (companyStore.availableCompanies.length === 0) {
      await companyStore.initialize();
  }

  setTimeout(() => { loadingCompanies.value = false; }, 300);
});

onUnmounted(() => {
    clearInterval(tickerInterval);
    clearInterval(bgInterval);
});
</script>

<style scoped lang="scss">
.hub-wrapper {
  position: relative; width: 100vw; height: 100vh; overflow: hidden;
  font-family: 'Roboto', sans-serif; transition: background-color 0.5s ease;
}

/* THEMES Base */
.theme-dark { background-color: #050505; }
.theme-light { background-color: #F3F4F6; }
.theme-glass { background-color: #000; }

/* ==========================================================
   CARROSSEL GLOBAL DE FUNDO
   ========================================================== */
.global-carousel-container {
    position: absolute; inset: 0; z-index: 0; pointer-events: none; overflow: hidden;
}
.bg-slide {
    position: absolute; inset: 0;
    background-size: cover; background-position: center;
    opacity: 0; transform: scale(1);
    transition: opacity 2s ease-in-out, transform 15s linear;
}
.bg-slide.active { opacity: 1; transform: scale(1.1); }
.bg-overlay { position: absolute; inset: 0; background: radial-gradient(circle at center, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0.85) 100%); backdrop-filter: blur(2px); z-index: 1; }
.theme-light .bg-overlay { background: radial-gradient(circle at center, rgba(255,255,255,0.7) 0%, rgba(255,255,255,0.95) 100%); backdrop-filter: blur(8px); }

/* ==========================================================
   MENSAGEM CENTRAL (BEM VINDO)
   ========================================================== */
.welcome-container {
    position: absolute; top: 10%; left: 50%; transform: translateX(-50%);
    z-index: 20;
    transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.4s ease;
    pointer-events: none;
}
.welcome-container.hide-up {
    transform: translate(-50%, -150%);
    opacity: 0;
}
.waving-hand { animation: wave 2.5s infinite; transform-origin: 70% 70%; }
@keyframes wave { 0% { transform: rotate(0deg); } 10% { transform: rotate(14deg); } 20% { transform: rotate(-8deg); } 30% { transform: rotate(14deg); } 40% { transform: rotate(-4deg); } 50% { transform: rotate(10deg); } 60% { transform: rotate(0deg); } 100% { transform: rotate(0deg); } }

/* ==========================================================
   CAMADA HEADER ABSOLUTA (Sobe ao Navegar)
   ========================================================== */
.absolute-header-layer {
    position: absolute;
    top: 0; left: 0; width: 100%;
    z-index: 50;
    pointer-events: none;
    transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.6s ease;
}
.absolute-header-layer.hide-up { transform: translateY(-100%); opacity: 0; }

.system-ticker, .left-controls, .weather-widget { pointer-events: auto; }
.system-ticker { height: 32px; backdrop-filter: blur(5px); }
.left-controls { position: absolute; top: 50px; left: 24px; }
.weather-widget { position: absolute; top: 50px; right: 24px; }

/* ==========================================================
   3D CAROUSEL DE CARTÕES
   ========================================================== */
.hub-main-content {
    height: 100%; display: flex; flex-direction: column; justify-content: center;
    position: relative; z-index: 10; margin-top: 50px;
    transition: opacity 0.4s ease, transform 0.4s ease;
}
.scene-3d-wrapper { flex-grow: 1; display: flex; align-items: center; justify-content: center; perspective: 1000px; position: relative; transition: all 0.5s ease; }
.scene-3d-wrapper.fade-out-scale { opacity: 0; transform: scale(0.9); pointer-events: none; }

.scene-3d { width: 100%; max-width: 900px; height: 420px; position: relative; transform-style: preserve-3d; display: flex; justify-content: center; align-items: center; }
.carousel-platform { width: 100%; height: 100%; position: relative; transform-style: preserve-3d; display: flex; justify-content: center; align-items: center; }

.card-3d-container {
  position: absolute; width: 340px; height: 420px;
  transition: transform 0.8s cubic-bezier(0.23, 1, 0.32, 1), opacity 0.5s ease, z-index 0s;
  pointer-events: auto !important;
  cursor: pointer;
}

/* POSIÇÕES DO CARROSSEL */
.item-center { transform: translate3d(0, 0, 100px); z-index: 20; opacity: 1; }
.item-left { transform: translate3d(-380px, 0, -100px) rotateY(25deg) scale(0.9); z-index: 10; opacity: 0.6; }
.item-right { transform: translate3d(380px, 0, -100px) rotateY(-25deg) scale(0.9); z-index: 10; opacity: 0.6; }
.item-hidden { transform: translate3d(0, 0, -300px) scale(0); opacity: 0; pointer-events: none !important; }

/* HOVER EFFECTS */
.item-center:hover { transform: translate3d(0, 0, 120px) scale(1.02); }
.item-left:hover { transform: translate3d(-400px, 0, -50px) rotateY(15deg) scale(0.95); opacity: 1; z-index: 15; }
.item-right:hover { transform: translate3d(400px, 0, -50px) rotateY(-15deg) scale(0.95); opacity: 1; z-index: 15; }

/* Flutuação Interna */
.card-3d-wrapper {
  width: 100%; height: 100%;
  animation: floatY 6s ease-in-out infinite;
  transform-style: preserve-3d;
  pointer-events: none;
}
.glass-card-3d { pointer-events: auto; }
.card-3d-container:hover .card-3d-wrapper { animation-play-state: paused; transform: translateY(0); }
@keyframes floatY { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }

/* SETAS DE NAVEGAÇÃO */
.nav-arrow { position: absolute; top: 50%; transform: translateY(-50%); z-index: 50; cursor: pointer; padding: 20px; }
.left-arrow { left: 5%; }
.right-arrow { right: 5%; }
.large-arrow {
  width: 56px; height: 56px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.3s ease; backdrop-filter: blur(10px);
  background: rgba(128,128,128,0.2);
}
.large-arrow:hover { transform: scale(1.2); background: rgba(128,128,128,0.4); }

/* --- CARD STYLES --- */
.glass-card-3d { width: 100%; height: 100%; border-radius: 24px; transition: all 0.3s ease; position: relative; overflow: hidden; transform-style: preserve-3d; display: flex; flex-direction: column; }
.dark-card-3d { background: rgba(20, 20, 25, 0.85); backdrop-filter: blur(25px); border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: 0 20px 50px rgba(0, 0, 0, 0.6); color: white; }
.light-card-3d { background: rgba(255, 255, 255, 0.9); backdrop-filter: blur(15px); border: 1px solid rgba(0, 0, 0, 0.05); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1); color: #333; }

.card-glow { position: absolute; inset: 0; opacity: 0; transition: opacity 0.5s ease; z-index: 0; pointer-events: none; }
.item-center:hover .card-glow { opacity: 0.3; }
.blue-glow { background: radial-gradient(circle at center, rgba(41, 121, 255, 0.8) 0%, transparent 70%); }
.orange-glow { background: radial-gradient(circle at center, rgba(255, 100, 0, 0.8) 0%, transparent 70%); }

/* === NOVO ESTILO PROFISSIONAL DE ACESSO RESTRITO === */
.restricted-card { filter: grayscale(100%); opacity: 0.8; cursor: not-allowed !important; }
.professional-lock-overlay { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; background: rgba(0, 0, 0, 0.6); backdrop-filter: blur(6px); z-index: 50; border-radius: inherit; color: white; }
.theme-light .professional-lock-overlay { background: rgba(255, 255, 255, 0.7); color: #424242; }
.lock-circle { width: 64px; height: 64px; border-radius: 50%; background: rgba(255, 255, 255, 0.1); display: flex; align-items: center; justify-content: center; margin-bottom: 16px; border: 1px solid rgba(255, 255, 255, 0.2); }
.theme-light .lock-circle { background: rgba(0, 0, 0, 0.05); border: 1px solid rgba(0, 0, 0, 0.1); }
.lh-1-4 { line-height: 1.4; }

/* ==========================================================
   TELA DE LOADING CENTRAL
   ========================================================== */
.navigation-loading { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 100; }
.loading-backdrop { position: absolute; inset: 0; z-index: -1; transition: background 0.5s ease; }
.dark-blur { background: rgba(0, 0, 0, 0.6); backdrop-filter: blur(15px); }
.light-blur { background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(20px); }

.fancy-progress-track { width: 100%; height: 6px; background: rgba(128,128,128,0.2); border-radius: 4px; overflow: hidden; position: relative; }
.fancy-progress-bar { height: 100%; border-radius: 4px; position: relative; transition: width 0.4s ease-out; }
.glow-blue { background: linear-gradient(90deg, #448AFF, #2962FF); box-shadow: 0 0 15px rgba(41, 121, 255, 0.8); }
.glow-orange { background: linear-gradient(90deg, #FF9800, #FF3D00); box-shadow: 0 0 15px rgba(255, 100, 0, 0.8); }
.shimmer-effect { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent); transform: skewX(-20deg) translateX(-150%); animation: shimmer 1.5s infinite linear; }
@keyframes shimmer { 0% { transform: skewX(-20deg) translateX(-150%); } 100% { transform: skewX(-20deg) translateX(150%); } }

/* ==========================================================
   UTILITIES E COMPONENTES AUXILIARES
   ========================================================== */
.hub-footer {
    width: 100%; z-index: 50; position: absolute; bottom: 0; left: 0;
    transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.6s ease;
}
.hub-footer.hide-down { transform: translateY(100%); opacity: 0; }

.glass-bar-dark { background: rgba(5,5,10,0.85); border-bottom: 1px solid rgba(255,255,255,0.05); }
.glass-bar-light { background: rgba(255,255,255,0.9); border-bottom: 1px solid rgba(0,0,0,0.05); }
.glass-bar-dark.hub-footer { border-bottom: none; border-top: 1px solid rgba(255,255,255,0.05); }
/* Correção do fundo preto no light mode */
.theme-light .hub-footer { background: #ffffff !important; color: #333 !important; border-top: 1px solid rgba(0,0,0,0.05); }

.glass-icon-btn { width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; }
.glass-icon-btn:hover { transform: scale(1.1); }
.glass-icon-dark { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.1); }
.glass-icon-light { background: rgba(255,255,255,0.8); border: 1px solid rgba(0,0,0,0.1); box-shadow: 0 2px 5px rgba(0,0,0,0.1); }

.glass-pill { transition: 0.2s; }
.glass-pill-dark { background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.1); }
.glass-pill-light { background: rgba(255,255,255,0.9); border: 1px solid rgba(0,0,0,0.05); color: #333; }
.glass-menu { background: rgba(30, 30, 35, 0.95) !important; backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.1); }

.bg-glass-header { background: rgba(255,255,255,0.05); }
.bg-white-10 { background: rgba(255,255,255,0.1); }
.border-white-sm { border: 1px solid rgba(255,255,255,0.3); }
.border-white-50 { border-color: rgba(255,255,255,0.5) !important; }
.text-shadow-lg { text-shadow: 0 4px 15px rgba(0,0,0,0.7); }
.drop-shadow-sm { filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3)); }
.drop-shadow-logo { filter: drop-shadow(0 5px 15px rgba(0,0,0,0.6)); }
.hover-bg-white:hover { background-color: rgba(255,255,255,0.1) !important; }
.transition-transform { transition: transform 0.5s ease; }

.breathing-logo { animation: breathe 3s ease-in-out infinite; filter: drop-shadow(0 0 25px rgba(255,255,255,0.3)); }
.cursor-blink { animation: blink 1s infinite; }
@keyframes breathe { 0%, 100% { transform: scale(1); opacity: 0.85; } 50% { transform: scale(1.05); opacity: 1; } }
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }

:global(.custom-tooltip) { background-color: #333 !important; color: #fff !important; font-size: 0.75rem !important; font-weight: 500 !important; opacity: 1 !important; }

/* ==========================================================
   A MÁGICA DA RESPONSIVIDADE MOBILE DO CARROSSEL
   ========================================================== */
@media (max-width: 768px) {
  /* Arruma os widgets espremidos no topo */
  .left-controls { top: 40px; left: 10px; }
  .weather-widget { top: 40px; right: 10px; }

  /* Deixa o pill do tempo menor para não cruzar a tela */
  .weather-pill { padding: 4px 10px !important; }
  .weather-pill .text-h5 { font-size: 1.2rem !important; }

  /* Mensagem de boas vindas desce para não bater no header */
  .welcome-container { top: 16%; width: 100%; padding: 0 16px; }
  .welcome-container h1 { font-size: 2rem !important; }

  /* Empurra o carrossel um pouco para baixo */
  .hub-main-content { margin-top: 80px; }

  /* MANTÉM O 3D, APENAS ENCOLHE TUDO PRA CABER NA TELA! */
  .scene-3d {
    transform: scale(0.75);
    transform-origin: center center;
  }

  /* Aproxima um pouco as cartas laterais para elas não vazarem da tela */
  .item-left { transform: translate3d(-180px, 0, -100px) rotateY(25deg) scale(0.85); opacity: 0.8; }
  .item-right { transform: translate3d(180px, 0, -100px) rotateY(-25deg) scale(0.85); opacity: 0.8; }

  .hub-footer { padding-bottom: env(safe-area-inset-bottom); }
}
</style>
