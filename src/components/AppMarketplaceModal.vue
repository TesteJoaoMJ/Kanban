<template>
  <v-dialog
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    fullscreen
    transition="dialog-bottom-transition"
    scrollable
  >
    <v-card :class="['marketplace-container', themeClasses.bg]">

      <div class="custom-topbar d-flex align-center justify-space-between px-6 py-3 z-index-20" :class="themeClasses.blurHeader">
        <div class="d-flex align-center">
          <v-btn
            icon
            density="compact"
            variant="text"
            :color="textClasses.secondary"
            @click="handleBack"
            class="mr-2"
          >
            <v-icon size="small">{{ navigationStack.length > 0 ? 'mdi-arrow-left' : 'mdi-close' }}</v-icon>
          </v-btn>

          <v-breadcrumbs :items="breadcrumbs" density="compact" class="pa-0">
            <template v-slot:divider>
              <v-icon icon="mdi-chevron-right" size="x-small" color="grey"></v-icon>
            </template>
            <template v-slot:title="{ item }">
              <span class="text-caption font-weight-bold" :class="item.disabled ? textClasses.secondary : textClasses.primary">
                {{ item.title }}
              </span>
            </template>
          </v-breadcrumbs>
        </div>

        <div class="d-flex align-center gap-3">
          <div class="text-right hidden-xs">
            <div class="text-caption font-weight-bold lh-1" :class="textClasses.primary">{{ userStore.profile?.full_name || 'Visitante' }}</div>
            <div class="text-caption lh-1 opacity-70" :class="textClasses.secondary" style="font-size: 10px;">{{ userStore.profile?.role?.toUpperCase() || 'GUEST' }}</div>
          </div>
          <v-avatar
            size="32"
            class="cursor-pointer transition-swing hover-scale border"
            :image="userStore.profile?.avatar_url || ''"
            color="grey-darken-3"
          >
            <span v-if="!userStore.profile?.avatar_url" class="text-caption font-weight-bold white--text">
              {{ userStore.profile?.full_name?.charAt(0) || 'U' }}
            </span>
          </v-avatar>
        </div>
      </div>

      <div class="d-flex fill-height overflow-hidden position-relative">

        <div v-if="!isSuperAdmin" class="restricted-overlay z-index-10 d-flex flex-column align-center justify-center text-center">
          <div class="floating-icon mb-6">
            <div class="icon-circle">
              <v-icon size="64" color="white">mdi-rocket-launch-outline</v-icon>
            </div>
            <div class="pulse-rings"></div>
          </div>
          <h1 class="text-h3 font-weight-black text-white mb-2 tracking-wide text-shadow fade-in-up delay-1">EM BREVE</h1>
          <p class="text-h6 text-grey-lighten-3 font-weight-light max-width-600 mb-8 fade-in-up delay-2">
            Estamos preparando um ecossistema completo de integrações para impulsionar o seu negócio.
          </p>
          <div class="glass-badge px-4 py-2 rounded-pill fade-in-up delay-3">
            <v-icon size="small" color="amber" class="mr-2">mdi-lock-outline</v-icon>
            <span class="text-caption font-weight-bold text-white">ACESSO EXCLUSIVO SUPER ADMIN</span>
          </div>
        </div>

        <div class="d-flex fill-height w-100 transition-all" :class="{ 'blur-restricted': !isSuperAdmin }">

          <div class="store-sidebar d-flex flex-column py-4 border-r hidden-sm-and-down" :class="themeClasses.sidebar">
            <div class="px-4 mb-6">
              <div class="d-flex align-center gap-2 text-primary">
                <v-icon size="small">mdi-storefront-outline</v-icon>
                <span class="font-weight-black text-caption tracking-wide">MJ STORE</span>
              </div>
            </div>

            <v-list density="compact" nav class="bg-transparent px-2">
              <v-list-item
                v-for="item in menuItems"
                :key="item.id"
                :value="item.id"
                :active="activeView === item.id"
                @click="navigateTo(item.id)"
                rounded="lg"
                class="mb-1 nav-item"
                active-color="primary"
              >
                <template v-slot:prepend>
                  <v-icon size="small" :icon="item.icon" class="opacity-80"></v-icon>
                </template>
                <v-list-item-title class="text-caption font-weight-bold">{{ item.label }}</v-list-item-title>
              </v-list-item>
            </v-list>

            <v-spacer></v-spacer>

            <div class="px-4 pb-4">
              <v-card variant="outlined" class="pa-3 rounded-lg text-center" :class="themeClasses.borderSubtle">
                <div class="text-caption font-weight-bold mb-1" :class="textClasses.primary">Atualizações</div>
                <div class="text-caption text-grey mb-2" style="font-size: 10px;">Sistema atualizado</div>
                <v-btn block size="x-small" variant="tonal" color="success">Check</v-btn>
              </v-card>
            </div>
          </div>

          <div class="store-content flex-grow-1 overflow-y-auto custom-scrollbar position-relative pa-0" ref="scrollContainer">
            <v-fade-transition mode="out-in">

              <div v-if="activeView === 'home' && !selectedApp" key="home" class="view-container">
                <div class="hero-section position-relative mb-6">
                  <v-img
                    src="https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?q=80&w=2070&auto=format&fit=crop"
                    cover
                    height="320"
                    class="align-end"
                    gradient="to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.8)"
                  >
                    <div class="px-8 pb-10 w-100 d-flex align-end justify-space-between">
                      <div>
                        <v-chip size="x-small" color="white" label class="font-weight-black text-black mb-2">DESTAQUE</v-chip>
                        <h1 class="text-h3 font-weight-black text-white mb-1 text-shadow">MJ Analytics Pro</h1>
                        <p class="text-body-2 text-grey-lighten-3 font-weight-regular max-width-500 text-shadow">
                          Inteligência artificial integrada para decisões mais rápidas.
                        </p>
                      </div>
                      <v-btn color="white" variant="flat" class="text-black font-weight-bold px-6" size="small">Ver Detalhes</v-btn>
                    </div>
                  </v-img>
                </div>

                <v-container fluid class="px-8 mt-n8 position-relative z-index-2">
                  <v-card :class="['search-bar-card pa-1 rounded-pill d-flex align-center mb-8 elevation-4', themeClasses.card]">
                    <v-icon class="ml-4 mr-2 opacity-50" size="small">mdi-magnify</v-icon>
                    <input
                      v-model="search"
                      type="text"
                      placeholder="Buscar apps..."
                      class="flex-grow-1 bg-transparent border-none outline-none text-caption font-weight-medium"
                      :class="textClasses.primary"
                      style="height: 40px;"
                    />
                    <v-divider vertical class="my-2 mx-2 opacity-20"></v-divider>
                    <div class="d-flex align-center px-1 gap-1 overflow-x-auto hide-scrollbar" style="max-width: 50%;">
                      <v-chip
                        v-for="cat in appCategories"
                        :key="cat.id"
                        size="x-small"
                        :color="selectedCategory === cat.id ? 'primary' : (isLightMode ? 'grey-lighten-3' : 'grey-darken-3')"
                        :variant="selectedCategory === cat.id ? 'flat' : 'tonal'"
                        class="font-weight-bold cursor-pointer transition-swing"
                        @click="selectedCategory = cat.id"
                      >
                        {{ cat.label }}
                      </v-chip>
                    </div>
                  </v-card>

                  <div v-for="(section, sIndex) in filteredSections" :key="sIndex" class="mb-8">
                    <div class="d-flex align-center justify-space-between mb-3">
                      <h3 class="text-subtitle-1 font-weight-bold" :class="textClasses.primary">{{ section.title }}</h3>
                      <v-btn variant="text" size="x-small" density="compact" color="primary" append-icon="mdi-chevron-right">Ver tudo</v-btn>
                    </div>
                    <v-row dense>
                      <v-col cols="12" sm="6" md="4" lg="3" xl="2" v-for="app in section.apps" :key="app.id">
                        <v-hover v-slot="{ isHovering, props }">
                          <v-card
                            v-bind="props"
                            class="app-card rounded-lg fill-height d-flex flex-column transition-swing cursor-pointer"
                            :class="[themeClasses.card, { 'hover-lift': isHovering }]"
                            elevation="0"
                            @click="openAppDetails(app)"
                            variant="outlined"
                            style="border-width: 1px !important; border-color: rgba(128,128,128,0.1) !important;"
                          >
                            <div class="card-header pa-3 d-flex align-start gap-3">
                              <v-avatar size="48" :color="app.bgHex || 'grey-darken-3'" rounded="lg" class="elevation-1">
                                <v-icon color="white" size="24">{{ app.icon }}</v-icon>
                              </v-avatar>
                              <div class="overflow-hidden">
                                <div class="text-subtitle-2 font-weight-bold text-truncate lh-1 mb-1" :class="textClasses.primary">{{ app.name }}</div>
                                <div class="text-caption text-grey text-truncate" style="font-size: 10px;">{{ app.developer }}</div>
                              </div>
                            </div>
                            <div class="px-3 pb-2 flex-grow-1">
                              <div class="d-flex align-center gap-1 mb-2">
                                <v-chip size="x-small" density="compact" label :color="app.categoryColor" variant="tonal" class="font-weight-bold" style="height: 16px; font-size: 9px;">{{ app.category }}</v-chip>
                                <v-spacer></v-spacer>
                                <v-icon size="x-small" color="amber" class="mr-1">mdi-star</v-icon>
                                <span class="text-caption font-weight-bold" :class="textClasses.primary" style="font-size: 10px;">{{ app.rating }}</span>
                              </div>
                              <p class="text-caption text-grey line-clamp-2" style="font-size: 11px; line-height: 1.3;">{{ app.shortDescription }}</p>
                            </div>
                            <div class="pa-3 pt-0 mt-auto">
                               <v-btn
                                 block
                                 size="x-small"
                                 :variant="app.installed ? 'tonal' : 'flat'"
                                 :color="app.installed ? 'grey' : 'primary'"
                                 class="font-weight-bold"
                               >
                                 {{ app.installed ? 'Instalado' : 'Obter' }}
                               </v-btn>
                            </div>
                          </v-card>
                        </v-hover>
                      </v-col>
                    </v-row>
                  </div>
                </v-container>
              </div>

              <div v-else-if="selectedApp" key="details" class="details-view position-relative">
                <div class="detail-backdrop" :style="{ backgroundImage: `url(${selectedApp.banner || 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop'})` }"></div>

                <v-container maxWidth="1200" class="pt-12 position-relative z-index-2">

                  <div class="d-flex flex-column flex-md-row align-end gap-8 mb-10 px-4">
                    <v-card width="180" height="180" :color="selectedApp.bgHex" elevation="12" class="rounded-xl d-flex align-center justify-center flex-shrink-0 card-icon-3d mb-n4 position-relative z-index-3">
                       <v-icon size="90" color="white">{{ selectedApp.icon }}</v-icon>
                    </v-card>

                    <div class="flex-grow-1 text-white pb-2">
                      <h1 class="text-h3 font-weight-black mb-1 text-shadow tracking-tight">{{ selectedApp.name }}</h1>
                      <div class="d-flex align-center gap-4 mb-5 text-shadow">
                        <span class="text-subtitle-1 font-weight-medium opacity-90">{{ selectedApp.developer }}</span>
                        <span class="opacity-50">•</span>
                        <v-chip size="small" color="white" variant="outlined" class="font-weight-bold">{{ selectedApp.category }}</v-chip>
                        <span class="opacity-50">•</span>
                        <div class="d-flex align-center">
                          <v-rating :model-value="selectedApp.rating" color="amber" density="compact" size="small" readonly></v-rating>
                          <span class="text-body-2 font-weight-bold ml-2 opacity-90">{{ selectedApp.rating }} ({{ selectedApp.reviewsCount }} avaliações)</span>
                        </div>
                      </div>

                      <div class="d-flex align-center gap-4">
                        <v-btn
                          color="blue-accent-3"
                          height="48"
                          width="200"
                          class="font-weight-bold text-body-1"
                          elevation="4"
                          :loading="installing"
                          @click="installApp"
                        >
                          {{ selectedApp.installed ? 'ABRIR' : 'OBTER' }}
                        </v-btn>
                        <div class="text-caption font-weight-medium opacity-80" v-if="!selectedApp.installed">Gratuito • Oferece compras no app</div>
                        <v-spacer></v-spacer>
                        <v-btn variant="tonal" color="white" height="48" width="48" icon class="rounded-lg backdrop-blur"><v-icon>mdi-heart-outline</v-icon></v-btn>
                        <v-btn variant="tonal" color="white" height="48" width="48" icon class="rounded-lg backdrop-blur"><v-icon>mdi-share-variant</v-icon></v-btn>
                      </div>
                    </div>
                  </div>

                  <v-card :class="['rounded-xl overflow-hidden min-h-screen-50', themeClasses.card]" elevation="0" border>
                    <v-tabs v-model="detailTab" density="comfortable" :color="isLightMode ? 'primary' : 'white'" bg-color="transparent" class="border-b px-6">
                      <v-tab value="overview" class="text-body-2 font-weight-bold text-capitalize">Visão Geral</v-tab>
                      <v-tab value="reviews" class="text-body-2 font-weight-bold text-capitalize">Avaliações</v-tab>
                      <v-tab value="details" class="text-body-2 font-weight-bold text-capitalize">Detalhes Técnicos</v-tab>
                    </v-tabs>

                    <v-window v-model="detailTab" class="pa-8">
                      <v-window-item value="overview">
                        <v-row>
                          <v-col cols="12" md="8">
                            <div class="mb-8">
                              <h3 class="text-h6 font-weight-bold mb-4" :class="textClasses.primary">Galeria</h3>
                              <div class="d-flex gap-4 overflow-x-auto pb-4 custom-scrollbar snap-x">
                                <v-card v-for="n in 3" :key="n" width="340" height="200" class="flex-shrink-0 rounded-lg snap-start cursor-pointer hover-scale" :color="isLightMode ? 'grey-lighten-4' : 'grey-darken-4'" flat>
                                  <v-img src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=800&q=80" cover height="100%" class="opacity-80 hover-opacity-100 transition-swing"></v-img>
                                </v-card>
                              </div>
                            </div>

                            <h3 class="text-h6 font-weight-bold mb-3" :class="textClasses.primary">Descrição</h3>
                            <p class="text-body-1 line-height-relaxed mb-8 text-justify opacity-90" :class="textClasses.secondary" style="white-space: pre-line;">
                              {{ selectedApp.fullDescription }}
                            </p>

                            <v-card variant="tonal" :color="isLightMode ? 'blue-grey-lighten-5' : 'grey-darken-3'" class="pa-6 rounded-lg mb-6">
                              <div class="d-flex align-center mb-3">
                                <v-icon color="primary" class="mr-2">mdi-star-four-points</v-icon>
                                <h3 class="text-subtitle-1 font-weight-bold" :class="textClasses.primary">Novidades da versão {{ selectedApp.version }}</h3>
                              </div>
                              <ul class="pl-6 text-body-2" :class="textClasses.secondary">
                                <li v-for="news in selectedApp.whatsNew" :key="news" class="mb-1">{{ news }}</li>
                              </ul>
                            </v-card>
                          </v-col>

                          <v-col cols="12" md="4">
                            <div class="pa-5 rounded-xl border" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-4'">
                              <div class="text-caption font-weight-black mb-6 letter-spacing-2" :class="textClasses.secondary">INFORMAÇÕES</div>

                              <div class="info-grid">
                                <div class="mb-4">
                                  <div class="text-caption text-grey mb-1">Desenvolvedor</div>
                                  <div class="text-body-2 font-weight-bold text-primary cursor-pointer">{{ selectedApp.developer }}</div>
                                </div>
                                <div class="mb-4">
                                  <div class="text-caption text-grey mb-1">Categoria</div>
                                  <div class="text-body-2 font-weight-medium" :class="textClasses.primary">{{ selectedApp.category }}</div>
                                </div>
                                <div class="mb-4">
                                  <div class="text-caption text-grey mb-1">Tamanho</div>
                                  <div class="text-body-2 font-weight-medium" :class="textClasses.primary">{{ selectedApp.size }}</div>
                                </div>
                                <div class="mb-4">
                                  <div class="text-caption text-grey mb-1">Última Atualização</div>
                                  <div class="text-body-2 font-weight-medium" :class="textClasses.primary">{{ selectedApp.lastUpdate }}</div>
                                </div>
                              </div>

                              <v-divider class="my-4"></v-divider>

                              <div class="text-caption font-weight-bold mb-3" :class="textClasses.primary">Permissões Necessárias</div>
                              <div class="d-flex flex-wrap gap-2">
                                <v-chip v-for="perm in selectedApp.permissions" :key="perm" size="small" :class="themeClasses.chip" class="font-weight-medium">
                                  <v-icon start size="x-small">mdi-check</v-icon> {{ perm }}
                                </v-chip>
                              </div>
                            </div>
                          </v-col>
                        </v-row>
                      </v-window-item>

                      <v-window-item value="reviews">
                        <v-row>
                          <v-col cols="12" md="4">
                            <div class="text-center pa-6 rounded-lg border" :class="isLightMode ? 'bg-grey-lighten-5' : 'bg-grey-darken-4'">
                              <div class="text-h2 font-weight-black mb-1" :class="textClasses.primary">{{ selectedApp.rating }}</div>
                              <v-rating :model-value="selectedApp.rating" color="amber" density="compact" readonly half-increments class="mb-2"></v-rating>
                              <div class="text-caption text-grey">{{ selectedApp.reviewsCount }} avaliações</div>

                              <div class="mt-6 w-100 px-4">
                                <div v-for="n in 5" :key="n" class="d-flex align-center mb-1">
                                  <span class="text-caption font-weight-bold mr-2 w-10 text-right" :class="textClasses.secondary">{{ 6-n }}</span>
                                  <v-progress-linear :model-value="Math.random() * 100" color="amber" height="6" rounded class="flex-grow-1"></v-progress-linear>
                                </div>
                              </div>
                            </div>
                          </v-col>
                          <v-col cols="12" md="8">
                            <div class="d-flex justify-space-between align-center mb-6">
                              <h3 class="text-h6 font-weight-bold" :class="textClasses.primary">Comentários dos Usuários</h3>
                              <v-btn variant="outlined" color="primary" size="small">Escrever Avaliação</v-btn>
                            </div>

                            <div v-for="review in selectedApp.reviewsList" :key="review.id" class="mb-6 pb-6 border-b">
                              <div class="d-flex align-center mb-2">
                                <v-avatar size="36" color="grey-lighten-2" class="mr-3 font-weight-bold text-grey-darken-3">{{ review.user.charAt(0) }}</v-avatar>
                                <div>
                                  <div class="text-body-2 font-weight-bold" :class="textClasses.primary">{{ review.user }}</div>
                                  <div class="d-flex align-center">
                                    <v-rating :model-value="review.rating" color="amber" density="compact" size="x-small" readonly></v-rating>
                                    <span class="text-caption text-grey ml-2">{{ review.date }}</span>
                                  </div>
                                </div>
                              </div>
                              <p class="text-body-2 mt-2" :class="textClasses.secondary">{{ review.comment }}</p>
                            </div>
                          </v-col>
                        </v-row>
                      </v-window-item>

                      <v-window-item value="details">
                        <v-table density="comfortable" class="bg-transparent">
                          <tbody>
                            <tr v-for="(value, key) in selectedApp.technicalDetails" :key="key">
                              <td class="text-caption font-weight-bold text-uppercase opacity-70 py-3" :class="textClasses.secondary" width="200">{{ key }}</td>
                              <td class="text-body-2 font-weight-medium py-3" :class="textClasses.primary">{{ value }}</td>
                            </tr>
                          </tbody>
                        </v-table>

                        <div class="mt-8">
                          <h3 class="text-subtitle-1 font-weight-bold mb-4" :class="textClasses.primary">Links Úteis</h3>
                          <div class="d-flex gap-4">
                            <v-btn variant="text" color="primary" prepend-icon="mdi-web">Site do Desenvolvedor</v-btn>
                            <v-btn variant="text" color="primary" prepend-icon="mdi-email-outline">Suporte Técnico</v-btn>
                            <v-btn variant="text" color="primary" prepend-icon="mdi-shield-check-outline">Política de Privacidade</v-btn>
                          </div>
                        </div>
                      </v-window-item>
                    </v-window>
                  </v-card>
                </v-container>
              </div>

              <div v-else-if="activeView === 'profile'" key="profile" class="pa-8">
                <v-container maxWidth="800">
                  <div class="text-center mt-10">
                    <v-avatar size="120" color="grey-darken-3" class="mb-4 text-h3 font-weight-bold">
                      {{ userStore.profile?.full_name?.charAt(0) }}
                    </v-avatar>
                    <h2 class="text-h4 font-weight-bold" :class="textClasses.primary">{{ userStore.profile?.full_name }}</h2>
                    <p class="text-body-1 text-grey">{{ userStore.user?.email }}</p>
                  </div>
                </v-container>
              </div>

            </v-fade-transition>
          </div>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/themeStore';
