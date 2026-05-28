<template>
  <div class="governance-wrapper">
    <v-dialog
      v-model="showTerms"
      :persistent="isMandatory"
      max-width="1100"
      scrollable
      transition="dialog-transition"
      class="glass-dialog-container"
    >
      <v-card class="governance-glass-card rounded-xl d-flex flex-column overflow-hidden">

        <div class="glass-noise"></div>
        <div class="glass-gradient"></div>

        <v-toolbar color="transparent" density="comfortable" class="border-b-glass px-5 pt-2" height="70">
          <div class="d-flex align-center">
            <div class="glass-icon-box mr-4">
              <v-icon color="blue-accent-2" size="24">mdi-shield-account-outline</v-icon>
            </div>
            <div>
              <div class="text-subtitle-1 font-weight-bold text-white lh-1 tracking-wide">GOVERNANÇA CORPORATIVA</div>
              <div class="text-caption text-blue-grey-lighten-3 font-mono mt-1">
                SESSION: <span class="text-white">{{ sessionId }}</span>
              </div>
            </div>
          </div>

          <v-spacer></v-spacer>

          <div class="d-none d-md-flex align-center gap-3">
            <div class="meta-glass-chip" title="Endereço IP Público Detectado">
              <v-icon start size="14" color="green-accent-3">mdi-access-point-network</v-icon>
              <span class="font-mono text-caption">{{ clientIP }}</span>
            </div>

            <div class="meta-glass-chip" title="Sistema Operacional Detectado">
              <v-icon start size="14" color="light-blue-accent-3">mdi-laptop</v-icon>
              <span class="font-mono text-caption">{{ clientOS }}</span>
            </div>

            <div class="monitor-badge">
              <span class="pulsing-dot"></span>
              AUDITADO
            </div>
          </div>

          <v-btn v-if="!isMandatory" icon variant="text" class="ml-4 close-btn" @click="showTerms = false">
            <v-icon color="white">mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <div class="d-flex flex-grow-1 overflow-hidden position-relative z-index-2">

          <div class="governance-sidebar border-r-glass">
            <div class="pa-5">
              <span class="text-overline text-blue-grey-lighten-3 font-weight-black tracking-wider">ÍNDICE</span>
            </div>
            <v-list density="compact" bg-color="transparent" class="px-3 custom-scrollbar overflow-y-auto" style="max-height: calc(100vh - 250px);">
              <v-list-item
                v-for="(section, i) in termsSections"
                :key="i"
                :value="section.id"
                rounded="lg"
                class="mb-2 glass-list-item"
                :class="{ 'active-glass-item': activeSection === section.id }"
                @click="scrollTo(section.id)"
              >
                <template v-slot:prepend>
                  <v-icon :color="activeSection === section.id ? 'white' : section.color" size="small" class="mr-3 opacity-80">{{ section.icon }}</v-icon>
                </template>
                <v-list-item-title class="font-weight-medium text-caption text-white" style="white-space: normal; line-height: 1.2;">{{ section.title }}</v-list-item-title>
              </v-list-item>
            </v-list>

            <div class="mt-auto pa-5">
              <div class="doc-meta-box">
                <div class="text-caption text-grey-lighten-1">Revisão Jurídica</div>
                <div class="font-weight-bold text-white mt-1">Novembro 2025</div>
                <div class="text-caption text-blue-accent-1 mt-1 font-mono">REV-3.0-ENT</div>
              </div>
            </div>
          </div>

          <main id="terms-content" class="flex-grow-1 overflow-y-auto pa-8 custom-scrollbar" @scroll="checkScroll">
            <v-container max-width="800" class="mx-auto pt-4">

              <div class="text-center mb-10 fade-in">
                <div class="glass-avatar mx-auto mb-4">
                  <v-icon size="32" color="white">mdi-file-certificate</v-icon>
                </div>
                <h2 class="text-h4 font-weight-black text-white mb-2 text-shadow">Termos de Serviço</h2>
                <p class="text-blue-grey-lighten-2">Diretrizes de segurança, uso aceitável e responsabilidade operacional.</p>
              </div>

              <div v-for="section in termsSections" :key="section.id" :id="section.id" class="mb-12 section-block">
                <div class="d-flex align-center mb-4">
                  <v-icon :color="section.color" class="mr-3 glass-glow-icon">{{ section.icon }}</v-icon>
                  <h3 class="text-h6 font-weight-bold text-white">{{ section.title }}</h3>
                </div>

                <div class="glass-content-box pa-6 rounded-xl">
                  <div class="text-body-2 text-grey-lighten-2 content-html" v-html="section.content"></div>
                </div>
              </div>

              <div class="py-8 text-center opacity-50">
                <v-icon class="mb-2" size="small" color="white">mdi-check-decagram-outline</v-icon>
                <div class="text-caption text-white">Fim do Documento</div>
              </div>

            </v-container>
          </main>
        </div>

        <div class="glass-footer border-t-glass px-6 py-4 d-flex align-center justify-space-between">
          <div class="d-flex flex-column" v-if="isMandatory">
            <span class="text-caption text-blue-grey-lighten-3 font-weight-bold ml-1">PROGRESSO DE LEITURA</span>
            <div class="progress-track mt-1">
              <div class="progress-bar" :style="{ width: scrollPercentage + '%' }"></div>
            </div>
          </div>
          <div v-else>
             <span class="text-caption text-grey">Modo de Visualização</span>
          </div>

          <div v-if="isMandatory" class="d-flex align-center gap-4">
            <v-btn
              variant="text"
              color="red-lighten-2"
              class="text-caption font-weight-bold"
              @click="handleDecline"
            >
              RECUSAR ACESSO
            </v-btn>

            <div class="action-wrapper d-flex align-center bg-black-20 rounded-pill pl-4 pr-1 py-1 border-glass-thin">
              <v-checkbox-btn
                v-model="agreedToTerms"
                color="blue-accent-3"
                density="compact"
                :disabled="!hasReadBottom"
                class="mr-2"
              ></v-checkbox-btn>
              <span class="text-caption text-white mr-4 cursor-pointer" @click="hasReadBottom ? agreedToTerms = !agreedToTerms : null">
                Li e concordo
              </span>

              <v-tooltip :text="!hasReadBottom ? 'Leia todo o documento para desbloquear' : 'Confirmar e Acessar'">
                <template v-slot:activator="{ props }">
                  <div v-bind="props">
                    <v-btn
                      color="blue-accent-3"
                      class="glass-confirm-btn"
                      rounded="pill"
                      :disabled="!agreedToTerms || !hasReadBottom"
                      :loading="userStore.isAcceptingTerms"
                      @click="handleAccept"
                    >
                      <v-icon start icon="mdi-fingerprint"></v-icon>
                      ACEITAR
                    </v-btn>
                  </div>
                </template>
              </v-tooltip>
            </div>
          </div>
          <v-btn v-else variant="outlined" class="glass-outline-btn" color="white" @click="showTerms = false">Fechar</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showPrivacy" max-width="900" scrollable transition="slide-y-reverse-transition">
      <v-card class="privacy-glass-card rounded-xl overflow-hidden d-flex flex-column">
        <div class="glass-noise"></div>

        <div class="card-header-glass pa-6 d-flex align-center justify-space-between flex-shrink-0">
          <div class="d-flex align-center">
             <div class="glass-icon-box-green mr-4">
                <v-icon color="green-accent-3">mdi-shield-lock</v-icon>
             </div>
             <div>
                <div class="text-overline text-green-accent-2 mb-0 lh-1">DADOS & LGPD</div>
                <h3 class="text-h5 font-weight-bold text-white">Política de Privacidade e Uso de Dados</h3>
             </div>
          </div>
          <v-btn icon variant="text" @click="showPrivacy = false"><v-icon color="white">mdi-close</v-icon></v-btn>
        </div>

        <v-card-text class="pa-0 flex-grow-1 overflow-y-auto custom-scrollbar position-relative z-index-2">

          <div class="pa-8">
            <div class="glass-alert mb-8">
              <v-icon color="green-accent-3" class="mr-3" size="28">mdi-information-outline</v-icon>
              <div class="text-body-2 text-white">
                <strong>Transparência Operacional:</strong> Este documento detalha minuciosamente quais dados coletamos, como processamos suas credenciais externas (Google/Microsoft) e nosso compromisso com o sigilo industrial e a LGPD (Lei nº 13.709/2018).
              </div>
            </div>

            <div v-for="(section, index) in privacySections" :key="index" class="mb-10">
              <h4 class="text-h6 font-weight-bold text-white mb-4 d-flex align-center border-b-glass pb-2">
                <v-icon :color="section.color" size="24" class="mr-3">{{ section.icon }}</v-icon>
                {{ section.title }}
              </h4>
              <div class="text-body-2 text-grey-lighten-2 content-html" style="line-height: 1.7;" v-html="section.content"></div>
            </div>
          </div>

        </v-card-text>

        <div class="pa-4 border-t-glass d-flex justify-end position-relative z-index-2 flex-shrink-0 bg-black-20">
          <v-btn variant="outlined" color="white" class="mr-3 text-none font-weight-bold" @click="showPrivacy = false">Recusar</v-btn>
          <v-btn class="glass-confirm-btn-green px-8 text-none font-weight-bold" @click="showPrivacy = false">Compreendi e Aceito</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useUserStore } from '@/stores/user';
