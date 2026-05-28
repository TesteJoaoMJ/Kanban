<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="moodboard.isOpen"
        class="drawer-backdrop"
        @click="moodboard.closeDrawer"
      ></div>
    </Transition>

    <Transition name="slide-right">
      <aside v-if="moodboard.isOpen" class="moodboard-drawer">

        <header class="drawer-header">
          <div class="header-titles">
            <h2>Seu Moodboard</h2>
            <span class="item-count">{{ moodboard.totalItems }} estampas selecionadas</span>
          </div>
          <button class="close-btn" @click="moodboard.closeDrawer" title="Fechar">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
          </button>
        </header>

        <div class="drawer-body">

          <div v-if="moodboard.isEmpty" class="empty-state">
            <div class="empty-icon">🎨</div>
            <h3>O seu board está vazio</h3>
            <p>Explore as nossas coleções e salve as estampas que mais gostar para solicitar um orçamento conjunto.</p>
            <button class="btn-primary" @click="moodboard.closeDrawer">Explorar Catálogo</button>
          </div>

          <div v-else class="items-list">
            <TransitionGroup name="list">
              <article v-for="item in moodboard.items" :key="item.id" class="mb-item-card">

                <div class="item-image-wrapper">
                  <img :src="item.stamp.main_image_url" :alt="item.stamp.title" class="item-image" />
                </div>

                <div class="item-details">
                  <div class="item-meta">
                    <h4 class="item-title">{{ item.stamp.title }}</h4>
                    <span class="item-ref">{{ item.stamp.ref_code }}</span>
                  </div>

                  <textarea
                    v-model="item.notes"
                    placeholder="Adicionar nota (ex: alterar para tons pastéis)"
                    class="item-notes"
                    @change="moodboard.updateNotes(item.id, item.notes)"
                  ></textarea>
                </div>

                <button class="remove-btn" @click="moodboard.removeItem(item.id)" title="Remover">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                </button>
              </article>
            </TransitionGroup>
          </div>

        </div>

        <footer class="drawer-footer" v-if="!moodboard.isEmpty">
          <button class="btn-checkout" @click="openQuoteModal" :disabled="moodboard.isLoading">
            <span v-if="!moodboard.isLoading">Solicitar Orçamento Comercial</span>
            <span v-else class="loading-spinner">Enviando...</span>
          </button>
          <p class="secure-notice">Nenhum pagamento será cobrado agora.</p>
        </footer>

      </aside>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { useMoodboardStore } from '@/stores/moodboard';

const moodboard = useMoodboardStore();

function openQuoteModal() {
  // Num cenário real, isto abriria um modal recolhendo o Nome/Email da Lead
  // antes de disparar o `moodboard.submitQuoteRequest()`
  const confirmAction = confirm("Deseja enviar estas estampas para a nossa equipa de vendas gerar um orçamento oficial?");

  if(confirmAction) {
    moodboard.submitQuoteRequest({
      name: 'Cliente Visitante',
      email: 'contato@cliente.com',
      phone: '1199999999'
    }).then(() => {
      alert("Sucesso! A nossa equipa entrará em contacto em breve com o seu orçamento.");
    });
  }
}
</script>

<style scoped>
/* Transições Vue */
.fade-enter-active, .fade-leave-active { transition: opacity 0.4s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.slide-right-enter-active, .slide-right-leave-active { transition: transform 0.5s cubic-bezier(0.16, 1, 0.3, 1); }
.slide-right-enter-from, .slide-right-leave-to { transform: translateX(100%); }

.list-enter-active, .list-leave-active { transition: all 0.4s ease; }
.list-enter-from, .list-leave-to { opacity: 0; transform: translateX(30px); }

/* Backdrop Blur (Apple Style) */
.drawer-backdrop {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  z-index: 9998;
}

/* Gaveta Principal */
.moodboard-drawer {
  position: fixed;
  top: 0; right: 0; bottom: 0;
  width: 100%;
  max-width: 440px;
  background-color: #ffffff;
  box-shadow: -10px 0 40px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  z-index: 9999;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
}

/* Header */
.drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  border-bottom: 1px solid #f4f4f5;
}

.header-titles h2 {
  font-size: 20px;
  font-weight: 600;
  color: #111;
  margin: 0 0 4px 0;
  letter-spacing: -0.02em;
}

.item-count {
  font-size: 13px;
  color: #71717a;
}

.close-btn {
  background: transparent;
  border: none;
  color: #52525b;
  cursor: pointer;
  padding: 8px;
  border-radius: 50%;
  transition: background 0.2s;
}

.close-btn:hover { background: #f4f4f5; color: #111; }

/* Corpo e Lista */
.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: 24px 32px;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  text-align: center;
  color: #71717a;
}

.empty-icon { font-size: 48px; margin-bottom: 16px; }
.empty-state h3 { font-size: 18px; color: #111; margin: 0 0 8px 0; }
.empty-state p { font-size: 14px; margin: 0 0 24px 0; max-width: 280px; line-height: 1.5; }

/* Cartões de Item */
.items-list {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.mb-item-card {
  display: flex;
  gap: 16px;
  position: relative;
  padding-bottom: 24px;
  border-bottom: 1px solid #f4f4f5;
}
.mb-item-card:last-child { border-bottom: none; padding-bottom: 0; }

.item-image-wrapper {
  width: 80px;
  height: 106px;
  border-radius: 8px;
  overflow: hidden;
  background: #f4f4f5;
  flex-shrink: 0;
}

.item-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.item-meta { display: flex; flex-direction: column; gap: 2px; }
.item-title { font-size: 15px; font-weight: 600; color: #111; margin: 0; }
.item-ref { font-size: 13px; color: #71717a; font-family: ui-monospace, monospace; }

.item-notes {
  width: 100%;
  border: 1px solid #e4e4e7;
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 13px;
  resize: none;
  height: 54px;
  color: #3f3f46;
  background: #fafafa;
  transition: border-color 0.2s;
  font-family: inherit;
}
.item-notes:focus { outline: none; border-color: #111; background: #fff; }

.remove-btn {
  position: absolute;
  top: 0; right: 0;
  background: transparent;
  border: none;
  color: #a1a1aa;
  cursor: pointer;
  padding: 4px;
}
.remove-btn:hover { color: #dc2626; }

/* Footer Premium */
.drawer-footer {
  padding: 24px 32px;
  border-top: 1px solid #f4f4f5;
  background: #fafafa;
}

.btn-checkout {
  width: 100%;
  background: #111;
  color: #fff;
  border: none;
  padding: 16px;
  border-radius: 99px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.btn-checkout:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0,0,0,0.15);
}

.btn-checkout:disabled {
  background: #a1a1aa;
  cursor: not-allowed;
}

.secure-notice {
  text-align: center;
  font-size: 12px;
  color: #71717a;
  margin: 12px 0 0 0;
}

.btn-primary {
  background: #111;
  color: #fff;
  border: none;
  padding: 12px 24px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}
</style>