import { storeToRefs } from 'pinia';

const props = defineProps<{ modelValue: boolean }>();
const emit = defineEmits(['update:modelValue']);
const userStore = useUserStore();
const themeStore = useThemeStore();
const { profile } = storeToRefs(userStore);

// --- PERMISSIONS ---
const isSuperAdmin = computed(() => {
  return profile.value?.role === 'super_admin' || profile.value?.role === 'admin'; // Adjusted for demo
});

// --- STATE ---
const search = ref('');
const activeView = ref('home');
const selectedCategory = ref('all');
const selectedApp = ref<any>(null);
const detailTab = ref('overview');
const installing = ref(false);
const navigationStack = ref<string[]>([]);

// --- THEME HELPERS ---
const isLightMode = computed(() => themeStore.currentMode === 'light');
const isGlassMode = computed(() => themeStore.currentMode === 'glass');

const themeClasses = computed(() => {
  if (isLightMode.value) {
    return {
      bg: 'bg-grey-lighten-5',
      sidebar: 'bg-white',
      blurHeader: 'bg-white-blur',
      card: 'bg-white border-subtle',
      borderSubtle: 'border-grey-lighten-2',
      chip: 'bg-grey-lighten-3'
    };
  } else {
    return {
      bg: 'bg-dark-workspace',
      sidebar: isGlassMode.value ? 'bg-glass-sidebar' : 'bg-grey-darken-4',
      blurHeader: 'bg-dark-blur',
      card: 'bg-surface-dark border-dark',
      borderSubtle: 'border-grey-darken-3',
      chip: 'bg-grey-darken-3'
    };
  }
});