import { useRouter } from 'vue-router';

const userStore = useUserStore();
const router = useRouter();

// --- STATE ---
const showTerms = ref(false);
const showPrivacy = ref(false);
const isMandatory = ref(false);
const agreedToTerms = ref(false);
const hasReadBottom = ref(false);
const scrollPercentage = ref(0);
const activeSection = ref('intro');

// --- METADATA ---
const clientIP = ref('Analisando Rede...');
const clientOS = ref('Identificando Sistema...');
const sessionId = ref(crypto.randomUUID().split('-')[0].toUpperCase());

const detectOS = () => {
  const userAgent = window.navigator.userAgent;
  const platform = window.navigator.platform;
  const macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'];
  const windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'];
  const iosPlatforms = ['iPhone', 'iPad', 'iPod'];
  let os = null;

  if (macosPlatforms.indexOf(platform) !== -1) {
    os = 'macOS (Darwin)';
  } else if (iosPlatforms.indexOf(platform) !== -1) {
    os = 'iOS Mobile';
  } else if (windowsPlatforms.indexOf(platform) !== -1) {
    os = 'Windows NT';
  } else if (/Android/.test(userAgent)) {
    os = 'Android System';
  } else if (!os && /Linux/.test(platform)) {
    os = 'Linux x86_64';
  }

  return os || 'Sistema Desconhecido';
};

