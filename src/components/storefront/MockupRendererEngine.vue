<template>
  <div class="mockup-engine-container">

    <div v-if="isLoading" class="loading-overlay">
      <div class="spinner"></div>
      <span>A renderizar tecido e iluminação...</span>
    </div>

    <canvas
      ref="canvasRef"
      class="mockup-canvas"
      @mousedown="startDrag"
      @mousemove="onDrag"
      @mouseup="endDrag"
      @mouseleave="endDrag"
      @wheel.prevent="onWheel"
    ></canvas>

    <div class="floating-controls" v-if="!isLoading">
      <div class="control-group">
        <label>Escala do Padrão</label>
        <div class="slider-wrapper">
          <button @click="patternScale -= 0.1" :disabled="patternScale <= 0.2">-</button>
          <input
            type="range"
            min="0.2"
            max="3"
            step="0.1"
            v-model.number="patternScale"
          />
          <button @click="patternScale += 0.1" :disabled="patternScale >= 3">+</button>
        </div>
      </div>

      <div class="control-group">
        <label>Rotação</label>
        <div class="slider-wrapper">
          <button @click="patternRotation -= 15">-</button>
          <input
            type="range"
            min="-180"
            max="180"
            step="1"
            v-model.number="patternRotation"
          />
          <button @click="patternRotation += 15">+</button>
        </div>
      </div>

      <div class="hints">
        Dica: Clique e arraste na imagem para mover a estampa. Use o scroll do rato para aplicar zoom.
      </div>

      <div class="actions">
        <button class="btn-primary" @click="exportImage">Transferir Mockup</button>
        <button class="btn-secondary" @click="$emit('close')">Fechar</button>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue';

// Props rigorosas mapeadas da tabela `catalog_mockups`
const props = defineProps<{
  stampUrl: string;
  mockupBaseUrl: string;
  mockupMaskUrl: string;
  mockupShadowUrl: string;
}>();

const emit = defineEmits(['close']);

// Referências de DOM e Estado
const canvasRef = ref<HTMLCanvasElement | null>(null);
const isLoading = ref(true);

// Controles do utilizador (Reativos)
const patternScale = ref(1);
const patternRotation = ref(0);
const patternOffsetX = ref(0);
const patternOffsetY = ref(0);

// Imagens carregadas em memória (Offscreen)
let imgBase: HTMLImageElement;
let imgMask: HTMLImageElement;
let imgShadow: HTMLImageElement;
let imgStamp: HTMLImageElement;

// Variáveis de interação de rato (Drag)
let isDragging = false;
let startX = 0;
let startY = 0;

// ==========================================
// CARREGAMENTO DE IMAGENS ASSÍNCRONO
// ==========================================
function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = "Anonymous"; // Crucial para exportar o canvas depois (CORS)
    img.onload = () => resolve(img);
    img.onerror = (err) => reject(err);
    img.src = src;
  });
}

async function initEngine() {
  isLoading.value = true;
  try {
    // Carrega todas as camadas simultaneamente para máxima performance
    [imgBase, imgMask, imgShadow, imgStamp] = await Promise.all([
      loadImage(props.mockupBaseUrl),
      loadImage(props.mockupMaskUrl),
      loadImage(props.mockupShadowUrl),
      loadImage(props.stampUrl)
    ]);

    setupCanvas();
    renderMockup();
  } catch (error) {
    console.error("Falha ao carregar assets do mockup:", error);
    alert("Não foi possível carregar o renderizador 3D. Verifique os links das imagens.");
  } finally {
    isLoading.value = false;
  }
}

// ==========================================
// RENDERIZAÇÃO CORE (Canvas API)
// ==========================================
function setupCanvas() {
  if (!canvasRef.value || !imgBase) return;
  // Define o tamanho do canvas para corresponder à imagem base de alta resolução
  canvasRef.value.width = imgBase.width;
  canvasRef.value.height = imgBase.height;
}

function renderMockup() {
  const canvas = canvasRef.value;
  if (!canvas || !imgBase || !imgMask || !imgShadow || !imgStamp) return;

  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const width = canvas.width;
  const height = canvas.height;

  // 1. Limpa o canvas
  ctx.clearRect(0, 0, width, height);
  ctx.globalCompositeOperation = 'source-over'; // Default

  // 2. Desenha a Imagem Base (O fundo, ex: parede branca, pescoço do manequim)
  ctx.drawImage(imgBase, 0, 0, width, height);

  // 3. Inicia o recorte da Estampa (Clipping Mask)
  // Desenhamos a máscara (que é a silhueta da t-shirt/tecido em preto e branco opaco)
  ctx.drawImage(imgMask, 0, 0, width, height);

  // Agora a magia: 'source-in' faz com que tudo o que for desenhado a seguir SÓ APAREÇA onde a máscara foi desenhada
  ctx.globalCompositeOperation = 'source-in';

  // 4. Desenha a Estampa (com cálculos matemáticos de escala, rotação e movimento)
  ctx.save();

  // Move o ponto central para permitir rotação correta
  const centerX = width / 2;
  const centerY = height / 2;
  ctx.translate(centerX + patternOffsetX.value, centerY + patternOffsetY.value);

  // Aplica rotação (convertida para radianos)
  ctx.rotate((patternRotation.value * Math.PI) / 180);

  // Aplica a escala
  ctx.scale(patternScale.value, patternScale.value);

  // Para tecidos, repetimos a imagem (Pattern) caso ela seja Seamless, ou desenhamos centrada
  // Neste caso, criamos um preenchimento repetido (Seamless) nativo do Canvas
  const pattern = ctx.createPattern(imgStamp, 'repeat');
  if (pattern) {
    ctx.fillStyle = pattern;
    // Preenche uma área gigante ao redor do centro para garantir que, ao rodar ou mover, não faltem bordas
    ctx.fillRect(-width * 2, -height * 2, width * 4, height * 4);
  }

  ctx.restore(); // Restaura as transformações para não afetar a próxima camada

  // 5. Aplica as Dobras e Sombras (Luzes volumétricas)
  // O blend mode 'multiply' escurece a estampa onde há dobras (sombras) preservando as cores da estampa
  ctx.globalCompositeOperation = 'multiply';
  ctx.drawImage(imgShadow, 0, 0, width, height);

  // Restaura para o padrão para o próximo ciclo de renderização
  ctx.globalCompositeOperation = 'source-over';
}

