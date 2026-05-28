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
            <div class="badge-premium mb-6">Governança, Legal e Compliance</div>
            <h1 class="colossal-title-small mb-6">Política de Privacidade <br><span class="gradient-text">e Proteção de Dados</span></h1>
            <p class="hero-subtitle mx-auto">
              Diretrizes exaustivas de processamento, retenção, inteligência artificial, monitoramento corporativo e segurança da informação da plataforma MJ Process Technologies.
            </p>
            <div class="mt-4 text-caption muted-text font-weight-bold">
              Última atualização: {{ new Date().toLocaleDateString('pt-BR') }}
            </div>
          </v-container>
        </section>

        <section class="privacy-content pb-16">
          <v-container class="max-w-1200">
            <v-row>
              <v-col cols="12" md="3" class="d-none d-md-block position-relative">
                <div class="sticky-sidebar pa-5 mj-card rounded-xl">
                  <h3 class="text-subtitle-1 font-weight-black mb-4 text-primary text-uppercase" style="letter-spacing: 0.1em;">Sumário Executivo</h3>
                  <nav class="toc-nav">
                    <a href="#introducao" class="toc-link">1. Introdução e Papéis Legais</a>
                    <a href="#dados-coletados" class="toc-link">2. Categoria de Dados Coletados</a>
                    <a href="#uso-dados" class="toc-link">3. Como Usamos as Informações</a>
                    <a href="#google-workspace" class="toc-link">4. Ecossistema Google e E-mails</a>
                    <a href="#ia-labelstudio" class="toc-link">5. Inteligência Artificial e Modelagem</a>
                    <a href="#monitoramento-rh" class="toc-link">6. Monitoramento, Extensões e RH</a>
                    <a href="#sefaz-gov" class="toc-link">7. Transmissões Fiscais (Sefaz)</a>
                    <a href="#open-finance" class="toc-link">8. Open Finance e Pagamentos</a>
                    <a href="#ecommerce-b2c" class="toc-link">9. E-commerce e Operações B2C</a>
                    <a href="#frota-telemetria" class="toc-link">10. Gestão de Frota e Rastreamento</a>
                    <a href="#cookies-rastreio" class="toc-link">11. Cookies e Tecnologias de Rastreio</a>
                    <a href="#armazenamento-rls" class="toc-link">12. Armazenamento, R2 e Segurança RLS</a>
                    <a href="#direitos-titular" class="toc-link">13. Direitos do Titular (LGPD)</a>
                    <v-divider class="my-3 opacity-20"></v-divider>
                    <a href="#faq" class="toc-link font-weight-bold">Dúvidas Frequentes (FAQ)</a>
                    <a href="#dpo-contato" class="toc-link font-weight-bold text-primary mt-2">Contato com o DPO</a>
                  </nav>
                </div>
              </v-col>

              <v-col cols="12" md="9">
                <div class="mj-card privacy-document pa-6 pa-md-12 text-justify">

                  <div id="introducao" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">1. Introdução e Definição de Papéis Legais</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Esta Política de Privacidade descreve de forma exaustiva como a <strong>MJ Process Technologies</strong> (o "Sistema", "Plataforma", "nós", "nosso") coleta, processa, utiliza, retém e divulga informações pessoais e corporativas quando você utiliza nossa infraestrutura de Planejamento de Recursos Empresariais (ERP), ecossistema tático, loja virtual, aplicativos móveis e extensões de navegador (coletivamente, os "Serviços").
                    </p>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Para fins de conformidade com a <strong>Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018)</strong>, estabelecemos uma distinção crucial em nossos papéis:
                    </p>
                    <ul class="privacy-list text-body-1 muted-text mb-4">
                      <li><strong>Como Operadora (Ambiente B2B):</strong> Quando sua empresa contrata nosso ERP para gerenciar seus próprios funcionários, fornecedores e carteira de clientes, a sua empresa atua como <em>Controladora</em>. A MJ Process atua estritamente como <em>Operadora</em>, processando os dados alocados na nuvem sob suas ordens, não utilizando os dados dos seus clientes para proveito próprio.</li>
                      <li><strong>Como Controladora (Ambiente B2C e Contratual):</strong> Quando você, como representante legal, assina nosso contrato, ou quando um cliente final navega em nosso ecossistema de Marketplace/Vitrine pública provido pela MJ Process, nós assumimos o papel de <em>Controladores</em> dos dados de navegação, telemetria e dados cadastrais da sua empresa.</li>
                    </ul>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      Ao acessar, autenticar-se ou utilizar qualquer módulo dos Serviços, você concorda expressamente com as práticas estipuladas neste documento. Caso discorde, o uso do sistema deve ser imediatamente descontinuado.
                    </p>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="dados-coletados" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">2. Categoria e Natureza dos Dados Coletados</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A arquitetura da plataforma exige a coleta de diferentes vetores de dados para garantir o funcionamento técnico e a segurança da informação. Coletamos informações de três fontes principais:
                    </p>
                    <h3 class="text-h6 font-weight-bold mb-3 mt-6 text-primary">A. Informações Fornecidas Diretamente por Você (Tenant e Usuários)</h3>
                    <ul class="privacy-list text-body-1 muted-text mb-4">
                      <li><strong>Dados Cadastrais e Societários:</strong> Razão Social, CNPJ, Inscrição Estadual, endereços físicos, e-mails de faturamento, telefones de contato corporativo e Certificados Digitais (A1/A3) necessários para emissão de documentos fiscais.</li>
                      <li><strong>Dados de Colaboradores (Contas de Acesso):</strong> Nome completo, CPF, e-mail corporativo, cargo, departamento, dados de biometria facial/digital (quando aplicável via quiosque de ponto) e senhas criptografadas por <em>hashing</em> unidirecional (Bcrypt/Argon2).</li>
                      <li><strong>Dados Operacionais Inseridos:</strong> Informações de terceiros (seus clientes e fornecedores) que você cadastra no módulo de CRM, compras ou produção, incluindo endereços de entrega, histórico de consumo e limites de crédito.</li>
                    </ul>

                    <h3 class="text-h6 font-weight-bold mb-3 mt-6 text-primary">B. Informações Coletadas Automaticamente (Telemetria e Uso)</h3>
                    <ul class="privacy-list text-body-1 muted-text mb-4">
                      <li><strong>Identificadores de Dispositivo e Rede:</strong> Endereços IP (Internet Protocol), provedor de serviços de internet (ISP), tipo de navegador, sistema operacional, <em>User-Agent</em> e MAC Address (em dispositivos dedicados de chão de fábrica).</li>
                      <li><strong>Trilhas de Auditoria (Audit Logs):</strong> Registramos timestamps (data e hora exatas) de criação, leitura, atualização e exclusão (CRUD) de qualquer registro crítico no sistema. Rastreamento de quais telas foram visitadas e o tempo de permanência.</li>
                      <li><strong>Dados de Presença (Extensão de Navegador):</strong> Interações com o mouse, foco em abas do navegador e status de ociosidade, coletados via extensão proprietária para módulos de produtividade.</li>
                    </ul>

                    <h3 class="text-h6 font-weight-bold mb-3 mt-6 text-primary">C. Informações Obtidas de Terceiros</h3>
                    <p class="text-body-1 muted-text line-height-relaxed">
                      Poderemos enriquecer nossos bancos de dados com informações oriundas de APIs governamentais (ex: consulta automática de CNPJ na Receita Federal), bureaus de crédito integrados pelo cliente, ou provedores de Open Finance (ex: extratos bancários integrados via Banco Cora ou similares).
                    </p>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="uso-dados" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">3. Como Utilizamos Suas Informações</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A retenção e o processamento dos dados coletados possuem finalidades estritamente vinculadas à prestação do serviço contratado, respaldadas nas bases legais do <strong>Cumprimento de Contrato</strong>, <strong>Obrigação Legal</strong> e <strong>Legítimo Interesse</strong>.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Prestação dos Serviços (Core Business):</strong> Processar pedidos de vendas, despachar ordens de produção (PCP), emitir faturas, gerar relatórios de DRE e manter a estabilidade do fluxo de caixa.</li>
                      <li><strong>Prevenção a Fraudes e Segurança:</strong> O monitoramento de IPs e trilhas de auditoria são vitais para detectar acessos não autorizados, tentativas de força bruta (Brute Force) e vazamentos internos de informações industriais da sua empresa.</li>
                      <li><strong>Aprimoramento Contínuo:</strong> Dados de uso anonimizados (ex: quais módulos são mais clicados) são utilizados para otimização de UX/UI e alocação de recursos em nossos servidores (Load Balancing).</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="google-workspace" class="document-section mb-12 scroll-mt google-highlight-section pa-8 rounded-xl border">
                    <div class="d-flex align-center gap-4 mb-8">
                      <v-avatar color="white" size="56" class="elevation-3" style="padding: 10px;">
                        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
                      </v-avatar>
                      <div>
                        <div class="text-overline text-primary font-weight-black mb-1">Integração Homologada</div>
                        <h2 class="text-h5 font-weight-black mb-0">4. Ecossistema Google, SSO e API de E-mails</h2>
                      </div>
                    </div>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A arquitetura da MJ Process integra-se profundamente ao Google Workspace para prover autenticação de nível militar e comunicações oficiais. O uso das APIs do Google obedece estritamente à <a href="https://developers.google.com/terms/api-services-user-data-policy" target="_blank" class="text-primary text-decoration-underline">Política de Dados de Usuários de Serviços de API do Google</a>, incluindo os requisitos de <em>Uso Limitado</em>.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Single Sign-On (OAuth 2.0):</strong> Solicitamos apenas os escopos <code>openid</code>, <code>email</code> e <code>profile</code>. Armazenamos exclusivamente seu endereço de e-mail e nome. Não temos acesso à sua senha do Google.</li>
                      <li><strong>Gmail API (Proxy de Saída):</strong> Para que o ERP dispare cotações, faturas e links de boletos em nome da sua empresa, utilizamos escopos de envio (send). A MJ Process atua como um conduíte passivo. O corpo do e-mail é montado em memória, disparado pela API do Google e <strong>não é armazenado em texto plano</strong> em nossos servidores, retendo-se apenas o log de status de entrega.</li>
                      <li><strong>Edge Functions de Inbound (Leitura Restrita):</strong> Processos de automação que exigem leitura de caixas de entrada (ex: captura automática de XMLs de fornecedores) utilizam algoritmos de <em>parsing</em> automatizado. <strong>Garantimos o Sigilo de Correspondência:</strong> Nenhum funcionário humano da MJ Process visualiza o conteúdo dos seus e-mails recebidos. Os dados extraídos são injetados diretamente nas tabelas de compras do seu Tenant.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="ia-labelstudio" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">5. Inteligência Artificial e Treinamento de Modelos (LLM/Vision)</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Para elevar a eficiência operacional, o ERP emprega ferramentas de IA Generativa (como integrações com a API da OpenAI) e ferramentas de anotação de dados computacionais (como o Label Studio).
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Política Zero Data Retention (APIs Externas):</strong> Quando dados textuais ou imagens do seu fluxo de trabalho são enviados para provedores de LLM (ex: para sugerir respostas ou categorizar produtos), utilizamos estritamente contas de nível <em>Corporate/API</em>. Seus dados corporativos <strong>NÃO são utilizados para treinar modelos de fundação públicos</strong> da OpenAI ou de terceiros. Eles são descartados pelo provedor após o retorno da inferência.</li>
                      <li><strong>Anotação Interna (Label Studio):</strong> Ocasionalmente, administradores do seu Tenant podem utilizar o módulo interno de Label Studio para rotular imagens (ex: estampas, defeitos de maquinário) a fim de treinar algoritmos locais pertencentes unicamente à sua instância. Esses dados são governados pelo mesmo isolamento RLS descrito na Seção 12.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="monitoramento-rh" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">6. Monitoramento Laboral, Quiosque de Ponto e Extensões</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A plataforma engloba módulos de Recursos Humanos voltados à gestão de produtividade. É imperativo que as entidades corporativas (Controladoras) informem seus colaboradores sobre a existência destas métricas, amparadas pelo <strong>Poder Diretivo do Empregador (Art. 2º da CLT)</strong>.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Extensão Presence & Time Tracking:</strong> O sistema pode monitorar o estado da janela do navegador, capturar eventos de teclado/mouse (para medir ociosidade, não para capturar o que é digitado - <em>no keylogging</em>) e tabular horas efetivamente trabalhadas.</li>
                      <li><strong>Controle de Ponto (Kiosk):</strong> A captura de fotografias, geolocalização e endereços IP no momento da batida de ponto são armazenadas para validar a autenticidade da jornada de trabalho, em conformidade com as portarias do Ministério do Trabalho e Emprego (MTE).</li>
                      <li><strong>Comunicações Internas:</strong> O chat interno do sistema é uma ferramenta estritamente profissional. <strong>Não há expectativa de privacidade</strong> nas mensagens trocadas entre os colaboradores dentro da plataforma. Administradores com permissão de auditoria podem exportar transcrições em casos de investigações internas de compliance.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="sefaz-gov" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">7. Transmissões Governamentais e Módulo Fiscal</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      A MJ Process atua como emissora de documentos fiscais eletrônicos (NFe, NFCe, CTe, MDFe).
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Guarda de Certificados Digitais:</strong> Seus certificados A1 são armazenados em nossos bancos de dados em formato criptografado binário. O sistema automatiza a assinatura dos XMLs.</li>
                      <li><strong>Compartilhamento Compulsório:</strong> Dados de faturamento, impostos, informações dos seus clientes (Nomes, CPFs, Endereços) são compulsoriamente transmitidos, em tempo real, para as bases de dados das <strong>Secretarias de Fazenda Estaduais (Sefaz)</strong> e da Receita Federal do Brasil.</li>
                      <li><strong>Guarda Legal CTN:</strong> Somos obrigados a reter os arquivos XMLs autorizados e cancelados pelo prazo prescricional de 5 (cinco) anos, conforme dita o Código Tributário Nacional, independentemente de solicitações de exclusão do titular.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <v-row class="mb-12">
                    <v-col cols="12" md="6">
                      <div id="open-finance" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="success" size="36" class="mb-4">mdi-bank-transfer</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">8. Open Finance e Bancos</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          Para módulos de conciliação bancária (ex: Banco Cora) e emissão de boletos/Pix, o tráfego de dados (chaves API, extratos, CNABs) ocorre via túneis TLS criptografados. Nós não retemos saldo bancário ou senhas de internet banking. A integração submete-se às regulamentações de segurança cibernética e Open Finance do <strong>Banco Central do Brasil (Bacen)</strong>.
                        </p>
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <div id="ecommerce-b2c" class="document-section h-100 scroll-mt bg-surface border rounded-xl pa-6">
                        <v-icon color="primary" size="36" class="mb-4">mdi-storefront</v-icon>
                        <h3 class="text-h5 font-weight-black mb-3">9. E-commerce e B2C</h3>
                        <p class="text-body-2 muted-text mb-0 line-height-relaxed">
                          Quando o cliente final acessa a vitrine online, nós atuamos como Controladores dos dados de navegação. Transações de cartão seguem rigorosamente a certificação <strong>PCI-DSS</strong>; não armazenamos CVV ou dados plásticos em nosso banco (Tokenização direta com a adquirente).
                        </p>
                      </div>
                    </v-col>
                  </v-row>

                  <div id="frota-telemetria" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">10. Gestão de Frota e Rastreamento Logístico</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      O módulo de frota (Vehicle Management e Refueling) realiza o processamento de dados inerentes à operação logística, o que constitui tratamento de dados pessoais dos motoristas envolvidos:
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li>Dados de Carteira Nacional de Habilitação (CNH), histórico de infrações e multas de trânsito.</li>
                      <li>Geolocalização, rotas de entrega e telemetria de abastecimento e quilometragem. Tais dados são vitais para a segurança patrimonial da Controladora e apuração de custos.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="cookies-rastreio" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">11. Cookies e Tecnologias de Rastreamento (Web Beacons)</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Aplica-se aos Serviços e aos domínios públicos (Landing Pages e Storefront). Utilizamos pequenos arquivos de texto denominados "Cookies" para operar o sistema.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Cookies Estritamente Necessários:</strong> Fundamentais para a manutenção da sessão de login (Tokens JWT), preservação do carrinho de compras e defesa contra ataques de falsificação de solicitações entre sites (CSRF). <em>Não podem ser desativados sem quebrar o sistema.</em></li>
                      <li><strong>Cookies de Desempenho e Analítica:</strong> Ferramentas analíticas que processam dados anonimizados de navegação para identificar gargalos de usabilidade no design da interface.</li>
                      <li><strong>Web Beacons / Pixels:</strong> E-mails enviados pelo ERP podem conter pixels invisíveis para registrar taxas de abertura (Read Receipts), permitindo que sua equipe de vendas saiba se o destinatário visualizou a cotação comercial.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="armazenamento-rls" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">12. Infraestrutura, Segurança RLS e Retenção R2</h2>
                    <p class="text-body-1 muted-text mb-4 line-height-relaxed">
                      Não operamos servidores locais precários. Toda a infraestrutura está alocada em Data Centers Tier III ou superior (AWS / Cloudflare), com certificações ISO 27001 e SOC 2 Tipo II.
                    </p>
                    <ul class="privacy-list text-body-1 muted-text">
                      <li><strong>Isolamento Multi-Tenant via RLS:</strong> O núcleo do nosso banco de dados relacional utiliza o PostgreSQL com <em>Row Level Security</em> (Segurança em Nível de Linha). Isso significa que as consultas ao banco são filtradas a nível de hardware e driver. É criptograficamente impossível que um Tenant acesse o espaço de memória ou os dados industriais de outro Tenant concorrente.</li>
                      <li><strong>Armazenamento Descentralizado (Cloudflare R2):</strong> Arquivos pesados, estampas, plantas industriais e comprovantes de pagamento (Pix) contendo dados sensíveis são arquivados em <em>Object Storage</em>, garantindo redundância geográfica e links assinados temporários que expiram em minutos.</li>
                      <li><strong>Protocolo de Desligamento (Wipe):</strong> Em caso de rescisão contratual, o Tenant entra em modo <em>Read-Only</em> por 30 dias para exportação de dados. Transcorrido o prazo, iniciamos um processo automatizado de exclusão definitiva (<em>Wipe</em>) das tabelas e <em>buckets</em>, tornando impossível a recuperação dos dados, restando apenas metadados fiscalmente obrigatórios. Backups de rotina (PITR) são sobrepostos e destruídos num ciclo contínuo de retenção de curto prazo.</li>
                    </ul>
                  </div>

                  <v-divider class="opacity-20 mb-12"></v-divider>

                  <div id="direitos-titular" class="document-section mb-12 scroll-mt">
                    <h2 class="text-h4 font-weight-black mb-6">13. Seus Direitos como Titular (Art. 18 LGPD)</h2>
                    <p class="text-body-1 muted-text mb-6 line-height-relaxed">
                      A legislação garante a você, seja como usuário do ERP ou consumidor final no e-commerce, o controle sobre seus dados. O cumprimento desses direitos pode sofrer ressalvas nos casos de necessidade de cumprimento de obrigações legais, conforme o Art. 16 da LGPD.
                    </p>
                    <div class="bg-surface border rounded-lg pa-6">
                      <ul class="privacy-list text-body-1 muted-text mb-0">
                        <li><strong>Direito de Confirmação e Acesso:</strong> Obter um relatório estruturado informando quais categorias de dados possuímos sobre você em nossos clusters.</li>
                        <li><strong>Direito de Retificação:</strong> Corrigir dados desatualizados ou incorretos (que frequentemente pode ser feito diretamente no painel de perfil do ERP).</li>
                        <li><strong>Direito à Portabilidade:</strong> Exportar as tabelas estruturais de clientes e produtos via CSV, JSON ou através de nossa API RESTFul.</li>
                        <li><strong>Direito à Exclusão / Anonimização:</strong> Solicitar a eliminação de dados tratados com base no consentimento. <em>Nota: Colaboradores da empresa Controladora não podem exigir a exclusão de seus registros de ponto ou auditoria de operações.</em></li>
                        <li><strong>Revogação de Consentimento:</strong> Desvincular integrações de terceiros (como o login do Google) a qualquer momento pelo portal do provedor original.</li>
                      </ul>
                    </div>
                  </div>

                  <v-divider class="opacity-20 mb-16"></v-divider>

                  <div id="faq" class="document-section mb-16 scroll-mt">
                    <h2 class="colossal-title-small text-h3 font-weight-black mb-8 text-center">Dúvidas Frequentes (FAQ)</h2>
                    <v-expansion-panels variant="accordion" class="custom-panels">
                      <v-expansion-panel class="bg-surface border mb-3 rounded-lg">
                        <v-expansion-panel-title class="font-weight-bold text-h6 py-4">A MJ Process vende ou monetiza a base de dados da minha empresa?</v-expansion-panel-title>
                        <v-expansion-panel-text class="text-body-1 muted-text line-height-relaxed pt-2 pb-4">
                          <strong>Categoricamente e contratualmente, NÃO.</strong> Nosso modelo de negócio é exclusivamente focado no licenciamento e manutenção do software (SaaS). Seu mailing corporativo, carteira de clientes, fornecedores e segredos industriais de produção pertencem exclusivamente a você.
                        </v-expansion-panel-text>
                      </v-expansion-panel>

                      <v-expansion-panel class="bg-surface border mb-3 rounded-lg">
                        <v-expansion-panel-title class="font-weight-bold text-h6 py-4">Houve um vazamento na minha empresa. De quem é a culpa legal?</v-expansion-panel-title>
                        <v-expansion-panel-text class="text-body-1 muted-text line-height-relaxed pt-2 pb-4">
                          Como <em>Operadora</em>, a MJ Process responsabiliza-se por falhas estruturais nos servidores e vulnerabilidades de código (Zero-Day, injeções SQL). No entanto, se um administrador do seu Tenant utilizar senhas fracas, não ativar a Autenticação Multifator (MFA), ou se um funcionário vazar planilhas exportadas intencionalmente, a responsabilidade civil e administrativa recai sobre a sua empresa, que atua como <em>Controladora</em>.
                        </v-expansion-panel-text>
                      </v-expansion-panel>

                      <v-expansion-panel class="bg-surface border mb-3 rounded-lg">
                        <v-expansion-panel-title class="font-weight-bold text-h6 py-4">Meus e-mails estão seguros com o Proxy do Gmail?</v-expansion-panel-title>
                        <v-expansion-panel-text class="text-body-1 muted-text line-height-relaxed pt-2 pb-4">
                          Sim. A permissão solicitada ao seu Google Workspace limita-se a permitir que nossos servidores montem a mensagem técnica e entreguem ao Google para despacho. Nós não clonamos sua caixa de saída e possuímos rotinas de No-Read garantindo que o algoritmo apenas identifique retornos sistêmicos de erro (bounces) para os dashboards de faturamento.
                        </v-expansion-panel-text>
                      </v-expansion-panel>
                    </v-expansion-panels>
                  </div>

                  <div id="dpo-contato" class="document-section bg-alternate border rounded-xl pa-6 pa-md-10 mt-16 scroll-mt position-relative overflow-hidden">
                    <div class="dpo-glow position-absolute"></div>
                    <div class="position-relative z-1">
                      <div class="text-center mb-8">
                        <v-avatar color="primary" variant="tonal" size="64" class="mb-4">
                          <v-icon size="32">mdi-gavel</v-icon>
                        </v-avatar>
                        <h3 class="text-h4 font-weight-black mb-3">Portal do Titular e DPO</h3>
                        <p class="text-body-1 muted-text mx-auto max-w-800">
                          O Data Protection Officer (DPO / Encarregado de Dados) é responsável pela conformidade legal. Para denúncias, auditorias ou exercício dos direitos do Art. 18, envie sua solicitação. O canal oficial e direto é <strong class="text-main">suporte@estudiodeestampamj.com</strong>.
                        </p>
                      </div>

                      <v-form @submit.prevent="submitDpoForm" class="dpo-form mx-auto max-w-800" ref="formRef">
                        <v-row>
                          <v-col cols="12" md="6">
                            <v-text-field v-model="dpoForm.nome" label="Nome Completo" variant="outlined" bg-color="var(--bg-surface)" color="primary" required :rules="[v => !!v || 'Campo obrigatório']" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field v-model="dpoForm.empresa" label="Empresa (Razão Social ou CNPJ)" variant="outlined" bg-color="var(--bg-surface)" color="primary" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12">
                            <v-text-field v-model="dpoForm.email" label="E-mail Corporativo ou de Cadastro" type="email" variant="outlined" bg-color="var(--bg-surface)" color="primary" required :rules="[v => !!v || 'E-mail obrigatório', v => /.+@.+\..+/.test(v) || 'E-mail inválido']" hide-details="auto"></v-text-field>
                          </v-col>
                          <v-col cols="12">
                            <v-textarea v-model="dpoForm.mensagem" label="Fundamente sua solicitação com detalhes jurídicos ou operacionais" variant="outlined" bg-color="var(--bg-surface)" color="primary" rows="5" required :rules="[v => !!v || 'A mensagem é obrigatória']" hide-details="auto"></v-textarea>
                          </v-col>
                          <v-col cols="12" class="text-center mt-4">
                            <v-btn type="submit" color="primary" size="x-large" variant="flat" class="submit-btn px-12" :loading="isSubmitting" :disabled="formSuccess">
                              {{ formSuccess ? 'Processo de Abertura Realizado' : 'Solicitar Atendimento Oficial' }}
                              <v-icon right class="ml-2" v-if="!formSuccess">mdi-send-lock</v-icon>
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
                <a href="/terms" class="footer-link">Termos de Serviço de Licença</a>
                <a href="/privacy" class="footer-link text-primary font-weight-bold">Política de Privacidade (LGPD)</a>
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
const dpoForm = ref({ nome: '', empresa: '', email: '', mensagem: '' });

