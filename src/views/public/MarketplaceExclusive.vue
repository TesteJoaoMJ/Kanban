<template>
  <div class="view-wrap exclusive-page">
    <div class="ambient-glow glow-1"></div>
    <div class="ambient-glow glow-2"></div>

    <v-container class="exclusive-container">

      <section class="hero-section text-center">
        <div class="crown-wrapper">
          <v-icon size="56" color="warning" class="floating-crown">mdi-crown</v-icon>
          <div class="crown-glow"></div>
        </div>

        <div class="hero-kicker">Acesso Restrito</div>
        <h1 class="hero-title">Estampas <span class="text-gradient">Exclusivas</span></h1>

        <p class="hero-subtitle">
          Um acervo confidencial com curadoria de alto padrão.
          Designs únicos, modelagens sofisticadas e antecipação de tendências globais,
          reservados estritamente para nossos Clientes Premium.
        </p>

        <div class="hero-actions">
          <button class="premium-btn primary-glow" @click="goToProfile">
            <span class="btn-text">Solicitar Acesso VIP</span>
            <v-icon size="20" class="ml-2">mdi-arrow-right</v-icon>
          </button>
        </div>
      </section>

      <section class="floating-gallery-section">
        <div class="gallery-perspective" v-if="randomStamps.length >= 3">

          <div class="floating-stamp stamp-1 mj-border" @click="goToProduct(randomStamps[0].id)">
            <img :src="getOptimizedUrl(randomStamps[0].main_image_url, 600)" @error="handleImageError" alt="Estampa Exclusiva 1" />
            <div class="stamp-shade"></div>
          </div>

          <div class="floating-stamp stamp-2 mj-border" @click="goToProduct(randomStamps[1].id)">
            <img :src="getOptimizedUrl(randomStamps[1].main_image_url, 600)" @error="handleImageError" alt="Estampa Exclusiva 2" />
            <div class="stamp-shade"></div>
          </div>

          <div class="floating-stamp stamp-3 mj-border" @click="goToProduct(randomStamps[2].id)">
            <img :src="getOptimizedUrl(randomStamps[2].main_image_url, 600)" @error="handleImageError" alt="Estampa Exclusiva 3" />
            <div class="stamp-shade"></div>
          </div>

          <div class="perspective-text mj-surface mj-border">
            <v-icon color="primary" class="mr-2">mdi-lock-outline</v-icon>
            CONFIDENTIAL COLLECTION
          </div>

        </div>
        <div v-else-if="isLoading" class="d-flex justify-center align-center w-100" style="height: 300px;">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
        </div>
      </section>

      <section class="benefits-section">
        <div class="benefits-grid">

          <div class="benefit-card mj-surface mj-border">
            <div class="card-icon-wrap">
              <v-icon size="32" color="primary">mdi-diamond-stone</v-icon>
            </div>
            <h3 class="card-title">Curadoria Especialista</h3>
            <p class="card-text">
              Nossa equipe de diretores de arte seleciona a dedo os padrões mais promissores da temporada, garantindo que sua marca tenha sempre o melhor do design têxtil.
            </p>
          </div>

          <div class="benefit-card mj-surface mj-border">
            <div class="card-icon-wrap">
              <v-icon size="32" color="primary">mdi-eye-off-outline</v-icon>
            </div>
            <h3 class="card-title">Total Exclusividade</h3>
            <p class="card-text">
              Ao adquirir uma estampa do nosso acervo Premium, garantimos que ela será removida do catálogo, assegurando que o DNA da sua coleção permaneça único.
            </p>
          </div>

          <div class="benefit-card mj-surface mj-border">
            <div class="card-icon-wrap">
              <v-icon size="32" color="primary">mdi-trending-up</v-icon>
            </div>
            <h3 class="card-title">Antecipação de Tendências</h3>
            <p class="card-text">
              Acesso antecipado a macrotendências europeias e relatórios de estilo meses antes de chegarem ao mercado aberto. Saia sempre na frente.
            </p>
          </div>

        </div>
      </section>

      <section class="bottom-banner mj-border">
        <div class="banner-content">
          <h2 class="banner-title">Pronto para elevar o padrão da sua marca?</h2>
          <p class="banner-text">O processo de aprovação é feito mediante análise de perfil para garantir a exclusividade do nosso ecossistema.</p>
        </div>
        <div class="banner-action">
          <button class="premium-btn-outline" @click="goToProfile">
            <v-icon size="20" class="mr-2">mdi-lock-open-outline</v-icon>
            Quero ser Premium
          </button>
        </div>
      </section>

    </v-container>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/api/supabase'

