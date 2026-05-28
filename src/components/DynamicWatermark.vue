<template>
  <div
    class="dynamic-watermark-overlay"
    :style="{ opacity: currentOpacity }"
    aria-hidden="true"
  >
    <div class="watermark-container" :class="{ 'moving': isMoving }">
      <div v-for="i in 50" :key="i" class="watermark-text">
        <span>{{ displayIdentity }}</span>
        <span class="separator">&bull;</span>
        <span>Sessão: {{ shortSessionId }}</span>
        <span class="separator">&bull;</span>
        <span>{{ timeString }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useProtectionStore } from '@/stores/protectionStore'

const store = useProtectionStore()
const timeString = ref('')
let timer: ReturnType<typeof setInterval> | null = null

// Exibe o ID do usuário se logado, ou 'Visitante'
const displayIdentity = computed(() => {
  return store.userId ? `ID:${store.userId.substring(0, 8)}` : 'Visitante Anônimo'
})

// Pega apenas a primeira parte do UUID da sessão para não poluir muito a tela
const shortSessionId = computed(() => {
  return store.sessionId ? store.sessionId.split('-')[0] : '...'
})

// A opacidade vem diretamente do motor de risco (0.01 a 0.1)
const currentOpacity = computed(() => store.watermarkOpacity)

// Só anima a marca d'água se o usuário tiver alguma flag de risco ativa
const isMoving = computed(() => store.riskFlag !== 'none')

onMounted(() => {
  updateTime()
  // Atualiza o relógio a cada minuto para o timestamp da marca d'água ficar preciso na gravação
  timer = setInterval(updateTime, 60000)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

function updateTime() {
  const now = new Date()
  timeString.value = now.toLocaleDateString('pt-BR') + ' ' + now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}
</script>

<style scoped>
.dynamic-watermark-overlay {
  position: fixed;
  inset: 0;
  z-index: 999999; /* Fica acima de TUDO no site, incluindo modais */
  pointer-events: none; /* Crucial: permite que o usuário clique nas coisas "através" da marca d'água */
  user-select: none; /* Impede a seleção do texto */
  overflow: hidden;
  mix-blend-mode: overlay; /* Faz a marca d'água se mesclar com as cores de baixo */
  transition: opacity 1.5s ease-in-out; /* Transição suave para o ladrão não perceber a segurança ativando */
}

/* O container é o dobro do tamanho da tela para não faltar texto ao girar e animar */
.watermark-container {
  display: flex;
  flex-wrap: wrap;
  width: 200vw;
  height: 200vh;
  transform: translate(-25%, -25%) rotate(-30deg);
  justify-content: center;
  align-content: center;
  gap: 80px 140px; /* Espaçamento entre as marcas */
}

.watermark-text {
  font-size: 15px;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", monospace;
  font-weight: 800;
  color: rgba(140, 140, 140, 0.9);
  white-space: nowrap;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  display: flex;
  align-items: center;
  gap: 12px;
}

.separator {
  color: #ff3366; /* Um ponto de cor para dificultar remoção por Inteligência Artificial no vídeo */
}

/* Animação sutil para evitar filtros estáticos em vídeos gravados.
  A marca d'água flutua lentamente pela tela.
*/
.moving {
  animation: floatWatermark 30s linear infinite alternate;
}

@keyframes floatWatermark {
  0% { transform: translate(-25%, -25%) rotate(-30deg); }
  100% { transform: translate(-15%, -15%) rotate(-30deg); }
}

/* Ajustes de responsividade para Mobile */
@media (max-width: 768px) {
  .watermark-container {
    gap: 60px 80px;
  }
  .watermark-text {
    font-size: 11px;
  }
}
</style>