// --- CONTEÚDO TERMOS DE USO ---
const termsSections = [
  {
    id: 'intro',
    title: '1. Objeto e Aceitação',
    icon: 'mdi-domain',
    color: 'blue-accent-2',
    content: `
      <p>O presente sistema ERP, doravante denominado <strong>"Plataforma"</strong>, é de propriedade exclusiva e operado para fins de gestão industrial e comercial avançada.</p>
      <p>Ao realizar o login ou utilizar quaisquer serviços, APIs, ferramentas de comunicação (incluindo chats integrados e clientes de e-mail), o USUÁRIO concorda expressamente e sem ressalvas com as regras dispostas neste documento.</p>
      <p>O acesso é concedido sob licença estritamente pessoal, intransferível e revogável a qualquer momento.</p>
    `
  },
  {
    id: 'third-party',
    title: '2. Integrações de Terceiros e APIs (Google e Microsoft)',
    icon: 'mdi-api',
    color: 'amber-accent-2',
    content: `
      <p>A Plataforma permite a vinculação de contas externas, como <strong>Google Workspace (Gmail)</strong> e <strong>Microsoft 365 (Outlook)</strong>, visando centralizar operações comerciais.</p>
      <ul class="glass-list mt-2">
        <li><strong>Consentimento:</strong> O processo de vinculação OAuth 2.0 é estritamente opt-in. A Plataforma só agirá em nome do usuário com permissão explícita concedida nas telas oficiais dos provedores.</li>
        <li><strong>Limites e Abusos:</strong> É expressamente proibido utilizar a Plataforma para envio de SPAM, phishing ou envios em massa (bulk mailing) que violem os termos de serviço originais do provedor (Google/Microsoft).</li>
        <li><strong>Desvinculação:</strong> O usuário tem autonomia para revogar o acesso da Plataforma às suas contas de e-mail a qualquer momento através do painel "Connect Hub" ou pelas configurações de segurança da própria conta Google/Microsoft.</li>
      </ul>
    `
  },
  {
    id: 'monitoring',
    title: '3. Auditoria, SRE e Monitoramento',
    icon: 'mdi-eye-circle',
    color: 'red-accent-2',
    content: `
      <div class="glass-warning-box mb-4">
        <strong>⚠️ AMBIENTE AUDITADO CONTINUAMENTE</strong><br>
        Esta é uma infraestrutura corporativa. Não há expectativa de privacidade sobre os atos realizados dentro do sistema.
      </div>
      <p>Para resguardar a integridade da Plataforma e cumprimento de compliance, operamos com telemetria rigorosa:</p>
      <ul class="glass-list mt-2">
        <li>Geração de logs imutáveis (Audit Trail) associados ao seu ID para qualquer operação de criação, leitura, atualização ou deleção (CRUD).</li>
        <li>Rastreamento de Endereços IP, fingerprints de hardware e histórico de sessão.</li>
        <li>Análise de SRE (Site Reliability Engineering) para medição de produtividade sistêmica.</li>
      </ul>
    `
  },
  {
    id: 'security',
    title: '4. Deveres de Segurança da Informação',
    icon: 'mdi-shield-lock',
    color: 'green-accent-3',
    content: `
      <p>O usuário é o único responsável por manter a confidencialidade de sua senha e token de sessão ativa.</p>
      <p><strong>Configura-se infração gravíssima:</strong></p>
      <ul class="glass-list mt-2">
        <li>O compartilhamento de credenciais com colegas, terceiros ou entidades externas.</li>
        <li>Acesso simultâneo de múltiplos dispositivos com intuito de burlar licenças.</li>
        <li>Tentativas de extração não autorizada de dados (scraping), engenharia reversa ou ataques de negação de serviço.</li>
      </ul>
    `
  },
  {
    id: 'property',
    title: '5. Segredos Comerciais e Confidencialidade',
    icon: 'mdi-copyright',
    color: 'purple-accent-2',
    content: `
      <p>Os dados constantes na Plataforma, incluindo mas não se limitando a: banco de dados de clientes, carteira de pedidos, arquivos de design de estampas de alta resolução, tabelas de preço e estratégias comerciais, configuram <strong>Segredo de Negócio</strong> e são protegidos pela Lei de Propriedade Industrial (Lei 9.279/1996).</p>
      <p>A exportação, cópia não autorizada ou disseminação de tais dados acarretará na rescisão imediata do acesso, além das medidas legais reparatórias, tanto na esfera cível (perdas e danos) quanto criminal.</p>
    `
  },
  {
    id: 'termination',
    title: '6. Assinatura e Registro Digital',
    icon: 'mdi-file-sign',
    color: 'grey-lighten-1',
    content: `
      <p>Ao selecionar a caixa "Li e concordo" e clicar no botão "ACEITAR", você emite uma assinatura eletrônica com validade jurídica perante as partes.</p>
      <p>Os metadados desta operação (horário UTC, IP e identificador do dispositivo) são registrados de forma permanente nos servidores da Plataforma para fins comprobatórios.</p>
    `
  }
];