const textClasses = computed(() => ({
  primary: isLightMode.value ? 'text-grey-darken-4' : 'text-white',
  secondary: isLightMode.value ? 'text-grey-darken-1' : 'text-grey-lighten-1',
}));

const breadcrumbs = computed(() => {
  const crumbs = [{ title: 'Loja', disabled: false, href: 'home' }];
  if (activeView.value === 'profile') crumbs.push({ title: 'Perfil', disabled: true, href: 'profile' });
  if (selectedApp.value) {
    crumbs.push({ title: selectedApp.value.category, disabled: false, href: 'cat' });
    crumbs.push({ title: selectedApp.value.name, disabled: true, href: '#' });
  }
  return crumbs;
});

// --- MOCK DATA ---
const menuItems = [
  { id: 'home', label: 'Início', icon: 'mdi-home-variant-outline' },
  { id: 'apps', label: 'Aplicativos', icon: 'mdi-view-grid-outline' },
  { id: 'games', label: 'Jogos & Gamificação', icon: 'mdi-controller' },
  { id: 'profile', label: 'Biblioteca', icon: 'mdi-bookshelf' }
];

const appCategories = [
  { id: 'all', label: 'Tudo', icon: 'mdi-apps' },
  { id: 'productivity', label: 'Produtividade', icon: 'mdi-lightning-bolt' },
  { id: 'finance', label: 'Financeiro', icon: 'mdi-finance' },
  { id: 'marketing', label: 'Marketing', icon: 'mdi-bullhorn' },
  { id: 'logistics', label: 'Logística', icon: 'mdi-truck-fast' },
];

