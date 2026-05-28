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
        <div class="side-decorator cyber-grid-left"></div>
        <div class="side-decorator cyber-grid-right"></div>
        <div class="ambient-clouds"></div>

        <section class="privacy-hero pt-16 pb-8">
          <v-container class="position-relative z-1 max-w-1000 mt-16 text-center">
            <div class="badge-premium mb-6">Contrato de Licenciamento de Software (SaaS)</div>
            <h1 class="colossal-title-small mb-6">Termos de Serviço <br><span class="gradient-text">e Governança</span></h1>
            <p class="hero-subtitle mx-auto">
              Acordo de Nível de Serviço (SLA), Propriedade Intelectual, isenções de responsabilidade civil e regras de uso da plataforma corporativa MJ Process Technologies.
            </p>
            <div class="mt-4 text-caption muted-text font-weight-bold">
              Versão do Documento: 3.1.4 | Última atualização: {{ new Date().toLocaleDateString('pt-BR') }}
            </div>
          </v-container>
        </section>

        <section class="privacy-content pb-16">
          <v-container class="max-w-1200">
            <v-row>
              <v-col cols="12" md="3" class="d-none d-md-block position-relative">
                <div class="sticky-sidebar pa-5 mj-card rounded-xl">
                  <h3 class="text-subtitle-1 font-weight-black mb-4 text-primary text-uppercase" style="letter-spacing: 0.1em;">Estrutura Contratual</h3>
                  <nav class="toc-nav">
                    <a href="#objeto" class="toc-link">1. Objeto do Contrato</a>
                    <a href="#licenca-pi" class="toc-link">2. Licença e Propriedade Intelectual</a>
                    <a href="#acesso-seguranca" class="toc-link">3. Credenciais e Segurança (MFA)</a>
                    <a href="#sla-uptime" class="toc-link">4. SLA, Uptime e Manutenção</a>
                    <a href="#modulo-fiscal" class="toc-link">5. Operações Fiscais (Sefaz)</a>
                    <a href="#open-finance" class="toc-link">6. Open Finance e Integrações</a>
                    <a href="#ecommerce-b2c" class="toc-link">7. Marketplace e Consumidor Final</a>
                    <a href="#rh-frota" class="toc-link">8. Módulos de RH e Frota</a>
                    <a href="#ia-terceiros" class="toc-link">9. IA e Serviços de Terceiros</a>
                    <a href="#suspensao-wipe" class="toc-link">10. Rescisão e Wipe Criptográfico</a>
                    <a href="#limitacao-responsabilidade" class="toc-link">11. Limitação de Responsabilidade</a>
                    <a href="#foro" class="toc-link">12. Disposições Gerais e Foro</a>
                    <v-divider class="my-3 opacity-20"></v-divider>
                    <a href="#legal-contato" class="toc-link font-weight-bold text-primary">Assessoria Jurídica</a>
                  </nav>
                </div>
              </v-col>

              <v-col cols="12" md="9">
                <div class="mj-card privacy-document pa-6 pa-md-12 text-justify">

                  <div id="objeto" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">1. Objeto do Contrato e Aceite Legal</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Este instrumento constitui um acordo legal e vinculativo entre a <strong>MJ Process Technologies</strong> ("Licenciante", "Nós") e a <strong>Pessoa Jurídica ou Física Contratante</strong> ("Licenciada", "Cliente", "Tenant"). O objeto destes Termos é a concessão de licença de uso temporária, revogável, não exclusiva e intransferível do ecossistema de software ERP em nuvem (SaaS - <em>Software as a Service</em>), módulos operacionais, loja virtual e aplicativos vinculados.
                    </p>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      A concordância com estes Termos consolida-se automaticamente no ato de criação do <em>Workspace</em> (Tenant), no pagamento da primeira mensalidade ou no acesso às credenciais de administrador. <strong>O uso contínuo da plataforma implica em submissão integral a estas cláusulas.</strong>
                    </p>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="licenca-pi" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">2. Propriedade Intelectual e Proteção de Código</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A arquitetura, código-fonte (Vue.js, TypeScript), lógicas de banco de dados (Supabase/PostgreSQL), algoritmos de Edge Functions, design de interface (UI/UX), marcas, logotipos e <em>know-how</em> embarcados na MJ Process são de <strong>propriedade exclusiva e inalienável da Licenciante</strong>, protegidos pela Lei de Direitos Autorais (Lei nº 9.610/98) e Lei de Software (Lei nº 9.609/98).
                    </p>
                    <div class="bg-surface pa-5 rounded-lg border mb-4">
                      <h4 class="font-weight-bold text-error mb-2"><v-icon color="error" class="mr-2">mdi-gavel</v-icon> Vedações Estritas (Proibições)</h4>
                      <p class="text-body-2 muted-text mb-0">
                        É expressamente proibido à Licenciada e seus colaboradores: realizar engenharia reversa, descompilação, cópia de telas (scraping/clonagem), comercialização sublicenciada (white-label não autorizado), ou utilização do sistema para construir um produto concorrente. A violação desta cláusula enseja rescisão imediata e multa contratual punitiva, sem prejuízo de apuração de perdas e danos.
                      </p>
                    </div>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      <strong>Dados do Cliente:</strong> Toda a informação inserida no sistema pela Licenciada (produtos, clientes, finanças, arquivos R2) é de propriedade exclusiva da Licenciada. A MJ Process não adquire nenhum direito de propriedade sobre as suas operações industriais ou de vendas.
                    </p>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="acesso-seguranca" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">3. Credenciais, Acessos e Responsabilidade Administrativa</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      O acesso ao ambiente corporativo exige autenticação. A Licenciada é a única responsável pelas contas de seus colaboradores (usuários finais).
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Gestão de Permissões:</strong> O Administrador do Tenant deve configurar corretamente os níveis de acesso (RLS e Políticas UI) para cada funcionário. Não nos responsabilizamos por exclusão ou vazamento de dados causado por funcionários da Licenciada com permissões inadequadas.</li>
                      <li><strong>Credenciais e MFA:</strong> O sigilo de senhas ou a segurança das contas Google (no uso do SSO) são de inteira responsabilidade do usuário. A MJ Process exime-se de qualquer responsabilidade por invasões decorrentes de engenharia social, <em>phishing</em> ou senhas fracas oriundas dos terminais físicos da Licenciada.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="sla-uptime" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">4. SLA (Service Level Agreement), Uptime e Manutenção</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Esforçamo-nos para garantir uma disponibilidade de arquitetura de nuvem (Supabase/AWS/Cloudflare) de <strong>99.5% de Uptime anual</strong>.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Manutenções Programadas:</strong> Atualizações de banco de dados, <em>deploy</em> de novas <em>features</em> ou correções estruturais serão preferencialmente realizadas fora do horário de pico comercial (período noturno/madrugada) e comunicadas no painel <em>System Cockpit</em>.</li>
                      <li><strong>Força Maior e Exclusões de SLA:</strong> Interrupções decorrentes de falhas globais da AWS, quedas dos servidores governamentais (Sefaz), ataques massivos de DDoS em provedores de backbone, pandemias ou atos governamentais configuram eventos de <em>Força Maior</em>, não ensejando multas, descontos ou responsabilidade civil por lucros cessantes da Licenciada.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <v-row class="mb-12">
                    <v-col cols="12" md="6">
                      <div id="modulo-fiscal" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="warning" size="36" class="mb-4">mdi-bank</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">5. Obrigações Fiscais (Sefaz)</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          O módulo de emissão fiscal atua estritamente como transmissor de dados mensageiros (XML). A MJ Process <strong>não audita e não é responsável legal, fiscal ou tributariamente</strong> pelas informações digitadas pelo usuário (alíquotas, NCM, CFOP, CST). Qualquer autuação fiscal decorrente de parametrização errônea no ERP é de culpa exclusiva da Licenciada junto à Receita Federal e Sefaz.
                        </p>
                      </div>
                    </v-col>

                    <v-col cols="12" md="6">
                      <div id="open-finance" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="success" size="36" class="mb-4">mdi-finance</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">6. Open Finance e Bancos</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          As automações bancárias (ex: emissão via Banco Cora) dependem da estabilidade das APIs bancárias terceirizadas (Bacen). A MJ Process exime-se de obrigações em caso de falha sistêmica do Banco recebedor, atrasos na liquidação de Pix/Boletos, ou juros cobrados por divergências nas remessas/retornos (CNAB).
                        </p>
                      </div>
                    </v-col>

                    <v-col cols="12" md="6" class="mt-4 mt-md-0">
                      <div id="ecommerce-b2c" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="primary" size="36" class="mb-4">mdi-shopping-outline</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">7. Marketplace B2C e CDC</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          Ao operar vitrines B2C pelo nosso sistema, a Licenciada é a fornecedora legal frente ao consumidor. A MJ Process atua apenas como plataforma de software neutra. Todo e qualquer litígio fundamentado no <strong>Código de Defesa do Consumidor (CDC)</strong> — atraso em entregas, estornos de cartão (Chargeback), qualidade do produto — é de responsabilidade integral, exclusiva e inafastável da Licenciada.
                        </p>
                      </div>
                    </v-col>

                    <v-col cols="12" md="6" class="mt-4 mt-md-0">
                      <div id="rh-frota" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="info" size="36" class="mb-4">mdi-account-hard-hat</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">8. RH, Frota e CLT</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          Os módulos de <em>Time Kiosk</em>, gestão de frota, telemetria de presença e monitoramento no navegador existem para auxiliar na administração. A Licenciada atesta que comunicou formalmente seus funcionários (e motoristas) sobre as políticas de monitoramento e proteção de dados, isentando a MJ Process de passivos trabalhistas.
                        </p>
                      </div>
                    </v-col>
                  </v-row>

                  <div id="ia-terceiros" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">9. Inteligência Artificial e Serviços Integrados (Terceiros)</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A plataforma utiliza <em>LLMs</em> (Large Language Models, ex: OpenAI), <em>Machine Learning</em> (Label Studio), Gateways de pagamento e integração com o Google Workspace (API do Gmail).
                    </p>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      Estes recursos são fornecidos <strong>"no estado em que se encontram" (As Is)</strong> e <strong>"conforme disponíveis" (As Available)</strong>. Não garantimos a infalibilidade das análises geradas pela Inteligência Artificial. Decisões estratégicas baseadas em relatórios da IA são de risco assumido da Licenciada. A MJ Process reserva-se o direito de alterar, substituir ou descontinuar APIs de terceiros a qualquer momento, sem notificação prévia, caso estas modifiquem suas políticas de uso ou custos.
                    </p>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="suspensao-wipe" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">10. Inadimplência, Rescisão e Expurgo de Dados (Wipe)</h2>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Suspensão por Inadimplência:</strong> Em caso de não pagamento das obrigações da licença SaaS (mensalidade), após 5 (cinco) dias de atraso, o sistema será bloqueado operacionalmente.</li>
                      <li><strong>Rescisão e Extração de Dados:</strong> O contrato pode ser rescindido a qualquer momento. Após o distrato, a Licenciada terá <strong>30 dias corridos</strong> de acesso <em>Read-Only</em> (Apenas Leitura) para exportar seus dados, tabelas, XMLs e relatórios.</li>
                      <li><strong>Wipe Criptográfico:</strong> Transcorrido o período de 30 dias após o cancelamento, a MJ Process reserva-se ao direito (e obrigação) de aplicar rotinas de <em>Wipe</em>, eliminando permanentemente todas as linhas do Tenant dos bancos de dados do Supabase e esvaziando os <em>buckets</em> do Cloudflare R2, isentando-se de qualquer responsabilidade por perda de dados após este prazo.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="limitacao-responsabilidade" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6 text-error">11. Cláusula de Limitação Geral de Responsabilidade</h2>
                    <div class="bg-alternate pa-6 rounded-lg border">
                      <p class="text-body-1 mb-4 line-height-relaxed text-justify">
                        <strong>NO LIMITE MÁXIMO PERMITIDO PELA LEGISLAÇÃO APLICÁVEL</strong>, a MJ Process Technologies, seus diretores, engenheiros e fornecedores <strong>NÃO SERÃO RESPONSÁVEIS</strong> por quaisquer danos indiretos, incidentais, especiais, consequenciais ou punitivos, incluindo, sem limitação, <strong>lucros cessantes, perda de receita, perda de dados, perda de oportunidade de negócio ou danos à reputação</strong>, resultantes de: (I) seu acesso, uso ou incapacidade de usar os Serviços; (II) qualquer conduta ou conteúdo de terceiros ou funcionários da Licenciada no uso da plataforma; (III) acessos não autorizados motivados por negligência local de segurança da Licenciada.
                      </p>
                      <p class="text-body-1 mb-0 line-height-relaxed font-weight-bold">
                        A responsabilidade financeira total da MJ Process em relação a qualquer reivindicação decorrente destes Termos estará sempre estritamente limitada ao montante total efetivamente pago pela Licenciada referente aos últimos 3 (três) meses de mensalidade do Software (SaaS).
                      </p>
                    </div>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="foro" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">12. Disposições Gerais e Foro</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      <strong>Atualizações:</strong> Podemos revisar estes Termos periodicamente. Mudanças materiais serão notificadas via e-mail ou banner de painel. O uso contínuo implica aceitação.
                    </p>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      Estes Termos serão regidos e interpretados de acordo com as Leis da <strong>República Federativa do Brasil</strong>. Fica eleito o Foro da Comarca sede da MJ Process Technologies para dirimir quaisquer dúvidas, litígios ou controvérsias resultantes deste instrumento, com renúncia expressa de qualquer outro, por mais privilegiado que seja.
                    </p>
                  </div>

                  <div id="legal-contato" class="document-section bg-alternate border rounded-xl pa-6 pa-md-10 mt-16 scroll-mt position-relative overflow-hidden">
                    <div class="dpo-glow position-absolute"></div>
                    <div class="position-relative z-1">
                      <div class="text-center mb-8">
                        <v-avatar color="primary" variant="tonal" size="64" class="mb-4">
                          <v-icon size="32">mdi-scale-balance</v-icon>
                        </v-avatar>
                        <h3 class="text-h4 font-weight-black mb-3">Assessoria Jurídica e Contratual</h3>
                        <p class="text-body-1 muted-text mx-auto max-w-800">
                          Para notificações judiciais, renegociação de contratos Enterprise, auditorias de infraestrutura, ou emissão de aditivos contratuais, submeta sua requisição oficial abaixo. As correspondências são direcionadas para <strong>suporte@estudiodeestampamj.com</strong>.
                        </p>
                      </div>

                      <v-form @submit.prevent="submitLegalForm" class="dpo-form mx-auto max-w-800" ref="formRef">
                        <v-row>
                          <v-col cols="12" md="6">
                            <v-text-field v-model="legalForm.nome" label="Nome Completo / Representante" variant="outlined" bg-color="var(--bg-surface)" color="primary" required :rules="[v => !!v || 'Campo obrigatório']" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field v-model="legalForm.cnpj" label="CNPJ da Empresa Contratante" variant="outlined" bg-color="var(--bg-surface)" color="primary" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12">
                            <v-text-field v-model="legalForm.email" label="E-mail Corporativo Autorizado" type="email" variant="outlined" bg-color="var(--bg-surface)" color="primary" required :rules="[v => !!v || 'E-mail obrigatório', v => /.+@.+\..+/.test(v) || 'E-mail inválido']" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12">
                            <v-textarea v-model="legalForm.mensagem" label="Teor da Notificação Administrativa ou Contratual" variant="outlined" bg-color="var(--bg-surface)" color="primary" rows="5" required :rules="[v => !!v || 'A mensagem é obrigatória']" hide-details="auto"></v-textarea>
                          </v-col>
                          <v-col cols="12" class="text-center mt-4">
                            <v-btn type="submit" color="primary" size="x-large" variant="flat" class="submit-btn px-12" :loading="isSubmitting" :disabled="formSuccess">
                              {{ formSuccess ? 'Protocolo Gerado com Sucesso' : 'Protocolar Requisição Jurídica' }}
                              <v-icon right class="ml-2" v-if="!formSuccess">mdi-file-sign</v-icon>
                              <v-icon right class="ml-2" v-else>mdi-check-decagram</v-icon>
                            </v-btn>
                          </v-col>
                        </v-row>
                      </v-form>
                    </div>
                  </div>

                </div>
              </v-col>
            </v-row>
          </v-container>
        </section>
      </main>

      <footer class="mj-footer pt-16 pb-8 border-t">
        <v-container>
          <v-row class="mb-12">
            <v-col cols="12" md="4" class="pr-md-8">
              <img :src="currentLogo" alt="MJ Process" class="logo mb-6" style="height: 36px;" />
              <p class="text-body-2 muted-text mb-6 line-height-relaxed">
                O software de gestão proprietário projetado por engenheiros para empresas que exigem excelência técnica, compliance governamental e controle operacional absoluto no Brasil.
              </p>
            </v-col>
            <v-col cols="6" md="2">
              <h4 class="font-weight-bold mb-4 text-h6">Governança</h4>
              <div class="d-flex flex-column gap-3">
                <a href="/#modulos" class="footer-link">SLA & Disponibilidade</a>
                <a href="/#modulos" class="footer-link">Compliance Fiscal</a>
                <a href="/#planos" class="footer-link font-weight-bold text-primary">Assinaturas SaaS</a>
              </div>
            </v-col>
            <v-col cols="6" md="3">
              <h4 class="font-weight-bold mb-4 text-h6">Módulos Críticos</h4>
              <div class="d-flex flex-column gap-3">
                <a href="/#modulos" class="footer-link">Auditoria de Dados (Audit)</a>
                <a href="/#arquitetura" class="footer-link">Infraestrutura em Nuvem</a>
                <a href="/#arquitetura" class="footer-link">Isolamento Multi-Tenant (RLS)</a>
              </div>
            </v-col>
            <v-col cols="12" md="3">
              <h4 class="font-weight-bold mb-4 text-h6">Recursos e Legal</h4>
              <div class="d-flex flex-column gap-3">
                <a href="#" class="footer-link d-flex align-center gap-2">Status: <span class="d-flex align-center text-success font-weight-bold"><span class="dot-online mx-1"></span> AWS / Cloudflare Operantes</span></a>
                <a href="/terms" class="footer-link text-primary font-weight-bold">Termos de Serviço de Licença</a>
                <a href="/privacy" class="footer-link">Política de Privacidade (LGPD)</a>
              </div>
            </v-col>
          </v-row>
          <v-divider class="mb-6 opacity-20"></v-divider>
          <div class="text-center text-caption muted-text d-flex align-center justify-center gap-2 flex-wrap">
            <v-icon size="16">mdi-scale-balance</v-icon>
            &copy; {{ new Date().getFullYear() }} MJ Process Technologies. Todos os direitos reservados.
          </div>
        </v-container>
      </footer>

    </div>
  </v-app>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useTheme } from 'vuetify';