// --- CONTEÚDO POLÍTICA DE PRIVACIDADE ---
const privacySections = [
  {
    title: '1. Compromisso com a Privacidade (LGPD)',
    icon: 'mdi-handshake-outline',
    color: 'blue-accent-2',
    content: `
      <p>A proteção dos dados pessoais dos nossos usuários, clientes e parceiros comerciais é um dos pilares da nossa operação.</p>
      <p>Esta Política de Privacidade foi redigida em estrita conformidade com a <strong>Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 - LGPD)</strong>, definindo o modo como coletamos, utilizamos, retemos, transferimos e protegemos as informações fornecidas por você durante a utilização de nosso sistema ERP.</p>
      <p>Ao utilizar o sistema, o Controlador de Dados designa nossa Plataforma como Operadora de Dados para fins processuais e transacionais, limitando nosso uso estritamente ao fornecimento do serviço contratado.</p>
    `
  },
  {
    title: '2. Tratamento e Uso de Dados do Google (Google API Services User Data Policy)',
    icon: 'mdi-google',
    color: 'red-accent-2',
    content: `
      <div class="glass-warning-box mb-4" style="background: rgba(229, 57, 53, 0.1); border-left: 3px solid #E53935; color: white;">
        <strong>Conformidade Estrita com os Requisitos de Uso Limitado (Limited Use)</strong><br>
        O uso e a transferência de informações recebidas de APIs do Google para qualquer outro aplicativo pela nossa Plataforma atenderão estritamente à <a href="https://developers.google.com/terms/api-services-user-data-policy" target="_blank" style="color: #64B5F6;">Política de Dados do Usuário de Serviços de API do Google</a>, incluindo os requisitos de uso restrito.
      </div>
      <p>Quando você opta por vincular a sua conta do <strong>Google Workspace (Gmail)</strong> ao nosso ERP, nós acessamos a sua caixa postal através do protocolo seguro OAuth 2.0. Nosso tratamento destes dados atende aos seguintes preceitos:</p>
      <ul class="glass-list mt-2">
        <li><strong>O que acessamos:</strong> Endereço de e-mail associado, tokens de autenticação temporários (Access Token e Refresh Token), e o conteúdo de leitura e escrita das mensagens de e-mail (Remetente, Destinatário, Assunto, Corpo e Anexos).</li>
        <li><strong>Como utilizamos:</strong> Estes dados são usados <strong>exclusivamente</strong> para prover ao usuário a funcionalidade de um cliente de e-mail interno ao ERP, permitindo que você leia, organize, responda e vincule e-mails às negociações e pedidos cadastrados no sistema.</li>
        <li><strong>Armazenamento:</strong> <strong>Não armazenamos o conteúdo físico dos seus e-mails</strong> em nossos bancos de dados de forma definitiva, agindo primariamente como um visualizador (proxy) entre a API do Google e a sua tela. Apenas referências aos IDs das mensagens e os tokens de autenticação cifrados são retidos no banco de dados para manter a conexão.</li>
        <li><strong>Não Compartilhamento:</strong> Sob nenhuma hipótese os dados provindos da API do Google, conteúdos de e-mail, ou padrões de comunicação são compartilhados com terceiros, vendidos, licenciados ou utilizados para treinar modelos de inteligência artificial ou servir publicidade direcionada.</li>
      </ul>
    `
  },
  {
    title: '3. Coleta de Metadados e Telemetria',
    icon: 'mdi-database-search-outline',
    color: 'teal-accent-3',
    content: `
      <p>Para assegurar a integridade técnica, prevenir fraudes e auditar a segurança do ambiente corporativo, a Plataforma coleta passivamente as seguintes informações em cada requisição (login, visualização e gravação de dados):</p>
      <ul class="glass-list mt-2">
        <li>Endereço IP (Internet Protocol) e informações do ISP (Provedor de Serviços de Internet).</li>
        <li>Identificação do Agente de Usuário (Navegador e Sistema Operacional).</li>
        <li>Registros de Data e Hora exatos (Timestamps UTC) das interações com módulos sensíveis (Painel Financeiro, Design, SRE, Configurações).</li>
      </ul>
      <p>Estes dados são anonimizados quando possível, restritos ao time de auditoria de segurança (Super Admins) e expurgados do banco de dados analítico de acordo com nosso cronograma de retenção (tipicamente mantidos por 12 meses para fins forenses).</p>
    `
  },
  {
    title: '4. Direitos do Titular dos Dados',
    icon: 'mdi-account-key',
    color: 'amber-accent-3',
    content: `
      <p>Na condição de titular de dados (como pessoa física associada à credencial), você detém direitos inalienáveis perante a LGPD, incluindo:</p>
      <ul class="glass-list mt-2">
        <li><strong>Acesso e Retificação:</strong> Direito de solicitar acesso às informações cadastradas (como seu Perfil de Usuário) e corrigir dados desatualizados.</li>
        <li><strong>Revogação de Acesso e Anonimização:</strong> Você tem total autonomia para desvincular contas externas (Ex: Google) do sistema a qualquer momento pelo Hub de Conexões. Em caso de desligamento da Plataforma, seus dados operacionais poderão ser anonimizados, preservando o histórico da empresa, mas desassociando sua identidade civil do ato.</li>
      </ul>
      <p>Solicitações relacionadas à privacidade ou requisições de esquecimento (Right to be Forgotten) devem ser direcionadas ao DPO (Encarregado de Proteção de Dados) da organização contratante da Plataforma.</p>
    `
  }
];