const allApps = [
  {
    id: 1,
    name: 'WhatsApp Business API',
    developer: 'Meta Platforms',
    category: 'Marketing',
    categoryColor: 'green',
    rating: 4.8,
    reviewsCount: '1.2k',
    icon: 'mdi-whatsapp',
    bgHex: '#4CAF50',
    shortDescription: 'Conecte-se com seus clientes via WhatsApp Oficial.',
    fullDescription: 'A solução definitiva para atendimento ao cliente. Centralize mensagens, crie chatbots e automatize vendas.\n\nCom a API oficial, você garante estabilidade e acesso a recursos avançados como templates de mensagens, botões interativos e métricas de envio.',
    installed: true,
    size: '12 MB',
    lastUpdate: '10/01/2025',
    version: '2.4.0',
    permissions: ['Contatos', 'Mensagens', 'Notificações'],
    whatsNew: ['Suporte a catálogos de produtos.', 'Novas métricas de engajamento.', 'Correção de estabilidade.'],
    reviewsList: [
      { id: 1, user: 'Carlos Silva', rating: 5, date: '12/01/2025', comment: 'Excelente integração, facilitou muito o atendimento.' },
      { id: 2, user: 'Ana Souza', rating: 4, date: '05/01/2025', comment: 'Muito bom, mas poderia ter mais opções de bots.' }
    ],
    technicalDetails: {
      'Versão': '2.4.0',
      'Data de Atualização': '10 de Janeiro de 2025',
      'Tamanho do Download': '12.4 MB',
      'Idiomas': 'Português, Inglês, Espanhol',
      'Licença': 'Enterprise'
    }
  },
  {
    id: 4,
    name: 'Bling ERP Connector',
    developer: 'Bling Sistemas',
    category: 'Financeiro',
    categoryColor: 'teal',
    rating: 4.6,
    reviewsCount: '3k',
    icon: 'mdi-cube-outline',
    bgHex: '#009688',
    shortDescription: 'Emissão de NFe e controle financeiro integrado.',
    fullDescription: 'Sincronize suas vendas do MJProcess diretamente com o Bling para emissão instantânea de notas fiscais e controle de contas a receber.',
    installed: true,
    size: '8 MB',
    lastUpdate: '15/12/2024',
    version: '3.1.2',
    permissions: ['Financeiro', 'Vendas'],
    whatsNew: ['Correção na emissão de NFe de devolução.', 'Dashboard financeiro aprimorado.'],
    reviewsList: [],
    technicalDetails: { 'Versão': '3.1.2', 'Tamanho': '8 MB' }
  },
  {
    id: 5,
    name: 'Google Drive Sync',
    developer: 'Google LLC',
    category: 'Produtividade',
    categoryColor: 'blue',
    rating: 4.5,
    reviewsCount: '850',
    icon: 'mdi-google-drive',
    bgHex: '#2196F3',
    shortDescription: 'Backup automático de arquivos na nuvem.',
    fullDescription: 'Mantenha seus arquivos seguros e acessíveis. Sincronização automática de anexos de pedidos e relatórios gerados pelo sistema.',
    installed: false,
    size: '5 MB',
    lastUpdate: '20/12/2024',
    version: '1.5.0',
    permissions: ['Arquivos', 'Internet'],
    whatsNew: ['Upload em segundo plano.', 'Pastas compartilhadas.'],
    reviewsList: [],
    technicalDetails: { 'Versão': '1.5.0', 'Tamanho': '5 MB' }
  },
  // ... more mock apps
];

