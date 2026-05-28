import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';

export interface MarketplaceUser {
  id: string;
  name: string;
  email: string;
  phone?: string;
  avatarUrl?: string;
  document?: string; // CPF ou CNPJ
  address?: {
    street: string;
    number: string;
    complement?: string;
    neighborhood: string;
    city: string;
    state: string;
    zipCode: string;
  };
}

export interface PurchaseHistoryItem {
  id: string;
  date: string;
  total: number;
  status: 'pending' | 'paid' | 'production' | 'shipped' | 'delivered';
  paymentMethod: 'pix' | 'whatsapp_negotiation';
  items: Array<{
    type: 'psd' | 'fabric';
    stampId: string;
    stampName: string;
    fabricId?: string;
    fabricName?: string;
    quantity?: number;
    price: number;
  }>;
  downloadUrl?: string; // Liberado apenas se status for 'paid' e tipo for 'psd'
}

export const useMarketplaceUserStore = defineStore('marketplaceUser', {
  state: () => ({
    user: null as MarketplaceUser | null,
    wishlist: [] as string[], // Array com os IDs das estampas favoritadas
    purchases: [] as PurchaseHistoryItem[],
    isLoading: false,
  }),

  getters: {
    isAuthenticated: (state) => !!state.user,

    userInitials: (state) => {
      if (!state.user || !state.user.name) return '';
      const names = state.user.name.split(' ');
      if (names.length >= 2) {
        return `${names[0][0]}${names[names.length - 1][0]}`.toUpperCase();
      }
      return names[0].substring(0, 2).toUpperCase();
    },
  },

  actions: {
    // Define o usuário logado (será chamado após autenticação no Supabase)
    async setUser(userData: MarketplaceUser) {
      this.user = userData;
      // Carrega os favoritos do banco de dados ao fazer login
      await this.loadWishlist();
    },

    // Limpa os dados ao sair
    logout() {
      this.user = null;
      this.wishlist = [];
      this.purchases = [];
    },

    // Atualiza dados cadastrais
    updateProfile(updates: Partial<MarketplaceUser>) {
      if (this.user) {
        this.user = { ...this.user, ...updates };
      }
    },

    // Atualiza apenas a foto de perfil
    updateAvatar(url: string) {
      if (this.user) {
        this.user.avatarUrl = url;
      }
    },

    // --- GERENCIAMENTO DE WISHLIST ---

    async loadWishlist() {
      if (!this.user) return;
      try {
        const { data, error } = await supabase
          .from('public_leads')
          .select('wishlist')
          .eq('email', this.user.email)
          .single();

        if (error) throw error;

        if (data && data.wishlist) {
          this.wishlist = data.wishlist;
        }
      } catch (error) {
        console.error('Erro ao carregar a wishlist:', error);
      }
    },

    async toggleWishlist(stampId: string) {
      const index = this.wishlist.indexOf(stampId);

      // Atualização otimista na UI
      if (index === -1) {
        this.wishlist.push(stampId); // Adiciona se não existir
      } else {
        this.wishlist.splice(index, 1); // Remove se já existir
      }

      // Sincroniza com o banco de dados imediatamente se o usuário estiver logado
      if (this.user) {
        try {
          const { error } = await supabase
            .from('public_leads')
            .update({ wishlist: this.wishlist })
            .eq('email', this.user.email);

          if (error) throw error;
        } catch (error) {
          console.error('Erro ao sincronizar wishlist com o banco:', error);

          // Reverte a alteração local em caso de erro (Rollback)
          if (index === -1) {
            this.wishlist.pop();
          } else {
            this.wishlist.splice(index, 0, stampId);
          }
        }
      }
    },

    isInWishlist(stampId: string): boolean {
      return this.wishlist.includes(stampId);
    },

    // --- HISTÓRICO DE COMPRAS ---

    addPurchase(purchase: PurchaseHistoryItem) {
      // Insere a nova compra no início do array
      this.purchases.unshift(purchase);
    },

    setPurchases(purchases: PurchaseHistoryItem[]) {
      this.purchases = purchases;
    }
  }
});