// --- MÉTODOS ---

const openTerms = () => {
  isMandatory.value = false;
  showTerms.value = true;
  setTimeout(() => { hasReadBottom.value = true; scrollPercentage.value = 100; }, 200);
};

const openPrivacy = () => {
  showPrivacy.value = true;
};

const scrollTo = (id: string) => {
  activeSection.value = id;
  const el = document.getElementById(id);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
};

const checkScroll = (e: Event) => {
  const target = e.target as HTMLElement;
  const scrollHeight = target.scrollHeight - target.clientHeight;
  const scrollTop = target.scrollTop;

  const percentage = Math.min((scrollTop / scrollHeight) * 100, 100);
  scrollPercentage.value = percentage;

  if (scrollHeight - scrollTop <= 150) {
    hasReadBottom.value = true;
  }

  termsSections.forEach(section => {
    const el = document.getElementById(section.id);
    if(el && el.getBoundingClientRect().top < 250) {
      activeSection.value = section.id;
    }
  });
};

const handleAccept = async () => {
  if (!agreedToTerms.value) return;
  await userStore.acceptTerms();
};

const handleDecline = async () => {
  if (confirm('Recusar os termos impedirá seu acesso ao sistema. Deseja continuar e retornar à tela de login?')) {
    await userStore.signOut();
    router.push({ name: 'Login' });
  }
};