const submitDpoForm = async () => {
  const { valid } = await formRef.value.validate();
  if (!valid) return;

  isSubmitting.value = true;

  setTimeout(() => {
    isSubmitting.value = false;
    formSuccess.value = true;

    const subject = encodeURIComponent(`Solicitação Oficial DPO/LGPD - ${dpoForm.value.nome} (${dpoForm.value.empresa})`);
    const body = encodeURIComponent(`Notificação Legal e de Conformidade\n\nRemetente: ${dpoForm.value.nome}\nEmail: ${dpoForm.value.email}\nEmpresa: ${dpoForm.value.empresa}\n\nMensagem/Solicitação:\n${dpoForm.value.mensagem}\n\n[Mensagem gerada via Portal de Governança MJ Process]`);
    window.location.href = `mailto:suporte@estudiodeestampamj.com?subject=${subject}&body=${body}`;

    setTimeout(() => {
      formSuccess.value = false;
      dpoForm.value = { nome: '', empresa: '', email: '', mensagem: '' };
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

/* FAQ CUSTOMIZATION */
.custom-panels :deep(.v-expansion-panel-title) { font-family: inherit !important; color: var(--text-main); }
.custom-panels :deep(.v-expansion-panel-text__wrapper) { padding: 0 24px 24px 24px !important; text-align: justify; line-height: 1.7; }

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
