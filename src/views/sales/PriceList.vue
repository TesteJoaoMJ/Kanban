<template>
  <div
    class="price-list-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="isLightMode ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="!isLightMode" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">

      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="isLightMode ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Vendas</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Tabela de Preços</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <v-icon size="24" :color="isLightMode ? 'primary' : 'white'">mdi-currency-usd</v-icon>
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                Consulta de Preços
             </div>
          </div>
        </div>

        <div class="d-flex align-center flex-grow-1 flex-md-grow-0" style="max-width: 400px; width: 100%;">
          <div class="search-wrap rounded-sm border-thin d-flex align-center flex-grow-1" :class="isLightMode ? 'search-light' : 'search-dark'">
            <v-icon :color="isLightMode ? 'primary' : 'white-70'">mdi-magnify</v-icon>
            <input
              v-model="search"
              type="text"
              placeholder="Buscar produto ou composição..."
              class="clean-input flex-grow-1 font-weight-bold pl-2"
            />
            <v-icon v-if="search" size="small" class="cursor-pointer opacity-50 ml-2" @click="search = ''">mdi-close</v-icon>
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6">
        <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
          <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
        </div>

        <div v-else-if="filteredProducts.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
          <v-icon size="48" color="grey-lighten-1">mdi-database-search-outline</v-icon>
          <span class="text-body-2 font-weight-medium text-grey">Nenhum produto encontrado.</span>
        </div>

        <v-row v-else>
          <v-col
            v-for="item in filteredProducts"
            :key="item.id"
            cols="12"
            sm="6"
            md="4"
            lg="3"
          >
            <v-card
                class="price-card rounded-sm"
                :class="[
                    `unit--${item.unit}`,
                    isLightMode ? 'price-card-light' : 'price-card-dark'
                ]"
                variant="flat"
            >
              <v-card-text class="d-flex flex-column h-100">
                <div class="mb-3">
                  <h3 class="text-subtitle-1 font-weight-black lh-1 mb-1" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.name }}</h3>
                  <p class="text-caption font-weight-medium" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey-lighten-1'">{{ item.composition }}</p>
                </div>

                <div class="info-grid mb-4">
                  <div class="info-item">
                    <span class="info-label" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">Gramatura</span>
                    <span class="info-value" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.grammage || 'N/A' }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">Largura</span>
                    <span class="info-value" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.width_length || 'N/A' }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">Rolo</span>
                    <span class="info-value" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.rolo || 'N/A' }}</span>
                  </div>
                  <div class="info-item" v-if="item.unit === 'kg'">
                    <span class="info-label" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">Rendimento</span>
                    <span class="info-value" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">{{ item.rendimento || 'N/A' }}</span>
                  </div>
                  <div class="info-item">
                    <span class="info-label" :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">Unidade</span>
                    <v-chip
                      :color="item.unit === 'kg' ? 'purple-darken-1' : 'teal-darken-1'"
                      size="x-small"
                      variant="flat"
                      class="mt-1 font-weight-bold uppercase rounded-sm"
                    >
                      {{ item.unit }}
                    </v-chip>
                  </div>
                </div>

                <v-spacer></v-spacer>

                <div v-if="canViewSE" class="price-region mt-2" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2 border' : 'bg-white-05 border-white-05 border'">
                  <h4 class="region-title" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'">SUDESTE</h4>
                  <div class="price-values">
                    <div class="price-type" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        <span :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">À Vista</span>
                        {{ formatCurrency(item.price_se_cash) }}
                    </div>
                    <div class="price-type" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        <span :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">A Prazo</span>
                        {{ formatCurrency(item.price_se_term) }}
                    </div>
                  </div>
                </div>

                <div v-if="canViewNE" class="price-region mt-2" :class="isLightMode ? 'bg-grey-lighten-4 border-grey-lighten-2 border' : 'bg-white-05 border-white-05 border'">
                  <h4 class="region-title" :class="isLightMode ? 'text-grey-darken-2' : 'text-grey-lighten-1'">NORDESTE</h4>
                  <div class="price-values">
                    <div class="price-type" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        <span :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">À Vista</span>
                        {{ formatCurrency(item.price_ne_cash) }}
                    </div>
                    <div class="price-type" :class="isLightMode ? 'text-grey-darken-4' : 'text-white'">
                        <span :class="isLightMode ? 'text-grey-darken-1' : 'text-grey'">A Prazo</span>
                        {{ formatCurrency(item.price_ne_term) }}
                    </div>
                  </div>
                </div>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';

