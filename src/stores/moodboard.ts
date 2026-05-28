// ============================================================================
// ETAPA 6A: MOTOR DE ESTADO COMERCIAL (Carrinho / Moodboard)
// Ficheiro: src/stores/moodboard.ts
// ============================================================================

import { defineStore } from 'pinia';
import { ref, computed, watch } from 'vue';
import type { CatalogStamp, CatalogMockup } from '@/types/builder';

export interface MoodboardItem {
  id: string; // ID único gerado no momento de adição
  stamp: CatalogStamp;
  selected_mockup: CatalogMockup | null;
  notes: string;
  added_at: number;
}

export const useMoodboardStore = defineStore('moodboard', () => {
  // Estado
  const items = ref<MoodboardItem[]>([]);
  const isOpen = ref(false); // Controla a gaveta lateral
  const isLoading = ref(false);

  // Recuperar estado inicial do LocalStorage (Persistência para visitantes)
  const savedState = localStorage.getItem('mj_moodboard_draft');
  if (savedState) {
    try {
      items.value = JSON.parse(savedState);
    } catch (e) {
      console.error('Falha ao restaurar moodboard', e);
    }
  }

  // Auto-save: sempre que os items mudarem, guarda no LocalStorage
  watch(items, (newItems) => {
    localStorage.setItem('mj_moodboard_draft', JSON.stringify(newItems));
  }, { deep: true });

  // Getters (Computados)
  const totalItems = computed(() => items.value.length);
  const isEmpty = computed(() => items.value.length === 0);

  // Actions
  function openDrawer() {
    isOpen.value = true;
  }

  function closeDrawer() {
    isOpen.value = false;
  }

  function toggleDrawer() {
    isOpen.value = !isOpen.value;
  }

  function addItem(stamp: CatalogStamp, mockup: CatalogMockup | null = null) {
    // Evitar duplicações exatas
    const exists = items.value.find(i => i.stamp.id === stamp.id);
    if (!exists) {
      items.value.push({
        id: `mb_item_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
        stamp,
        selected_mockup: mockup,
        notes: '',
        added_at: Date.now()
      });
    }
    openDrawer(); // Abre o carrinho automaticamente para dar feedback visual
  }

  function removeItem(itemId: string) {
    items.value = items.value.filter(i => i.id !== itemId);
  }

  function updateNotes(itemId: string, notes: string) {
    const item = items.value.find(i => i.id === itemId);
    if (item) item.notes = notes;
  }

  function clearBoard() {
    items.value = [];
  }

  async function submitQuoteRequest(customerData: { name: string, email: string, phone: string, company?: string }) {
    if (isEmpty.value) return;

    isLoading.value = true;
    try {
      // Aqui faríamos a chamada à API Supabase para injetar nas tabelas:
      // commerce_leads, commerce_moodboards e commerce_quote_requests
      const payload = {
        lead: customerData,
        items: items.value
      };

      console.log('Enviando pedido de orçamento para o Banco:', payload);

      // Simulando latência de rede
      await new Promise(resolve => setTimeout(resolve, 1500));

      clearBoard();
      closeDrawer();
      return true;
    } catch (error) {
      console.error('Erro ao enviar cotação:', error);
      throw error;
    } finally {
      isLoading.value = false;
    }
  }

  return {
    items,
    isOpen,
    isLoading,
    totalItems,
    isEmpty,
    openDrawer,
    closeDrawer,
    toggleDrawer,
    addItem,
    removeItem,
    updateNotes,
    clearBoard,
    submitQuoteRequest
  };
});