import LogoDark from '@/assets/logo.png';
import LogoLight from '@/assets/logomjlm.png';

const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const isScrolled = ref(false);
const currentLogo = computed(() => isDark.value ? LogoDark : LogoLight);

const toggleTheme = () => { theme.global.name.value = isDark.value ? 'light' : 'dark'; };
const handleScroll = () => { isScrolled.value = window.scrollY > 50; };

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

const formRef = ref<any>(null);
const isSubmitting = ref(false);
const formSuccess = ref(false);
const legalForm = ref({ nome: '', cnpj: '', email: '', mensagem: '' });

const submitLegalForm = async () => {
  const { valid } = await formRef.value.validate();
  if (!valid) return;

  isSubmitting.value = true;

  setTimeout(() => {
    isSubmitting.value = false;
    formSuccess.value = true;

    const subject = encodeURIComponent(`Notificação Legal/Contratual - ${legalForm.value.nome} (${legalForm.value.cnpj})`);
    const body = encodeURIComponent(`Notificação de Serviço SaaS\n\nRepresentante: ${legalForm.value.nome}\nEmail: ${legalForm.value.email}\nCNPJ: ${legalForm.value.cnpj}\n\nTeor da Mensagem:\n${legalForm.value.mensagem}\n\n[Mensagem gerada via Portal de Governança MJ Process]`);
    window.location.href = `mailto:suporte@estudiodeestampamj.com?subject=${subject}&body=${body}`;

    setTimeout(() => {
      formSuccess.value = false;
      legalForm.value = { nome: '', cnpj: '', email: '', mensagem: '' };
      formRef.value.resetValidation();
    }, 6000);

  }, 1800);
};

