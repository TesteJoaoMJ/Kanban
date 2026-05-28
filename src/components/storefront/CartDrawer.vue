<template>
  <v-navigation-drawer
    v-model="cartStore.isOpen"
    location="right"
    temporary
    width="400"
    class="cart-drawer"
  >
    <v-toolbar color="surface" elevation="1">
      <v-toolbar-title class="text-h6 font-weight-bold">
        Meu Carrinho
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn icon @click="cartStore.closeCart">
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-toolbar>

    <div v-if="cartStore.items.length === 0" class="empty-cart-container d-flex flex-column align-center justify-center h-100 pa-6 text-center">
      <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-cart-outline</v-icon>
      <h3 class="text-h6 text-grey-darken-1 mb-2">Seu carrinho está vazio</h3>
      <p class="text-body-2 text-grey">Adicione estampas ou tecidos para continuar sua compra.</p>
      <v-btn color="primary" variant="flat" class="mt-6" @click="cartStore.closeCart">
        Continuar Explorando
      </v-btn>
    </div>

    <v-list v-else class="pa-4 flex-grow-1 overflow-y-auto" style="height: calc(100% - 140px);">
      <v-slide-y-transition group>
        <v-card
          v-for="item in cartStore.items"
          :key="item.id"
          variant="outlined"
          class="mb-3 item-card"
        >
          <div class="d-flex pa-3">
            <v-avatar rounded size="70" class="elevation-1 mr-3">
              <v-img :src="item.stampImageUrl || '/placeholder.png'" cover></v-img>
            </v-avatar>

            <div class="flex-grow-1 overflow-hidden">
              <div class="d-flex justify-space-between align-start">
                <div class="text-subtitle-2 font-weight-bold text-truncate pr-2">
                  {{ item.stampName }}
                </div>
                <v-btn
                  icon="mdi-trash-can-outline"
                  size="small"
                  color="error"
                  variant="text"
                  density="comfortable"
                  @click="cartStore.removeItem(item.id)"
                ></v-btn>
              </div>

              <div v-if="item.type === 'psd'" class="text-caption text-primary d-flex align-center mt-1">
                <v-icon size="small" class="mr-1">mdi-file-download-outline</v-icon>
                Arquivo PSD Digital
              </div>

              <div v-if="item.type === 'fabric'" class="text-caption text-grey-darken-1 mt-1">
                <div class="d-flex align-center">
                  <v-icon size="small" class="mr-1">mdi-texture</v-icon>
                  {{ item.fabricName }}
                </div>
                <div class="mt-1">
                  Qtd: <strong>{{ item.quantity }}m</strong> x {{ formatCurrency(item.unitPrice) }}/m
                </div>
              </div>

              <div class="text-subtitle-1 font-weight-bold mt-2 text-right">
                {{ formatCurrency(item.totalPrice) }}
              </div>
            </div>
          </div>
        </v-card>
      </v-slide-y-transition>
    </v-list>

    <template v-if="cartStore.items.length > 0">
      <v-divider></v-divider>
      <div class="pa-4 bg-surface-light checkout-footer">
        <div class="d-flex justify-space-between align-center mb-4">
          <span class="text-subtitle-1 text-grey-darken-1">Subtotal:</span>
          <span class="text-h5 font-weight-bold text-primary">{{ formatCurrency(cartStore.cartTotal) }}</span>
        </div>

        <v-btn
          color="primary"
          size="x-large"
          block
          variant="elevated"
          @click="goToCheckout"
        >
          Finalizar Compra
          <v-icon right class="ml-2">mdi-arrow-right</v-icon>
        </v-btn>
      </div>
    </template>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
import { useMarketplaceCartStore } from '@/stores/marketplaceCart';

const router = useRouter();
const cartStore = useMarketplaceCartStore();

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value);
};

const goToCheckout = () => {
  cartStore.closeCart(); // Fecha o drawer antes de mudar de rota
  router.push('/marketplace/checkout');
};
</script>

<style scoped>
.cart-drawer {
  display: flex;
  flex-direction: column;
}

.item-card {
  transition: all 0.2s ease;
}

.item-card:hover {
  border-color: rgba(var(--v-theme-primary), 0.5);
  background-color: rgba(var(--v-theme-primary), 0.02);
}

.checkout-footer {
  position: absolute;
  bottom: 0;
  width: 100%;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
}
</style>
