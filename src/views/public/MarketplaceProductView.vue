<template>
  <div class="product-page-container bg-background min-h-screen pb-12">
    <v-container class="pt-6 pb-2">
      <v-btn variant="text" prepend-icon="mdi-arrow-left" @click="router.push('/marketplace')" class="text-none px-0">
        Voltar para o Acervo
      </v-btn>
    </v-container>

    <v-container v-if="isLoading" class="d-flex justify-center align-center" style="min-height: 50vh;">
      <v-progress-circular indeterminate color="primary" size="64"></v-progress-circular>
    </v-container>

    <v-container v-else-if="stamp">
      <v-row>
        <v-col cols="12" md="6">
          <v-card elevation="0" rounded="xl" class="overflow-hidden bg-surface border">
            <v-img
              :src="stamp.image_url || '/placeholder.png'"
              :alt="stamp.name"
              aspect-ratio="1"
              cover
              class="bg-grey-lighten-4"
            >
              <template v-slot:placeholder>
                <div class="d-flex align-center justify-center fill-height">
                  <v-progress-circular indeterminate color="grey-lighten-2"></v-progress-circular>
                </div>
              </template>
            </v-img>
          </v-card>
        </v-col>

        <v-col cols="12" md="6" class="pl-md-8 pt-6 pt-md-0">
          <div class="text-overline text-primary mb-1">Estampa Exclusiva</div>
          <h1 class="text-h3 font-weight-bold mb-2">{{ stamp.name || 'Estampa Sem Título' }}</h1>
          <p class="text-body-1 text-grey-darken-1 mb-6">
            {{ stamp.description || 'Nenhuma descrição fornecida para esta estampa.' }}
          </p>

          <v-divider class="mb-6"></v-divider>

          <h2 class="text-h6 font-weight-bold mb-4">Como você deseja comprar esta estampa?</h2>

          <v-row class="mb-6">
            <v-col cols="12" sm="6" v-if="allowPsdSales">
              <v-card
                @click="selectMode('psd')"
                :color="purchaseMode === 'psd' ? 'primary' : 'surface'"
                :variant="purchaseMode === 'psd' ? 'flat' : 'outlined'"
                class="h-100 cursor-pointer transition-swing"
                rounded="lg"
              >
                <div class="pa-5 d-flex flex-column align-center text-center">
                  <v-icon size="48" :color="purchaseMode === 'psd' ? 'white' : 'primary'" class="mb-3">
                    mdi-file-download-outline
                  </v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold mb-1" :class="purchaseMode === 'psd' ? 'text-white' : ''">
                    Arte Digital (PSD)
                  </h3>
                  <div class="text-caption" :class="purchaseMode === 'psd' ? 'text-white' : 'text-grey-darken-1'">
                    Baixe o arquivo original aberto para uso próprio.
                  </div>
                </div>
              </v-card>
            </v-col>

            <v-col cols="12" :sm="allowPsdSales ? 6 : 12">
              <v-card
                @click="selectMode('fabric')"
                :color="purchaseMode === 'fabric' ? 'primary' : 'surface'"
                :variant="purchaseMode === 'fabric' ? 'flat' : 'outlined'"
                class="h-100 cursor-pointer transition-swing"
                rounded="lg"
              >
                <div class="pa-5 d-flex flex-column align-center text-center">
                  <v-icon size="48" :color="purchaseMode === 'fabric' ? 'white' : 'primary'" class="mb-3">
                    mdi-texture
                  </v-icon>
                  <h3 class="text-subtitle-1 font-weight-bold mb-1" :class="purchaseMode === 'fabric' ? 'text-white' : ''">
                    Estampar em Tecido
                  </h3>
                  <div class="text-caption" :class="purchaseMode === 'fabric' ? 'text-white' : 'text-grey-darken-1'">
                    Receba o tecido físico já impresso com esta arte.
                  </div>
                </div>
              </v-card>
            </v-col>
          </v-row>

          <v-expand-transition>
            <div v-if="purchaseMode === 'psd' && allowPsdSales" class="bg-surface-light pa-5 rounded-lg border mb-6">
              <div class="d-flex align-center mb-3">
                <v-icon color="success" class="mr-2">mdi-check-circle</v-icon>
                <span class="text-body-1">Arquivo em Alta Resolução</span>
              </div>
              <div class="d-flex align-center mb-4">
                <v-icon color="success" class="mr-2">mdi-check-circle</v-icon>
                <span class="text-body-1">Raport (Encaixe) Perfeito configurado</span>
              </div>

              <div class="d-flex justify-space-between align-center mt-6">
                <span class="text-h6 text-grey-darken-1">Valor Único:</span>
                <span class="text-h4 font-weight-bold text-primary">{{ formatCurrency(psdPrice) }}</span>
              </div>
            </div>
          </v-expand-transition>

          <v-expand-transition>
            <div v-if="purchaseMode === 'fabric'" class="bg-surface-light pa-5 rounded-lg border mb-6">
              <h3 class="text-subtitle-1 font-weight-bold mb-3">1. Selecione o Tecido:</h3>
              <v-select
                v-model="selectedFabric"
                :items="availableFabrics"
                item-title="name"
                return-object
                variant="outlined"
                bg-color="surface"
                placeholder="Clique para escolher um tecido..."
                hide-details
                class="mb-5"
                size="large"
              >
                <template v-slot:item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template v-slot:append>
                      <span class="font-weight-bold">{{ formatCurrency(item.raw.price) }}/m</span>
                    </template>
                  </v-list-item>
                </template>
              </v-select>

              <template v-if="selectedFabric">
                <h3 class="text-subtitle-1 font-weight-bold mb-3">2. Quantidade (em metros):</h3>
                <div class="d-flex align-center mb-5" style="max-width: 250px;">
                  <v-btn
                    icon="mdi-minus"
                    variant="tonal"
                    color="primary"
                    @click="decrementQuantity"
                    :disabled="fabricQuantity <= 1"
                  ></v-btn>
                  <v-text-field
                    v-model.number="fabricQuantity"
                    type="number"
                    variant="outlined"
                    hide-details
                    density="compact"
                    class="mx-3 text-center text-h6"
                    min="1"
                  ></v-text-field>
                  <v-btn
                    icon="mdi-plus"
                    variant="tonal"
                    color="primary"
                    @click="incrementQuantity"
                  ></v-btn>
                </div>

                <v-divider class="my-4"></v-divider>

                <div class="d-flex justify-space-between align-end">
                  <div>
                    <div class="text-caption text-grey-darken-1">Subtotal ({{ fabricQuantity }}m x {{ formatCurrency(selectedFabric.price) }})</div>
                    <div class="text-caption text-grey-darken-1">+ Custo da Estampa: Incluído</div>
                  </div>
                  <div class="text-right">
                    <div class="text-h4 font-weight-bold text-primary">{{ formatCurrency(fabricTotalPrice) }}</div>
                  </div>
                </div>
              </template>
            </div>
          </v-expand-transition>

          <v-btn
            color="primary"
            size="x-large"
            block
            variant="elevated"
            height="64"
            class="text-h6 font-weight-bold"
            :disabled="purchaseMode === 'fabric' && !selectedFabric"
            @click="handleAddToCart"
          >
            <v-icon left class="mr-2">mdi-cart-plus</v-icon>
            Adicionar ao Carrinho
          </v-btn>
        </v-col>
      </v-row>
    </v-container>

    <v-container v-else class="text-center py-12">
      <v-icon size="64" color="error" class="mb-4">mdi-alert-circle-outline</v-icon>
      <h2 class="text-h5 mb-2">Estampa não encontrada</h2>
      <p class="text-grey mb-6">A estampa que você está procurando não existe ou foi removida.</p>
      <v-btn color="primary" @click="router.push('/marketplace')">Voltar ao Acervo</v-btn>
    </v-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMarketplaceCartStore } from '@/stores/marketplaceCart';