type Product = {
  id: string;
  name: string;
  composition: string;
  grammage: string;
  unit: 'metro' | 'kg';
  rendimento?: string | null;
  width_length?: string | null;
  rolo?: string | null;
  price_se_cash: number;
  price_se_term: number;
  price_ne_cash: number;
  price_ne_term: number;
};

const userStore = useUserStore();
const themeStore = useThemeStore();
const isLightMode = computed(() => themeStore.currentMode === 'light');

const loading = ref(true);
const search = ref('');
const products = ref<Product[]>([]);

const canViewSE = computed(() => userStore.profile?.allowed_regions?.includes('SE') || userStore.isAdmin);
const canViewNE = computed(() => userStore.profile?.allowed_regions?.includes('NE') || userStore.isAdmin);

const filteredProducts = computed(() => {
  if (!search.value) return products.value;
  const query = search.value.toLowerCase();
  return products.value.filter(p =>
    p.name.toLowerCase().includes(query) ||
    p.composition?.toLowerCase().includes(query)
  );
});

const fetchPrices = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase.from('price_list').select('*').order('name');
    if (error) throw error;
    products.value = data || [];
  } catch (err: any) {
    console.error(`Erro ao buscar tabela de preços: ${err.message}`);
  } finally {
    loading.value = false;
  }
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value || 0);
};

onMounted(fetchPrices);
</script>

<style scoped lang="scss">
/* Layout Geral */
.price-list-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }
.z-10 { position: relative; z-index: 10; }

.search-wrap { height: 40px; padding: 0 12px; display: flex; align-items: center; flex: 1; }
.search-light { background: #f4f6f8; border: 1px solid rgba(0,0,0,0.08); }
.search-light:focus-within { border-color: #3f51b5; box-shadow: 0 0 0 2px rgba(63,81,181,0.1); }
.search-dark { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.10); }
.search-dark:focus-within { border-color: rgba(255,255,255,0.3); background: rgba(255,255,255,0.08); }
.clean-input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; color: inherit; }

/* Price Cards */
.price-card {
  border-left: 5px solid;
  transition: all 0.2s ease-in-out;
  height: 100%;
  display: flex;
  flex-direction: column;

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 20px rgba(0,0,0,0.15) !important;
  }

  &.unit--kg { border-left-color: #7E57C2; }
  &.unit--metro { border-left-color: #00897B; }
}

.price-card-dark {
  background-color: rgba(30, 30, 35, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-left-width: 5px;
}

.price-card-light {
  background-color: #ffffff;
  border: 1px solid rgba(0,0,0,0.08);
  border-left-width: 5px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
  gap: 12px;
}

.info-item { display: flex; flex-direction: column; }
.info-label { font-size: 0.65rem; text-transform: uppercase; margin-bottom: 2px; font-weight: 900; }
.info-value { font-size: 0.85rem; font-weight: 700; }

.price-region { padding: 8px 12px; border-radius: 4px; }
.region-title { font-size: 0.65rem; font-weight: 900; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 4px; }

.price-values { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
.price-type { font-size: 0.95rem; font-weight: 900; font-family: monospace; span { font-size: 0.65rem; font-weight: 800; display: block; text-transform: uppercase; font-family: sans-serif; }}

/* Utils */
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 3px; }
.border-white-05 { border-color: rgba(255,255,255,0.05) !important; }
.bg-white-05 { background-color: rgba(255,255,255,0.05) !important; }
.lh-1 { line-height: 1.1; }
.uppercase { text-transform: uppercase; }
</style>