const router = useRouter()
const randomStamps = ref<any[]>([])
const isLoading = ref(true)

function goToProfile() {
  router.push('/marketplace/perfil')
}

function goToProduct(id: string) {
  router.push(`/marketplace/produto/${id}`)
}

// Utilitário de otimização de imagem padrão do projeto para não pesar o carregamento
function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return '/placeholder.png'
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl
  try {
    const parts = originalUrl.split('/object/public/')
    const pathBucket = parts[1]
    const slashIdx = pathBucket.indexOf('/')
    const bucket = pathBucket.substring(0, slashIdx)
    let filePath = pathBucket.substring(slashIdx + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    filePath = decodeURIComponent(filePath)
    const { data } = supabase.storage.from(bucket).getPublicUrl(filePath, { transform: { width: targetWidth } })
    return data.publicUrl
  } catch (err) { return originalUrl }
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) img.src = '/placeholder.png'
}

onMounted(async () => {
  try {
    // Busca até 100 estampas ativas para ter uma boa base de aleatoriedade
    const { data, error } = await supabase
      .from('catalog_stamps')
      .select('id, main_image_url')
      .eq('is_active', true)
      .limit(100)

    if (data && data.length > 0) {
      // Embaralha o array de forma aleatória
      const shuffled = [...data].sort(() => 0.5 - Math.random())
      // Pega as 3 primeiras
      randomStamps.value = shuffled.slice(0, 3)

      // Fallback: se tiver menos de 3 estampas cadastradas no banco, duplica para não quebrar o layout 3D
      while (randomStamps.value.length < 3 && randomStamps.value.length > 0) {
         randomStamps.value.push(randomStamps.value[0])
      }
    }
  } catch (e) {
    console.error('Erro ao buscar estampas para a galeria 3D:', e)
  } finally {
    isLoading.value = false
  }
})
</script>

<style scoped>
/* =========================================
   FUNDAÇÃO E AMBIENTAÇÃO 3D
========================================== */
.view-wrap.exclusive-page {
  padding-top: 120px;
  padding-bottom: 80px;
  min-height: calc(100vh - 88px);
  position: relative;
  overflow: hidden;
  background: var(--bg-background);
}

.exclusive-container {
  position: relative;
  z-index: 10;
  max-width: 1200px;
  margin: 0 auto;
}

/* Efeitos de Luz Premium */
.ambient-glow {
  position: absolute;
  border-radius: 50%;
  filter: blur(120px);
  opacity: 0.1;
  z-index: 1;
  pointer-events: none;
  animation: pulse-glow 8s infinite alternate ease-in-out;
}

.glow-1 {
  width: 600px;
  height: 600px;
  background: rgb(var(--v-theme-primary));
  top: -100px;
  left: -200px;
}

.glow-2 {
  width: 500px;
  height: 500px;
  background: #f59e0b;
  bottom: -100px;
  right: -150px;
  animation-delay: -4s;
}

@keyframes pulse-glow {
  0% { transform: scale(1) translate(0, 0); opacity: 0.08; }
  100% { transform: scale(1.1) translate(30px, -30px); opacity: 0.15; }
}

/* =========================================
   HERO SECTION
========================================== */
.hero-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin-bottom: clamp(60px, 8vw, 100px);
}

.crown-wrapper {
  position: relative;
  margin-bottom: 24px;
}

.floating-crown {
  animation: float-crown 4s ease-in-out infinite;
  position: relative;
  z-index: 2;
}

.crown-glow {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 60px;
  height: 60px;
  background: #f59e0b;
  filter: blur(30px);
  opacity: 0.4;
  z-index: 1;
}