onMounted(async () => {
  clientOS.value = detectOS();
  try {
    const response = await fetch('https://api.ipify.org?format=json');
    if (response.ok) {
      const data = await response.json();
      clientIP.value = data.ip;
    } else {
      clientIP.value = 'IP Oculto/VPN';
    }
  } catch (e) {
    clientIP.value = 'Rede Local Detectada';
  }
});

watch(() => userStore.showTermsModal, (val) => {
  if (val) {
    isMandatory.value = true;
    showTerms.value = true;
    agreedToTerms.value = false;
    hasReadBottom.value = false;
    scrollPercentage.value = 0;
  } else if (isMandatory.value) {
    showTerms.value = false;
    isMandatory.value = false;
  }
}, { immediate: true });

defineExpose({ openTerms, openPrivacy });
</script>

<style scoped lang="scss">
/* --- BASE GLASS STYLES --- */
.governance-glass-card {
  background: rgba(20, 20, 25, 0.9); /* Escurecido para melhor legibilidade de textos grandes */
  backdrop-filter: blur(40px) saturate(180%);
  -webkit-backdrop-filter: blur(40px) saturate(180%);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 40px 100px rgba(0, 0, 0, 0.8);
  position: relative;
  height: 90vh;
}

/* Texture Noise */
.glass-noise {
  position: absolute; top:0; left:0; right:0; bottom:0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)' opacity='0.04'/%3E%3C/svg%3E");
  pointer-events: none; z-index: 0;
}

