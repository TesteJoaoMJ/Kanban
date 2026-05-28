<template>
  <v-app>
    <transition name="fade-boot">
      <div v-if="isBooting" class="enterprise-boot-screen">
        <div class="boot-content">
          <img :src="currentLogo" alt="MJ Process" class="boot-logo pulse-anim" />
          <div class="boot-loader-container">
            <div class="boot-loader-bar" :style="{ width: bootProgress + '%' }"></div>
          </div>
          <div class="boot-text font-monospace">{{ bootText }}</div>
        </div>
      </div>
    </transition>

    <div :class="['mj-landing-wrapper', isDark ? 'theme-dark' : 'theme-light']" v-show="!isBooting">

      <header :class="['glass-header', { 'scrolled': isScrolled }]">
        <div class="header-content">
          <a href="/">
            <img :src="currentLogo" alt="MJ Process" class="logo" />
          </a>

          <nav class="desktop-nav">
            <a href="/#pilares">Os Pilares</a>
            <a href="/#arquitetura">Arquitetura</a>
            <a href="/#modulos">Ecossistema</a>
            <a href="/#planos">Planos</a>
          </nav>

          <div class="header-actions">
            <v-btn icon variant="text" @click="toggleTheme" class="theme-btn">
              <v-icon>{{ isDark ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
            </v-btn>
            <a href="https://webmail.suaempresa.com" target="_blank" class="webmail-link">Webmail</a>
            <v-btn color="primary" variant="flat" class="login-btn" @click="initiateBootSequence">Acessar ERP</v-btn>
          </div>
        </div>
      </header>

      <main class="privacy-main">
        <div class="ambient-clouds"></div>

        <section class="privacy-hero pt-16 pb-8">
          <v-container class="position-relative z-1 max-w-1000 mt-16 text-center">
            <div class="badge-premium mb-6">Governança e Compliance Jurídico</div>
            <h1 class="colossal-title-small mb-6">Política de Privacidade e <br><span class="gradient-text">Proteção de Dados (LGPD)</span></h1>
            <p class="hero-subtitle mx-auto">
              Diretrizes rigorosas de segurança, criptografia e tratamento de dados corporativos da plataforma MJ Process Technologies. Atualizado em {{ new Date().toLocaleDateString('pt-BR') }}.
            </p>
          </v-container>
        </section>

        <section class="privacy-content section-padding pt-0">
          <v-container class="max-w-1000">
            <div class="mj-card privacy-document pa-8 pa-md-16">

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6 d-flex align-center gap-3">
                  <v-icon color="primary" size="36">mdi-shield-check</v-icon>
                  1. Compromisso Enterprise com a Privacidade
                </h2>
                <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                  A <strong>MJ Process Technologies</strong> (doravante "Nós", "Plataforma" ou "Controladora") reconhece a criticidade absoluta das informações industriais, comerciais e financeiras alocadas em nossa infraestrutura. Construímos nossa arquitetura não apenas para otimizar operações fabris, mas para atuar como um cofre digital inviolável para os seus dados corporativos.
                </p>
                <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                  Este documento destrincha, de forma extensa e transparente, nossas práticas de coleta, retenção, processamento e exclusão de dados, em estrita conformidade com a <strong>Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018)</strong> e demais legislações globais de segurança da informação.
                </p>
              </div>

              <v-divider class="opacity-20 mb-12"></v-divider>

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6">2. Natureza dos Dados Coletados</h2>
                <p class="text-body-1 muted-text mb-6">
                  Para prover o ecossistema tático do nosso ERP, operamos com a coleta minimizada de dados, divididos nas seguintes categorias:
                </p>

                <h3 class="text-h6 font-weight-bold mb-3 text-primary">2.1. Dados de Identificação Corporativa e Usuários (Tenant)</h3>
                <ul class="privacy-list mb-6 text-body-1 muted-text">
                  <li><strong>Dados Cadastrais da Empresa:</strong> Razão Social, CNPJ, Inscrição Estadual, endereço sede, certificados digitais A1/A3 (armazenados em cofres criptografados) para emissão de notas fiscais junto à Sefaz.</li>
                  <li><strong>Contas de Usuários (Colaboradores):</strong> Nome completo, e-mail corporativo, cargo, departamento e número de celular para autenticação multifator (MFA) e trilhas de auditoria internas.</li>
                </ul>

                <h3 class="text-h6 font-weight-bold mb-3 text-primary">2.2. Dados Operacionais e Transacionais</h3>
                <ul class="privacy-list mb-6 text-body-1 muted-text">
                  <li><strong>Informações de Clientes Finais:</strong> Dados inseridos no módulo de CRM/PDV por sua empresa (B2B ou B2C), sob sua responsabilidade como Controladora dos dados dos seus clientes. Nós atuamos estritamente como <em>Operadores</em> desses dados.</li>
                  <li><strong>Dados Financeiros:</strong> Integrações Open Finance para conciliação bancária transitam de forma anonimizada e protegida pelas APIs bancárias oficiais do Banco Central (Bacen).</li>
                </ul>

                <h3 class="text-h6 font-weight-bold mb-3 text-primary">2.3. Telemetria e Logs de Auditoria</h3>
                <ul class="privacy-list text-body-1 muted-text">
                  <li>Coletamos endereços IP, geolocalização aproximada, tipo de navegador e timestamps rigorosos de acessos, alterações de cadastros e exclusões. Isso garante a governança e a capacidade de rastrear a origem de qualquer modificação no sistema (Trilha de Auditoria Inviolável).</li>
                </ul>
              </div>

              <v-divider class="opacity-20 mb-12"></v-divider>

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6">3. Arquitetura de Proteção e Isolamento RLS</h2>
                <div class="bg-alternate pa-6 rounded-lg border mb-6">
                  <p class="text-body-1 mb-0 font-weight-medium">
                    <v-icon color="warning" class="mr-2">mdi-lock-outline</v-icon>
                    Nossa infraestrutura opera sob a premissa de "Zero Trust" (Confiança Zero).
                  </p>
                </div>
                <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                  Ao contrário de sistemas legados, o MJ Process não mistura seus dados em tabelas genéricas expostas a falhas de aplicação. Utilizamos <strong>PostgreSQL com Row Level Security (RLS) nativo</strong>.
                </p>
                <p class="text-body-1 muted-text line-height-relaxed">
                  Isso significa que o isolamento de dados ocorre a nível de hardware e banco de dados. Um vendedor não possui a capacidade computacional de acessar a carteira de outro vendedor, assim como um Tenant (sua empresa) não compartilha o mesmo escopo de memória de outro Tenant. Toda a comunicação ponta a ponta (E2EE) é protegida por protocolos TLS 1.3.
                </p>
              </div>

              <v-divider class="opacity-20 mb-12"></v-divider>

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6">4. Compartilhamento e Suboperadores</h2>
                <p class="text-body-1 muted-text mb-6 line-height-relaxed">
                  A MJ Process Technologies <strong>jamais venderá, alugará ou monetizará</strong> os dados operacionais da sua empresa. O compartilhamento ocorre única e exclusivamente com infraestruturas essenciais para o funcionamento do software:
                </p>

                <div class="d-flex flex-column gap-4">
                  <div class="d-flex align-start gap-4">
                    <v-avatar color="info" variant="tonal" size="48" class="flex-shrink-0"><v-icon>mdi-cloud</v-icon></v-avatar>
                    <div>
                      <h4 class="font-weight-bold text-h6 mb-1">Infraestrutura em Nuvem (AWS / Supabase)</h4>
                      <p class="text-body-2 muted-text mb-0">Utilizamos clusters distribuídos de altíssima segurança para hospedagem do banco de dados e execução de Edge Functions, todos sob certificação ISO 27001 e SOC 2.</p>
                    </div>
                  </div>
                  <div class="d-flex align-start gap-4">
                    <v-avatar color="warning" variant="tonal" size="48" class="flex-shrink-0"><v-icon>mdi-bank</v-icon></v-avatar>
                    <div>
                      <h4 class="font-weight-bold text-h6 mb-1">Entidades Governamentais (Sefaz)</h4>
                      <p class="text-body-2 muted-text mb-0">Transmissão automatizada de XMLs fiscais estritamente para os webservices das Secretarias de Estado da Fazenda, quando solicitado pelo usuário através do Motor Fiscal da plataforma.</p>
                    </div>
                  </div>
                </div>
              </div>

              <v-divider class="opacity-20 mb-12"></v-divider>

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6">5. Retenção de Dados e Backups (PITR)</h2>
                <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                  Mantemos os dados corporativos ativos pelo tempo de vigência do contrato. Nossa rotina de contingência inclui Backups Contínuos (PITR - Point-in-Time Recovery), garantindo que sua operação possa ser restaurada com granularidade de segundos em caso de desastres.
                </p>
                <p class="text-body-1 muted-text line-height-relaxed">
                  Após o encerramento do contrato, a empresa terá o prazo de 30 dias para exportar seu banco de dados completo. Transcorrido esse prazo, iniciamos o protocolo de expurgo automatizado, onde os dados são destruídos criptograficamente de nossos servidores, mantendo-se apenas os logs exigidos por leis fiscais (prazo legal de 5 anos para NFe).
                </p>
              </div>

              <v-divider class="opacity-20 mb-12"></v-divider>

              <div class="document-section mb-12">
                <h2 class="text-h4 font-weight-black mb-6">6. Direitos dos Titulares (Art. 18 LGPD)</h2>
                <p class="text-body-1 muted-text mb-6">Sua empresa e seus usuários finais possuem controle absoluto sobre seus dados pessoais, podendo solicitar a qualquer momento:</p>

                <v-row>
                  <v-col cols="12" sm="6">
                    <div class="bg-surface border pa-4 rounded-lg h-100">
                      <v-icon color="primary" class="mb-2">mdi-magnify-scan</v-icon>
                      <h4 class="font-weight-bold mb-1">Confirmação e Acesso</h4>
                      <p class="text-body-2 muted-text mb-0">Direito de saber quais dados estão sendo processados e obter cópia em formato legível (.csv ou .json).</p>
                    </div>
                  </v-col>
                  <v-col cols="12" sm="6">
                    <div class="bg-surface border pa-4 rounded-lg h-100">
                      <v-icon color="primary" class="mb-2">mdi-file-document-edit-outline</v-icon>
                      <h4 class="font-weight-bold mb-1">Retificação</h4>
                      <p class="text-body-2 muted-text mb-0">Correção de dados incompletos, inexatos ou desatualizados diretamente pelo painel administrativo.</p>
                    </div>
                  </v-col>
                  <v-col cols="12" sm="6">
                    <div class="bg-surface border pa-4 rounded-lg h-100">
                      <v-icon color="error" class="mb-2">mdi-delete-empty-outline</v-icon>
                      <h4 class="font-weight-bold mb-1">Anonimização ou Exclusão</h4>
                      <p class="text-body-2 muted-text mb-0">Eliminação de dados desnecessários, respeitando as guardas legais obrigatórias.</p>
                    </div>
                  </v-col>
                  <v-col cols="12" sm="6">
                    <div class="bg-surface border pa-4 rounded-lg h-100">
                      <v-icon color="success" class="mb-2">mdi-export-variant</v-icon>
                      <h4 class="font-weight-bold mb-1">Portabilidade</h4>
                      <p class="text-body-2 muted-text mb-0">Transferência dos dados a outro fornecedor de serviço, através da nossa API REST aberta.</p>
                    </div>
                  </v-col>
                </v-row>
              </div>

              <div class="document-section bg-alternate border rounded-lg pa-8 text-center mt-12">
                <v-avatar color="primary" variant="tonal" size="64" class="mb-4">
                  <v-icon size="32">mdi-card-account-mail-outline</v-icon>
                </v-avatar>
                <h3 class="text-h5 font-weight-black mb-3">Contato do DPO (Encarregado de Dados)</h3>
                <p class="text-body-1 muted-text mb-6 max-w-800 mx-auto">
                  Para exercer seus direitos, relatar vulnerabilidades ou solicitar esclarecimentos jurídicos sobre nossa governança, contate diretamente nossa equipe de segurança corporativa.
                </p>
                <div class="d-inline-flex align-center bg-surface border rounded-pill px-6 py-3 font-weight-bold text-h6">
                  <v-icon color="primary" class="mr-3">mdi-email-lock</v-icon>
                  dpo@mjprocess.com.br
                </div>
              </div>

            </div>
          </v-container>
        </section>
      </main>

      <footer class="mj-footer pt-16 pb-8 border-t">
        <v-container>
          <v-row class="mb-12">
            <v-col cols="12" md="4" class="pr-md-8">
              <img :src="currentLogo" alt="MJ Process" class="logo mb-6" style="height: 36px;" />
              <p class="text-body-2 muted-text mb-6">
                O software de gestão proprietário projetado por engenheiros para empresas que exigem excelência técnica e controle operacional absoluto na cadeia produtiva brasileira.
              </p>
              <div class="d-flex gap-4">
                <v-btn icon="mdi-linkedin" variant="tonal" size="small"></v-btn>
                <v-btn icon="mdi-instagram" variant="tonal" size="small"></v-btn>
                <v-btn icon="mdi-github" variant="tonal" size="small"></v-btn>
              </div>
            </v-col>
            <v-col cols="6" md="2">
              <h4 class="font-weight-bold mb-4 text-h6">Soluções</h4>
              <div class="d-flex flex-column gap-3">
                <a href="#" class="footer-link">Produção & Kanban</a>
                <a href="#" class="footer-link">Compliance Fiscal (Sefaz)</a>
                <a href="#" class="footer-link">Gestão Open Finance</a>
                <a href="/#planos" class="footer-link font-weight-bold text-primary">Planos Iniciais</a>
              </div>
            </v-col>
            <v-col cols="6" md="3">
              <h4 class="font-weight-bold mb-4 text-h6">Ecossistema Tático</h4>
              <div class="d-flex flex-column gap-3">
                <a href="#" class="footer-link">Design Studio & Workflow</a>
                <a href="#" class="footer-link">Impressão e Printing Station</a>
                <a href="#" class="footer-link">Suprimentos e Cotações</a>
                <a href="#" class="footer-link">Documentação API REST</a>
              </div>
            </v-col>
            <v-col cols="12" md="3">
              <h4 class="font-weight-bold mb-4 text-h6">Recursos e Legal</h4>
              <div class="d-flex flex-column gap-3">
                <a href="#" class="footer-link d-flex align-center gap-2">Status da Cloud: <span class="d-flex align-center text-success font-weight-bold"><span class="dot-online mx-1"></span> 99.9% Uptime</span></a>
                <a href="#" class="footer-link">Termos de Serviço Governança</a>
                <a href="/privacidade" class="footer-link text-primary font-weight-bold">Privacidade de Dados (LGPD)</a>
              </div>
            </v-col>
          </v-row>
          <v-divider class="mb-6 opacity-20"></v-divider>
          <div class="text-center text-caption muted-text d-flex align-center justify-center gap-2">
            <v-icon size="16">mdi-shield-check-outline</v-icon>
            &copy; {{ new Date().getFullYear() }} MJ Process Technologies. Construído com arquitetura de ponta no Brasil.
          </div>
        </v-container>
      </footer>

    </div>
  </v-app>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useTheme } from 'vuetify';