const filteredSections = computed(() => {
  const sections = [];
  let list = allApps;

  if (selectedCategory.value !== 'all') {
    list = allApps.filter(a => a.category.toLowerCase() === appCategories.find(c => c.id === selectedCategory.value)?.label.toLowerCase());
  }

  if (search.value) {
    const s = search.value.toLowerCase();
    list = list.filter(a => a.name.toLowerCase().includes(s));
    sections.push({ title: 'Resultados', apps: list });
  } else {
    sections.push({ title: 'Essenciais para Gestão', apps: list });
    if (selectedCategory.value === 'all') sections.push({ title: 'Sugestões Populares', apps: list.slice(0, 2) });
  }
  return sections;
});

// --- METHODS ---
function navigateTo(viewId: string) {
  if (viewId === activeView.value) return;
  navigationStack.value.push(activeView.value);
  activeView.value = viewId;
  selectedApp.value = null;
}

function openAppDetails(app: any) {
  if (!isSuperAdmin.value) return;
  navigationStack.value.push(activeView.value);
  selectedApp.value = app;
}

function handleBack() {
  if (selectedApp.value) {
    selectedApp.value = null;
    return;
  }
  if (navigationStack.value.length > 0) {
    activeView.value = navigationStack.value.pop() || 'home';
  } else {
    emit('update:modelValue', false);
  }
}