@keyframes float-crown {
  0% { transform: translateY(0px); }
  50% { transform: translateY(-10px); }
  100% { transform: translateY(0px); }
}

.hero-kicker {
  font-size: 13px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.2em;
  color: var(--text-muted);
  margin-bottom: 16px;
}

.hero-title {
  font-size: clamp(2.8rem, 6vw, 5rem);
  font-weight: 900;
  letter-spacing: -0.04em;
  line-height: 1.1;
  color: var(--text-main);
  margin-bottom: 24px;
}

.text-gradient {
  background: linear-gradient(135deg, rgb(var(--v-theme-primary)), #f59e0b);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-subtitle {
  font-size: clamp(1.05rem, 1.8vw, 1.2rem);
  color: var(--text-soft);
  max-width: 650px;
  line-height: 1.6;
  margin-bottom: 40px;
}

/* =========================================
   NOVA SEÇÃO: GALERIA FLUTUANTE 3D
========================================== */
.floating-gallery-section {
  position: relative;
  height: clamp(300px, 40vh, 450px);
  width: 100%;
  margin-bottom: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 5;
}

.gallery-perspective {
  position: relative;
  width: 100%;
  height: 100%;
  perspective: 1500px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.floating-stamp {
  position: absolute;
  width: clamp(180px, 20vw, 260px);
  aspect-ratio: 3 / 4;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 30px 60px rgba(0,0,0,0.3);
  transition: all 0.6s cubic-bezier(0.165, 0.84, 0.44, 1);
  transform-style: preserve-3d;
  cursor: pointer;
  background: var(--bg-surface-2);
}

.floating-stamp img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

/* Sombra interna para dar volume ao inclinar */
.stamp-shade {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(0,0,0,0.4), transparent 60%);
  opacity: 0;
  transition: opacity 0.6s ease;
  pointer-events: none;
}

/* Efeito ao passar o mouse */
.floating-stamp:hover {
  transform: translateZ(100px) rotateX(0deg) rotateY(0deg) !important;
  box-shadow: 0 50px 100px rgba(0,0,0,0.5);
  z-index: 50 !important;
  border-color: rgb(var(--v-theme-primary)) !important;
}

.floating-stamp:hover .stamp-shade {
  opacity: 1;
}

/* --- POSICIONAMENTO E INCLINAÇÃO INDIVIDUAL --- */
.stamp-1 {
  left: 10%;
  transform: rotateY(25deg) rotateX(10deg) translateZ(-50px);
  animation: float-stamp-1 6s infinite alternate ease-in-out;
  z-index: 10;
}

.stamp-2 {
  transform: rotateY(-10deg) rotateX(5deg) translateZ(50px);
  animation: float-stamp-2 5s infinite alternate ease-in-out;
  z-index: 30;
}

.stamp-3 {
  right: 10%;
  transform: rotateY(-25deg) rotateX(10deg) translateZ(-50px);
  animation: float-stamp-3 6s infinite alternate ease-in-out;
  z-index: 10;
}

.perspective-text {
  position: absolute;
  font-size: 11px;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.3em;
  color: var(--text-muted);
  padding: 10px 20px;
  border-radius: 99px;
  transform: translateZ(-150px);
  opacity: 0.5;
  display: flex;
  align-items: center;
  user-select: none;
}

/* --- ANIMAÇÕES DE FLUTUAÇÃO INDIVIDUAIS --- */
@keyframes float-stamp-1 {
  0% { transform: rotateY(25deg) rotateX(10deg) translateZ(-50px) translateY(0px); }
  100% { transform: rotateY(20deg) rotateX(8deg) translateZ(-50px) translateY(-15px); }
}

@keyframes float-stamp-2 {
  0% { transform: rotateY(-10deg) rotateX(5deg) translateZ(50px) translateY(0px); }
  100% { transform: rotateY(-8deg) rotateX(4deg) translateZ(50px) translateY(-20px); }
}

@keyframes float-stamp-3 {
  0% { transform: rotateY(-25deg) rotateX(10deg) translateZ(-50px) translateY(0px); }
  100% { transform: rotateY(-20deg) rotateX(8deg) translateZ(-50px) translateY(-15px); }
}

/* =========================================
   BENEFÍCIOS E OUTROS
========================================== */
.premium-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 56px;
  padding: 0 40px;
  border-radius: 99px;
  background: rgb(var(--v-theme-primary));
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  border: none;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
  box-shadow: 0 8px 24px rgba(var(--v-theme-primary), 0.25);
}