// Assets Globais (Idêntico ao Landing.vue)
import LogoDark from '@/assets/logo.png';
import LogoLight from '@/assets/logomjlm.png';

const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const isScrolled = ref(false);

const currentLogo = computed(() => isDark.value ? LogoDark : LogoLight);

const toggleTheme = () => {
  theme.global.name.value = isDark.value ? 'light' : 'dark';
};

const handleScroll = () => {
  isScrolled.value = window.scrollY > 50;
};

// ==========================================
// MÁQUINA DE ESTADO DE LOGIN (BOOT SEQUENCE)
// IDÊNTICO AO LANDING PARA O BOTÃO DO HEADER FUNCIONAR
// ==========================================
const isBooting = ref(false);
const bootProgress = ref(0);
const bootText = ref('Iniciando handshake seguro...');

const initiateBootSequence = () => {
  isBooting.value = true;
  bootProgress.value = 0;

  setTimeout(() => { bootProgress.value = 30; bootText.value = 'Validando certificados RLS...'; }, 500);
  setTimeout(() => { bootProgress.value = 75; bootText.value = 'Carregando Workspace Enterprise...'; }, 1200);
  setTimeout(() => {
    bootProgress.value = 100; bootText.value = 'Conectado. Redirecionando...';
    setTimeout(() => { window.location.href = '/login'; }, 400);
  }, 1800);
};