.glass-gradient {
  position: absolute; top:0; left:0; width:100%; height:100%;
  background: radial-gradient(circle at top left, rgba(41, 98, 255, 0.05), transparent 40%),
              radial-gradient(circle at bottom right, rgba(255, 255, 255, 0.02), transparent 40%);
  pointer-events: none; z-index: 0;
}

/* --- HEADER --- */
.border-b-glass { border-bottom: 1px solid rgba(255, 255, 255, 0.08); }
.glass-icon-box {
  width: 42px; height: 42px; border-radius: 12px;
  background: rgba(255,255,255,0.05); display: flex; align-items: center; justify-content: center;
  border: 1px solid rgba(255,255,255,0.1);
}

/* Metadata Chips */
.meta-glass-chip {
  background: rgba(0, 0, 0, 0.4); border: 1px solid rgba(255, 255, 255, 0.05);
  padding: 6px 14px; border-radius: 50px; color: #B0BEC5;
  display: flex; align-items: center; gap: 8px;
}

.monitor-badge {
  background: rgba(255, 143, 0, 0.15); border: 1px solid rgba(255, 143, 0, 0.4);
  color: #FFB74D; font-size: 0.65rem; font-weight: bold; letter-spacing: 1px;
  padding: 6px 12px; border-radius: 6px; display: flex; align-items: center; gap: 8px;
}
.pulsing-dot {
  width: 8px; height: 8px; background: #FFB74D; border-radius: 50%;
  animation: pulse 1.5s infinite;
}
@keyframes pulse { 0% { opacity: 1; box-shadow: 0 0 5px #FFB74D; } 50% { opacity: 0.3; box-shadow: 0 0 0px #FFB74D;} 100% { opacity: 1; box-shadow: 0 0 5px #FFB74D;} }

/* --- SIDEBAR --- */
.governance-sidebar {
  width: 280px; flex-shrink: 0;
  border-right: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(0, 0, 0, 0.3);
}
.glass-list-item {
  transition: 0.2s; color: rgba(255,255,255,0.6);
  &:hover { background: rgba(255,255,255,0.05); color: white; }
}
.active-glass-item {
  background: rgba(41, 121, 255, 0.15) !important;
  border: 1px solid rgba(41, 121, 255, 0.3);
  color: white !important;
}
.doc-meta-box {
  background: rgba(255,255,255,0.03); border-radius: 12px; padding: 16px;
  border: 1px solid rgba(255,255,255,0.05); text-align: center;
}

/* --- MAIN CONTENT --- */
.custom-scrollbar::-webkit-scrollbar { width: 8px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(0,0,0,0.1); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.15); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.3); }

.glass-avatar {
  width: 80px; height: 80px; border-radius: 50%;
  background: linear-gradient(135deg, rgba(33, 150, 243, 0.2), rgba(33, 150, 243, 0.05));
  border: 1px solid rgba(255,255,255,0.1); box-shadow: 0 0 30px rgba(33,150,243,0.15);
  display: flex; align-items: center; justify-content: center;
}
.text-shadow { text-shadow: 0 4px 20px rgba(0,0,0,0.5); }