.premium-btn::before {
  content: '';
  position: absolute;
  top: 0; left: -100%; width: 100%; height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: all 0.5s ease;
}

.premium-btn:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(var(--v-theme-primary), 0.4);
}

.premium-btn:hover::before {
  left: 100%;
}

.premium-btn-outline {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 56px;
  padding: 0 32px;
  border-radius: 12px;
  background: transparent;
  color: var(--text-main);
  font-size: 14px;
  font-weight: 800;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  border: 2px solid var(--border-strong);
  cursor: pointer;
  transition: all 0.3s ease;
}

.premium-btn-outline:hover {
  background: var(--bg-surface);
  border-color: rgb(var(--v-theme-primary));
  color: rgb(var(--v-theme-primary));
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.1);
}

.benefits-section {
  margin-bottom: 80px;
}

.benefits-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}

.benefit-card {
  padding: 40px 32px;
  border-radius: 20px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1);
  background: linear-gradient(145deg, var(--bg-surface), var(--bg-surface-2));
}

.benefit-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 24px 48px rgba(0,0,0,0.12);
  border-color: rgba(var(--v-theme-primary), 0.4) !important;
}

.card-icon-wrap {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  background: rgba(var(--v-theme-primary), 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
  transition: transform 0.4s ease;
}

.benefit-card:hover .card-icon-wrap {
  transform: scale(1.1) rotate(5deg);
  background: rgb(var(--v-theme-primary));
}

.benefit-card:hover .card-icon-wrap .v-icon {
  color: #fff !important;
}

.card-title {
  font-size: 1.4rem;
  font-weight: 800;
  color: var(--text-main);
  margin-bottom: 16px;
  letter-spacing: -0.02em;
}

.card-text {
  font-size: 1rem;
  color: var(--text-soft);
  line-height: 1.6;
}

.bottom-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 48px 56px;
  border-radius: 24px;
  background: radial-gradient(circle at right, rgba(var(--v-theme-primary), 0.08), transparent 50%), var(--bg-surface);
  box-shadow: 0 16px 40px rgba(0,0,0,0.08);
}

.banner-title {
  font-size: 2rem;
  font-weight: 900;
  color: var(--text-main);
  letter-spacing: -0.03em;
  margin-bottom: 8px;
}

.banner-text {
  font-size: 1.1rem;
  color: var(--text-soft);
  max-width: 500px;
}

/* =========================================
   RESPONSIVIDADE
========================================== */
@media (max-width: 1100px) {
  .floating-stamp { width: clamp(150px, 18vw, 200px); }
}

@media (max-width: 959px) {
  .hero-subtitle { margin-bottom: 20px; }
  .floating-gallery-section { height: 300px; margin-bottom: 60px; }
  .stamp-1 { left: 5%; }
  .stamp-3 { right: 5%; }

  .benefits-grid { grid-template-columns: repeat(2, 1fr); }
  .bottom-banner { flex-direction: column; text-align: center; gap: 32px; padding: 40px 24px; }
  .banner-text { margin: 0 auto; }
}

@media (max-width: 700px) {
  .gallery-perspective { perspective: none; gap: 10px; flex-wrap: wrap; height: auto; padding: 20px; }
  .floating-gallery-section { height: auto; }
  .floating-stamp { position: relative; inset: auto; transform: none !important; animation: none !important; width: calc(33% - 10px); }
  .perspective-text { display: none; }
}

@media (max-width: 599px) {
  .view-wrap.exclusive-page { padding-top: 80px; }
  .hero-title { font-size: 2.5rem; }
  .floating-stamp { width: calc(50% - 10px); }
  .benefits-grid { grid-template-columns: 1fr; }
  .benefit-card { padding: 32px 24px; align-items: center; text-align: center; }
  .banner-title { font-size: 1.5rem; }
}
</style>