onMounted(() => {
  window.addEventListener('scroll', handleScroll);
  window.scrollTo(0, 0);
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
});
</script>

<style scoped>
/* ROOT & THEMES */
.mj-landing-wrapper {
  --transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  font-family: system-ui, -apple-system, sans-serif;
  background-color: var(--bg-main);
  color: var(--text-main);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  transition: background-color 0.4s ease, color 0.4s ease;
  scroll-behavior: smooth;
}

.theme-dark {
  --bg-main: #09090b; --bg-alternate: #0f0f13; --bg-header: rgba(9, 9, 11, 0.85);
  --bg-card: rgba(255, 255, 255, 0.02); --bg-surface: #18181b; --border-card: rgba(255, 255, 255, 0.08);
  --text-main: #ffffff; --text-muted: #a1a1aa; --border-light: rgba(255,255,255,0.1);
  --gradient-text: linear-gradient(135deg, #a855f7 0%, #3b82f6 100%);
  --shadow-card: 0 8px 32px 0 rgba(0, 0, 0, 0.4); --backdrop-blur: blur(24px);
  --cyber-grid: rgba(255, 255, 255, 0.03);
}

.theme-light {
  --bg-main: #f8fafc; --bg-alternate: #ffffff; --bg-header: rgba(255, 255, 255, 0.9);
  --bg-card: #ffffff; --bg-surface: #ffffff; --border-card: #e2e8f0;
  --text-main: #0f172a; --text-muted: #64748b; --border-light: rgba(0,0,0,0.1);
  --gradient-text: linear-gradient(135deg, #2563eb 0%, #0f172a 100%);
  --shadow-card: 0 10px 30px -5px rgba(0, 0, 0, 0.05); --backdrop-blur: blur(12px);
  --cyber-grid: rgba(0, 0, 0, 0.03);
}

/* UTILITÁRIOS */
a { text-decoration: none; color: inherit; }
.gradient-text { background: var(--gradient-text); -webkit-background-clip: text; color: transparent; }
.text-main { color: var(--text-main) !important; }
.muted-text { color: var(--text-muted) !important; }
.bg-alternate { background-color: var(--bg-alternate); }
.bg-surface { background-color: var(--bg-surface); }
.border-b { border-bottom: 1px solid var(--border-light); }
.border-t { border-top: 1px solid var(--border-light); }
.border { border: 1px solid var(--border-card); }
.opacity-20 { opacity: 0.2; }
.max-w-800 { max-width: 800px; margin: 0 auto; }
.max-w-1000 { max-width: 1000px; margin: 0 auto; }
.max-w-1200 { max-width: 1200px; margin: 0 auto; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.line-height-relaxed { line-height: 1.8 !important; }
.scroll-mt { scroll-margin-top: 100px; }

/* BOOT SCREEN & HEADER */
.enterprise-boot-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: var(--bg-main); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.boot-content { display: flex; flex-direction: column; align-items: center; gap: 24px; width: 300px; }
.boot-logo { height: 48px; filter: drop-shadow(0 0 10px rgba(var(--v-theme-primary), 0.5)); }
.pulse-anim { animation: smoothPulse 2s infinite ease-in-out; }
.boot-loader-container { width: 100%; height: 4px; background: rgba(var(--v-theme-primary), 0.1); border-radius: 4px; overflow: hidden; }
.boot-loader-bar { height: 100%; background: rgb(var(--v-theme-primary)); transition: width 0.4s; }
.boot-text { font-size: 0.85rem; color: var(--text-muted); text-transform: uppercase; }
@keyframes smoothPulse { 0%, 100% { opacity: 0.7; transform: scale(0.98); } 50% { opacity: 1; transform: scale(1); } }
.fade-boot-enter-active, .fade-boot-leave-active { transition: opacity 0.6s ease; }
.fade-boot-enter-from, .fade-boot-leave-to { opacity: 0; }

.glass-header { position: fixed; top: 0; left: 0; width: 100%; height: 80px; z-index: 100; display: flex; align-items: center; transition: var(--transition); border-bottom: 1px solid transparent; }
.glass-header.scrolled { background: var(--bg-header); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur); border-bottom: 1px solid var(--border-card); }
.header-content { display: flex; align-items: center; justify-content: space-between; width: 100%; max-width: 1200px; margin: 0 auto; padding: 0 24px; }
.logo { cursor: pointer; height: 36px; }
.desktop-nav { display: none; gap: 32px; font-weight: 600; font-size: 0.95rem; }
.desktop-nav a { color: var(--text-muted); transition: var(--transition); }
.desktop-nav a:hover { color: rgb(var(--v-theme-primary)); }
.header-actions { display: flex; align-items: center; gap: 16px; }
.webmail-link { font-weight: 700; display: none; }
@media(min-width: 960px) { .desktop-nav { display: flex; } .webmail-link { display: block; } }

/* SIDEBAR E FUNDO DECORATIVO */
.privacy-main { position: relative; flex-grow: 1; overflow: hidden; }
.side-decorator { position: absolute; top: 0; bottom: 0; width: 25vw; pointer-events: none; z-index: 0; background-size: 40px 40px; background-image: linear-gradient(to right, var(--cyber-grid) 1px, transparent 1px), linear-gradient(to bottom, var(--cyber-grid) 1px, transparent 1px); }
.cyber-grid-left { left: 0; mask-image: linear-gradient(to right, black 0%, transparent 100%); -webkit-mask-image: linear-gradient(to right, black 0%, transparent 100%); }
.cyber-grid-right { right: 0; mask-image: linear-gradient(to left, black 0%, transparent 100%); -webkit-mask-image: linear-gradient(to left, black 0%, transparent 100%); }
.ambient-clouds { position: absolute; top: -10%; left: -20%; width: 140%; height: 100%; background: radial-gradient(circle at 50% 10%, rgba(var(--v-theme-primary), 0.04), transparent 50%); filter: blur(60px); z-index: 0; pointer-events: none; }

.sticky-sidebar { position: sticky; top: 100px; background: var(--bg-card); border: 1px solid var(--border-card); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur); }
.toc-nav { display: flex; flex-direction: column; gap: 12px; }
.toc-link { font-size: 0.85rem; color: var(--text-muted); transition: color 0.2s, transform 0.2s; display: block; line-height: 1.4; }
.toc-link:hover { color: rgb(var(--v-theme-primary)); transform: translateX(5px); }

/* CONTENT & TYPOGRAPHY */
.badge-premium { display: inline-block; padding: 6px 16px; border-radius: 20px; background: rgba(var(--v-theme-primary), 0.1); color: rgb(var(--v-theme-primary)); font-weight: 800; font-size: 0.85rem; letter-spacing: 0.1em; text-transform: uppercase; border: 1px solid rgba(var(--v-theme-primary), 0.2); }
.colossal-title-small { font-size: clamp(2.2rem, 5vw, 3.8rem); font-weight: 900; line-height: 1.1; letter-spacing: -0.04em; }
.hero-subtitle { font-size: 1.15rem; color: var(--text-muted); line-height: 1.6; }

.mj-card { background: var(--bg-card); border: 1px solid var(--border-card); box-shadow: var(--shadow-card); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur); position: relative; z-index: 2; }
.privacy-list { padding-left: 24px; }
.privacy-list li { margin-bottom: 12px; line-height: 1.8; }
.privacy-list li strong { color: var(--text-main); }
.text-justify { text-align: justify; hyphens: auto; }