import { supabase } from '@/api/supabase';

const route = useRoute();
const router = useRouter();
const cartStore = useMarketplaceCartStore();

// Estados da Estampa
const stamp = ref<any>(null);
const isLoading = ref(true);

// Controle de Compra
type PurchaseMode = 'psd' | 'fabric';
const purchaseMode = ref<PurchaseMode>('psd');

// Variável que controla a exibição da venda de PSD baseada no painel
const allowPsdSales = ref(true);

// Preço Fixo do PSD (Pode vir do banco depois)
const psdPrice = ref(150.00);

// Estados do Tecido
const availableFabrics = ref<any[]>([]);
const selectedFabric = ref<any>(null);
const fabricQuantity = ref(1);

// Busca os dados da estampa ao carregar a página
onMounted(async () => {
  const stampId = route.params.id as string;
  if (!stampId) {
    isLoading.value = false;
    return;
  }

  try {
    // 0. Busca a configuração global do Storefront para verificar a venda de PSD
    const { data: settingsData } = await supabase
      .from('storefront_settings')
      .select('allow_psd_sales')
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (settingsData && settingsData.allow_psd_sales === false) {
      allowPsdSales.value = false;
      purchaseMode.value = 'fabric'; // Força o modo para tecido se o PSD estiver oculto
    }

    // 1. Busca a Estampa
    const { data: stampData, error: stampError } = await supabase
      .from('stamps')
      .select('*')
      .eq('id', stampId)
      .single();

    if (stampError) throw stampError;
    stamp.value = stampData;

    // Se a estampa tiver preço de PSD no banco, atualiza:
    if (stampData.price) psdPrice.value = stampData.price;

    // 2. Busca os Tecidos Ativos do Estoque (Visíveis no NewOrder)
    // Ajuste o nome da tabela 'stock' para a sua tabela real de estoque
    const { data: fabricData, error: fabricError } = await supabase
      .from('stock')
      .select('id, name, price') // Busca id, nome e preço de venda
      .eq('category', 'tecido') // Ajuste o filtro conforme o seu banco
      .eq('active', true);

    if (fabricError) {
      console.warn("Erro ao buscar tecidos, usando lista de fallback", fabricError);
      // Fallback visual de teste caso a query falhe
      availableFabrics.value = [
        { id: 'f1', name: 'Crepe Pasqualle', price: 25.90 },
        { id: 'f2', name: 'Tricoline 100% Algodão', price: 32.50 },
        { id: 'f3', name: 'Viscolinho', price: 45.00 }
      ];
    } else if (fabricData) {
      availableFabrics.value = fabricData;
    }

  } catch (error) {
    console.error("Erro ao carregar estampa:", error);
  } finally {
    isLoading.value = false;
  }
});

// Funções de UI
const selectMode = (mode: PurchaseMode) => {
  purchaseMode.value = mode;
};

const incrementQuantity = () => {
  fabricQuantity.value++;
};

const decrementQuantity = () => {
  if (fabricQuantity.value > 1) {
    fabricQuantity.value--;
  }
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value);
};

// Computed Properties
const fabricTotalPrice = computed(() => {
  if (!selectedFabric.value) return 0;
  return selectedFabric.value.price * fabricQuantity.value;
});

// Ação de Compra
const handleAddToCart = () => {
  if (purchaseMode.value === 'psd') {
    cartStore.addPsdToCart(stamp.value, psdPrice.value);
  } else if (purchaseMode.value === 'fabric' && selectedFabric.value) {
    cartStore.addFabricToCart(
      stamp.value,
      selectedFabric.value,
      fabricQuantity.value,
      selectedFabric.value.price
    );
  }
};
</script>

<style scoped>
.transition-swing {
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.5, 1);
}
.product-page-container {
  /* Impede que o drawer de carrinho empurre o layout incorretamente dependendo do setup global */
  position: relative;
}
</style>
