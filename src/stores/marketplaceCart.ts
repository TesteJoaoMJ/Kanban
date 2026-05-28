import { defineStore } from 'pinia';

export type CartItemType = 'psd' | 'fabric';

export interface CartItem {
  id: string; // ID único gerado para a linha do carrinho
  type: CartItemType;
  stampId: string;
  stampName: string;
  stampImageUrl: string;
  // Campos específicos para tecido
  fabricId?: string;
  fabricName?: string;
  quantity?: number; // em metros
  // Preços
  unitPrice: number;
  totalPrice: number;
}

export const useMarketplaceCartStore = defineStore('marketplaceCart', {
  state: () => ({
    items: [] as CartItem[],
    isOpen: false, // Controla a visibilidade do carrinho lateral (Drawer)
  }),

  getters: {
    cartTotal: (state) => {
      return state.items.reduce((total, item) => total + item.totalPrice, 0);
    },
    itemCount: (state) => {
      return state.items.length;
    },
    hasPsdItems: (state) => {
      return state.items.some(item => item.type === 'psd');
    },
    hasFabricItems: (state) => {
      return state.items.some(item => item.type === 'fabric');
    }
  },

  actions: {
    toggleCart() {
      this.isOpen = !this.isOpen;
    },

    openCart() {
      this.isOpen = true;
    },

    closeCart() {
      this.isOpen = false;
    },

    addPsdToCart(stamp: any, price: number) {
      // Verifica se o PSD desta estampa já está no carrinho
      const existingItem = this.items.find(i => i.stampId === stamp.id && i.type === 'psd');

      if (existingItem) {
        // Se já existe, apenas abre o carrinho (não faz sentido comprar 2 PSDs iguais)
        this.openCart();
        return;
      }

      this.items.push({
        id: `psd_${stamp.id}`,
        type: 'psd',
        stampId: stamp.id,
        stampName: stamp.name || 'Estampa Sem Nome',
        stampImageUrl: stamp.image_url || '',
        unitPrice: price,
        totalPrice: price
      });

      this.openCart();
    },

    addFabricToCart(stamp: any, fabric: any, quantity: number, unitPrice: number) {
      // O ID do carrinho para tecido junta o ID da estampa e do tecido
      const cartId = `fab_${stamp.id}_${fabric.id}`;
      const existingItem = this.items.find(i => i.id === cartId);

      if (existingItem) {
        // Se já tem essa estampa nesse tecido, soma a quantidade
        existingItem.quantity = (existingItem.quantity || 0) + quantity;
        existingItem.totalPrice = existingItem.quantity * existingItem.unitPrice;
      } else {
        // Se não tem, adiciona nova linha
        this.items.push({
          id: cartId,
          type: 'fabric',
          stampId: stamp.id,
          stampName: stamp.name || 'Estampa Sem Nome',
          stampImageUrl: stamp.image_url || '',
          fabricId: fabric.id,
          fabricName: fabric.name || 'Tecido Desconhecido',
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: quantity * unitPrice
        });
      }

      this.openCart();
    },

    removeItem(id: string) {
      this.items = this.items.filter(item => item.id !== id);
    },

    clearCart() {
      this.items = [];
    }
  },
  // Opcional: Se você estiver usando o pinia-plugin-persistedstate, pode descomentar a linha abaixo
  // para que o carrinho não suma quando o usuário der F5.
  // persist: true,
});