/* SEÇÕES ESPECIAIS */
.google-highlight-section { background: linear-gradient(145deg, var(--bg-surface) 0%, rgba(var(--v-theme-primary), 0.03) 100%); border: 1px solid rgba(var(--v-theme-primary), 0.2) !important; box-shadow: inset 0 0 30px rgba(var(--v-theme-primary), 0.02); }

/* DPO FORM / LEGAL FORM */
.dpo-glow { top: 50%; left: 50%; transform: translate(-50%, -50%); width: 100%; height: 100%; background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.05) 0%, transparent 70%); filter: blur(40px); z-index: 0; pointer-events: none; }
.submit-btn { text-transform: none; font-weight: 700; letter-spacing: 0.5px; border-radius: 12px; transition: all 0.3s; }
.submit-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 25px -5px rgba(var(--v-theme-primary), 0.4); }

/* FOOTER */
.mj-footer { background: var(--bg-alternate); position: relative; z-index: 2; }
.footer-link { font-weight: 500; color: var(--text-muted); transition: color 0.2s; font-size: 0.95rem; }
.footer-link:hover { color: rgb(var(--v-theme-primary)); }
.dot-online { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: rgb(var(--v-theme-success)); box-shadow: 0 0 8px rgb(var(--v-theme-success)); }

/* RESPONSIVE TWEAKS */
@media(max-width: 959px) {
  .privacy-document { padding: 24px !important; text-align: left; }
  .colossal-title-small { font-size: 2.2rem; }
  .document-section h2 { font-size: 1.8rem !important; }
  .dpo-form { padding: 0 12px; }
}
</style>