// ==========================================
// REATIVIDADE E INTERAÇÕES (Mouse/Touch)
// ==========================================

// Re-renderiza 60fps sempre que um slider é alterado
watch([patternScale, patternRotation, patternOffsetX, patternOffsetY], () => {
  requestAnimationFrame(renderMockup);
});

function startDrag(e: MouseEvent) {
  isDragging = true;
  startX = e.clientX - patternOffsetX.value;
  startY = e.clientY - patternOffsetY.value;
}

function onDrag(e: MouseEvent) {
  if (!isDragging) return;
  // Fator de correção de movimento (pois o canvas original pode ser maior que o CSS em tela)
  const rect = canvasRef.value!.getBoundingClientRect();
  const scaleX = canvasRef.value!.width / rect.width;
  const scaleY = canvasRef.value!.height / rect.height;

  patternOffsetX.value = (e.clientX - startX) * scaleX;
  patternOffsetY.value = (e.clientY - startY) * scaleY;
}

function endDrag() {
  isDragging = false;
}

function onWheel(e: WheelEvent) {
  // Zoom suave com a roda do rato
  const zoomSpeed = 0.05;
  if (e.deltaY < 0) {
    patternScale.value = Math.min(patternScale.value + zoomSpeed, 3);
  } else {
    patternScale.value = Math.max(patternScale.value - zoomSpeed, 0.2);
  }
}

// ==========================================
// EXPORTAÇÃO
// ==========================================
function exportImage() {
  if (!canvasRef.value) return;
  const link = document.createElement('a');
  link.download = `mockup-${Date.now()}.png`;
  link.href = canvasRef.value.toDataURL('image/png');
  link.click();
}

onMounted(() => {
  initEngine();
});

onUnmounted(() => {
  // Limpeza de memória
  imgBase = imgMask = imgShadow = imgStamp = null as any;
});
</script>

<style scoped>
/* ==========================================================================
   DESIGN DA INTERFACE DO MOCKUP (Imersivo e Premium)
============================================================================= */
.mockup-engine-container {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: #f4f4f5;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  overflow: hidden;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
}

.mockup-canvas {
  max-width: 100%;
  max-height: 100vh;
  object-fit: contain;
  cursor: grab;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
}
.mockup-canvas:active { cursor: grabbing; }

/* CONTROLES FLUTUANTES (Apple Glassmorphism) */
.floating-controls {
  position: absolute;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: 24px;
  border-radius: 20px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.5);
  width: 90%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  border: 1px solid rgba(255,255,255,0.4);
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.control-group label {
  font-size: 13px;
  font-weight: 600;
  color: #111;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.slider-wrapper {
  display: flex;
  align-items: center;
  gap: 12px;
}

.slider-wrapper button {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 1px solid #d4d4d8;
  background: #fff;
  color: #111;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}
.slider-wrapper button:hover:not(:disabled) { border-color: #111; background: #f4f4f5; }
.slider-wrapper button:disabled { opacity: 0.5; cursor: not-allowed; }

/* Custom Range Input Premium */
input[type=range] {
  -webkit-appearance: none;
  flex: 1;
  background: transparent;
}
input[type=range]::-webkit-slider-thumb {
  -webkit-appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: #111;
  cursor: pointer;
  margin-top: -8px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
}
input[type=range]::-webkit-slider-runnable-track {
  width: 100%;
  height: 4px;
  cursor: pointer;
  background: #e4e4e7;
  border-radius: 2px;
}

.hints {
  font-size: 12px;
  color: #71717a;
  text-align: center;
  line-height: 1.4;
}

.actions {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

.btn-primary, .btn-secondary {
  flex: 1;
  padding: 12px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: transform 0.2s;
}
.btn-primary { background: #111; color: #fff; }
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
.btn-secondary { background: #e4e4e7; color: #111; }
.btn-secondary:hover { background: #d4d4d8; }

/* Loading State */
.loading-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  color: #71717a;
  font-weight: 500;
  font-size: 14px;
  z-index: 10;
}
.spinner {
  width: 40px; height: 40px;
  border: 3px solid #e4e4e7; border-top-color: #111;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