function installApp() {
  installing.value = true;
  setTimeout(() => {
    installing.value = false;
    if (selectedApp.value) selectedApp.value.installed = !selectedApp.value.installed;
  }, 1500);
}

watch(() => props.modelValue, (val) => {
  if (val) {
    navigationStack.value = [];
    activeView.value = 'home';
    selectedApp.value = null;
  }
});
</script>

<style scoped lang="scss">
.marketplace-container {
  font-family: 'Segoe UI', 'Roboto', Helvetica, Arial, sans-serif;
  display: flex; flex-direction: column;
}

/* THEME UTILS */
.bg-dark-workspace { background-color: #121212; color: white; }
.bg-surface-dark { background-color: #1E1E1E; }
.bg-glass-sidebar {
  background-color: rgba(20, 20, 25, 0.85);
  backdrop-filter: blur(20px);
  border-right: 1px solid rgba(255,255,255,0.08) !important;
}
.bg-white-blur { background: rgba(255,255,255,0.95); backdrop-filter: blur(12px); border-bottom: 1px solid rgba(0,0,0,0.05); }
.bg-dark-blur { background: rgba(18, 18, 18, 0.95); backdrop-filter: blur(12px); border-bottom: 1px solid rgba(255,255,255,0.05); }

.border-subtle { border: 1px solid rgba(0,0,0,0.06) !important; }
.border-dark { border: 1px solid rgba(255,255,255,0.08) !important; }

/* OVERLAY RESTRICTION */
.restricted-overlay {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0,0,0,0.4); z-index: 50;
  pointer-events: auto;
}
.blur-restricted { filter: blur(10px); pointer-events: none; transform: scale(0.98); opacity: 0.5; }

/* FLOATING ANIMATION */
.floating-icon { animation: float 4s ease-in-out infinite; }
.icon-circle { width: 120px; height: 120px; border-radius: 50%; background: linear-gradient(135deg, #FF6F00 0%, #FF8F00 100%); display: flex; align-items: center; justify-content: center; box-shadow: 0 0 30px rgba(255, 143, 0, 0.6); position: relative; z-index: 2; }
.pulse-rings { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 100%; height: 100%; border-radius: 50%; border: 2px solid rgba(255, 143, 0, 0.5); animation: ripple 2s infinite; z-index: 1; }
@keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
@keyframes ripple { 0% { width: 100%; height: 100%; opacity: 1; } 100% { width: 200%; height: 200%; opacity: 0; } }
.glass-badge { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2); }
.fade-in-up { animation: fadeInUp 0.8s ease-out forwards; opacity: 0; }
.delay-1 { animation-delay: 0.2s; }
.delay-2 { animation-delay: 0.4s; }
.delay-3 { animation-delay: 0.6s; }
@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

/* LAYOUT */
.store-sidebar { width: 240px; min-width: 240px; }
.nav-item { font-weight: 500; transition: background 0.2s; }
.custom-topbar { height: 60px; position: relative; }

/* CARDS */
.app-card { transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); }
.hover-lift:hover { transform: translateY(-4px); box-shadow: 0 10px 30px rgba(0,0,0,0.12) !important; border-color: transparent !important; }
.card-icon-3d { box-shadow: 0 25px 50px rgba(0,0,0,0.5) !important; transform: rotate(-3deg); transition: 0.5s ease; }
.card-icon-3d:hover { transform: rotate(0deg) scale(1.05); }

/* DETAIL PAGE */
.detail-backdrop { position: absolute; top: 0; left: 0; width: 100%; height: 500px; background-size: cover; background-position: center; mask-image: linear-gradient(to bottom, black 20%, transparent 100%); -webkit-mask-image: linear-gradient(to bottom, black 20%, transparent 100%); opacity: 0.7; z-index: 0; }
.text-shadow { text-shadow: 0 4px 12px rgba(0,0,0,0.6); }
.backdrop-blur { backdrop-filter: blur(10px); background: rgba(255,255,255,0.1) !important; }
.snap-x { scroll-snap-type: x mandatory; }
.snap-start { scroll-snap-align: start; }
.min-h-screen-50 { min-height: 50vh; }
.letter-spacing-2 { letter-spacing: 2px; }

/* SCROLLBAR */
.custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,0.5); }

/* Mobile */
@media (max-width: 960px) {
  .store-sidebar { display: none !important; }
  .detail-backdrop { height: 350px; }
  .card-icon-3d { width: 120px !important; height: 120px !important; }
}
</style>