.glass-content-box {
  background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.05);
  transition: all 0.3s ease;
  &:hover { background: rgba(255,255,255,0.05); border-color: rgba(255,255,255,0.1); }
}
.glass-glow-icon { filter: drop-shadow(0 0 8px currentColor); }

/* HTML Content Styling - Refined for Legal Documents */
.content-html :deep(p) { margin-bottom: 18px; line-height: 1.7; font-size: 15px; }
.content-html :deep(strong) { color: #ffffff; font-weight: 700; }
.content-html :deep(ul.glass-list) { list-style: none; padding: 0; margin-top: 12px; margin-bottom: 16px; }
.content-html :deep(li) {
  padding-left: 24px; position: relative; margin-bottom: 12px; color: #CFD8DC; font-size: 14px; line-height: 1.6;
}
.content-html :deep(li::before) {
  content: "•"; color: #2979FF; position: absolute; left: 0; font-weight: bold; font-size: 18px; line-height: 1;
}
.content-html :deep(a) { color: #64B5F6; text-decoration: none; border-bottom: 1px dotted rgba(100, 181, 246, 0.5); transition: border-bottom-color 0.2s;}
.content-html :deep(a:hover) { border-bottom-color: #64B5F6; }

.glass-warning-box {
  background: rgba(255, 82, 82, 0.1); border-left: 3px solid #FF5252;
  padding: 16px; border-radius: 0 8px 8px 0; color: #FFCDD2;
}

/* --- FOOTER --- */
.border-t-glass { border-top: 1px solid rgba(255, 255, 255, 0.08); background: rgba(0,0,0,0.4); }
.progress-track {
  width: 200px; height: 6px; background: rgba(255,255,255,0.1); border-radius: 3px; overflow: hidden;
}
.progress-bar { height: 100%; background: #2979FF; transition: width 0.3s; box-shadow: 0 0 10px rgba(41, 121, 255, 0.8);}

.bg-black-20 { background: rgba(0,0,0,0.4); }
.border-glass-thin { border: 1px solid rgba(255,255,255,0.15); }

.glass-confirm-btn {
  background: linear-gradient(90deg, #2962FF, #2979FF); color: white;
  box-shadow: 0 4px 15px rgba(41, 98, 255, 0.4); border: none; font-weight: bold;
}
.glass-outline-btn { border-color: rgba(255,255,255,0.2); }

/* --- PRIVACY MODAL SPECIFIC (REDESIGNED FOR TEXT) --- */
.privacy-glass-card {
  background: rgba(15, 20, 25, 0.95);
  backdrop-filter: blur(40px); border: 1px solid rgba(76, 175, 80, 0.3);
  box-shadow: 0 30px 80px rgba(0,0,0,0.9);
  height: 85vh; /* Ocupa boa parte da tela para leitura */
}
.card-header-glass {
  background: linear-gradient(90deg, rgba(76, 175, 80, 0.15), transparent);
  border-bottom: 1px solid rgba(255,255,255,0.08);
}
.glass-icon-box-green {
  width: 52px; height: 52px; border-radius: 14px;
  background: rgba(0, 230, 118, 0.1); border: 1px solid rgba(0, 230, 118, 0.3);
  display: flex; align-items: center; justify-content: center;
}
.glass-alert {
  background: rgba(0, 230, 118, 0.05); border: 1px solid rgba(0, 230, 118, 0.2);
  border-radius: 12px; padding: 20px; display: flex; align-items: start;
}
.glass-confirm-btn-green {
  background: #00C853; color: white; border-radius: 8px;
}

/* Responsividade */
@media (max-width: 900px) {
  .governance-sidebar { display: none; }
  .governance-glass-card { height: 100vh; max-width: 100% !important; border-radius: 0 !important; }
  .privacy-glass-card { height: 100vh; border-radius: 0 !important; border: none; }
}
</style>