// ==========================================
// LIFECYCLE
// ==========================================
onMounted(() => {
  window.addEventListener('scroll', handleScroll);
  // Garante que a página comece no topo
  window.scrollTo(0, 0);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
});
</script>

<style scoped>
/* =========================================================
   1. ROOT VARIABLES & THEMES (Mantidos do Landing)
========================================================= */
.mj-landing-wrapper {
  --transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  font-family: system-ui, -apple-system, sans-serif;
  background-color: var(--bg-main);
  color: var(--text-main);
  min-height: 100vh;
  transition: background-color 0.4s ease, color 0.4s ease;
}

/* TEMA DARK */
.theme-dark {
  --bg-main: #09090b;
  --bg-alternate: #0f0f13;
  --bg-header: rgba(9, 9, 11, 0.85);
  --bg-card: rgba(255, 255, 255, 0.03);
  --bg-surface: #18181b;
  --border-card: rgba(255, 255, 255, 0.08);
  --text-main: #ffffff;
  --text-muted: #a1a1aa;
  --border-light: rgba(255,255,255,0.1);
  --bg-primary-lighten: rgba(var(--v-theme-primary), 0.1);
  --gradient-text: linear-gradient(135deg, #a855f7 0%, #3b82f6 100%);
  --shadow-card: 0 8px 32px 0 rgba(0, 0, 0, 0.4);
  --backdrop-blur: blur(24px);
}

/* TEMA LIGHT */
.theme-light {
  --bg-main: #f8fafc;
  --bg-alternate: #ffffff;
  --bg-header: rgba(255, 255, 255, 0.9);
  --bg-card: #ffffff;
  --bg-surface: #ffffff;
  --border-card: #e2e8f0;
  --text-main: #0f172a;
  --text-muted: #64748b;
  --border-light: rgba(0,0,0,0.1);
  --bg-primary-lighten: rgba(var(--v-theme-primary), 0.05);
  --gradient-text: linear-gradient(135deg, #2563eb 0%, #0f172a 100%);
  --shadow-card: 0 10px 30px -5px rgba(0, 0, 0, 0.05);
  --backdrop-blur: blur(12px);
}

/* Utilitários Básicos */
a { text-decoration: none; color: inherit; }
.gradient-text { background: var(--gradient-text); -webkit-background-clip: text; color: transparent; }
.muted-text { color: var(--text-muted) !important; }
.bg-alternate { background-color: var(--bg-alternate); }
.bg-surface { background-color: var(--bg-surface); }
.border-b { border-bottom: 1px solid var(--border-light); }
.border-t { border-top: 1px solid var(--border-light); }
.border { border: 1px solid var(--border-card); }
.opacity-20 { opacity: 0.2; }
.max-w-800 { max-width: 800px; margin: 0 auto; }
.max-w-1000 { max-width: 1000px; margin: 0 auto; }
.gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.line-height-relaxed { line-height: 1.7 !important; }
.section-padding { padding: 120px 0; }

/* =========================================================
   2. BOOT SEQUENCE (Mantido do Landing)
========================================================= */
.enterprise-boot-screen {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: var(--bg-main); z-index: 9999;
  display: flex; align-items: center; justify-content: center;
}
.boot-content { display: flex; flex-direction: column; align-items: center; gap: 24px; width: 300px; }
.boot-logo { height: 48px; filter: drop-shadow(0 0 10px rgba(var(--v-theme-primary), 0.5)); }
.pulse-anim { animation: smoothPulse 2s infinite ease-in-out; }
.boot-loader-container { width: 100%; height: 4px; background: rgba(var(--v-theme-primary), 0.1); border-radius: 4px; overflow: hidden; }
.boot-loader-bar { height: 100%; background: rgb(var(--v-theme-primary)); transition: width 0.4s cubic-bezier(0.16, 1, 0.3, 1); box-shadow: 0 0 10px rgb(var(--v-theme-primary)); }
.boot-text { font-size: 0.85rem; color: var(--text-muted); letter-spacing: 0.05em; text-transform: uppercase; }
@keyframes smoothPulse { 0%, 100% { opacity: 0.7; transform: scale(0.98); } 50% { opacity: 1; transform: scale(1); } }
.fade-boot-enter-active, .fade-boot-leave-active { transition: opacity 0.6s ease; }
.fade-boot-enter-from, .fade-boot-leave-to { opacity: 0; }

/* =========================================================
   3. HEADER (Mantido Exatamente Igual)
========================================================= */
.glass-header {
  position: fixed; top: 0; left: 0; width: 100%; height: 80px; z-index: 100;
  display: flex; align-items: center; transition: var(--transition); border-bottom: 1px solid transparent;
}
.glass-header.scrolled {
  background: var(--bg-header);
  backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur);
  border-bottom: 1px solid var(--border-card);
}
.header-content { display: flex; align-items: center; justify-content: space-between; width: 100%; max-width: 1200px; margin: 0 auto; padding: 0 24px; }
.logo { cursor: pointer; height: 36px; }
.desktop-nav { display: none; gap: 32px; font-weight: 600; font-size: 0.95rem; }
.desktop-nav a { color: var(--text-muted); transition: var(--transition); }
.desktop-nav a:hover { color: rgb(var(--v-theme-primary)); }
.header-actions { display: flex; align-items: center; gap: 16px; }
.webmail-link { font-weight: 700; display: none; }
@media(min-width: 960px) { .desktop-nav { display: flex; } .webmail-link { display: block; } }

/* =========================================================
   4. CONTEÚDO DE PRIVACIDADE E ESTILOS ESPECÍFICOS
========================================================= */
.privacy-main { position: relative; min-height: 80vh; }
.ambient-clouds {
  position: absolute; top: -20%; left: -20%; width: 140%; height: 140%;
  background: radial-gradient(circle at 50% 20%, rgba(var(--v-theme-primary), 0.05), transparent 40%);
  filter: blur(60px); z-index: 0; pointer-events: none;
}
.badge-premium { display: inline-block; padding: 6px 16px; border-radius: 20px; background: rgba(var(--v-theme-primary), 0.1); color: rgb(var(--v-theme-primary)); font-weight: 800; font-size: 0.85rem; letter-spacing: 0.1em; text-transform: uppercase; border: 1px solid rgba(var(--v-theme-primary), 0.2); }
.colossal-title-small { font-size: clamp(2.5rem, 6vw, 4rem); font-weight: 900; line-height: 1.1; letter-spacing: -0.04em; }
.hero-subtitle { font-size: 1.25rem; color: var(--text-muted); max-width: 800px; text-align: center; line-height: 1.6; }

.mj-card {
  background: var(--bg-card); border: 1px solid var(--border-card); border-radius: 24px;
  box-shadow: var(--shadow-card); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur);
  position: relative;
}

.privacy-list { padding-left: 24px; line-height: 1.7; }
.privacy-list li { margin-bottom: 12px; }
.privacy-list li strong { color: var(--text-main); }

/* =========================================================
   5. FOOTER (Mantido Exatamente Igual)
========================================================= */
.footer-link { font-weight: 500; color: var(--text-muted); transition: color 0.2s; }
.footer-link:hover { color: rgb(var(--v-theme-primary)); }
.dot-online { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: rgb(var(--v-theme-success)); box-shadow: 0 0 8px rgb(var(--v-theme-success)); }
</style>
