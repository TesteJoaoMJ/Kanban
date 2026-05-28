<template>
  <div :class="['mj-marketplace', isDark ? 'theme-dark' : 'theme-light']">
    <div v-if="isLoading" class="boot-screen">
      <div class="boot-box">
        <img :src="currentLogo" alt="MJ Process" class="boot-logo" />
        <div class="boot-line"></div>
        <p class="boot-text">Sincronizando acervo...</p>
      </div>
    </div>

    <div v-else class="app-shell">
      <transition name="fade" mode="out-in">
        <section class="store-shell">

          <header class="store-header custom-premium-glass border-b border-opacity-10 d-none d-md-flex" :style="settings.maintenance_mode ? 'top: 32px;' : 'top: 0;'">
            <div class="header-inner">
              <div class="header-brand" @click="router.push('/marketplace')" style="cursor: pointer;">
                <img
                  :src="settings.logo_url || currentLogo"
                  alt="Logo"
                  class="brand-logo header-logo"
                  :class="{ 'invert-logo': isDark && !settings.logo_url }"
                />
              </div>

<nav class="header-nav scrollable-nav">
                <button type="button" class="nav-link" :class="{ active: route.path === '/marketplace' }" @click.prevent="console.log('🚨 [HEADER] Indo para INÍCIO. Path atual:', route.path); router.push('/marketplace')">Início</button>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/catalogo') || route.path.includes('/descobrir') }" @click.prevent="console.log('🚨 [HEADER] Indo para CATÁLOGO. hasVipAccess:', hasVipAccess); router.push('/marketplace/catalogo')">
                  <v-icon start size="14" class="mr-1 opacity-70">mdi-lock-outline</v-icon> Catálogo Exclusivo
                </button>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/ficha-tecnica') }" @click.prevent="console.log('🚨 [HEADER] Indo para FICHA TÉCNICA'); router.push('/marketplace/ficha-tecnica')">Ficha Técnica</button>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/estamparia-digital') }" @click.prevent="console.log('🚨 [HEADER] Indo para ESTAMPARIA DIGITAL'); router.push('/marketplace/estamparia-digital')">Estamparia Digital</button>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/corte-a-laser') }" @click.prevent="console.log('🚨 [HEADER] Indo para CORTE LASER'); router.push('/marketplace/corte-a-laser')">Corte a Laser</button>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/canga-promocional') }" @click.prevent="console.log('🚨 [HEADER] Indo para CANGAS'); router.push('/marketplace/canga-promocional')">Cangas Promocionais</button>

                <button v-if="isLoggedIn" type="button" class="nav-link" :class="{ active: route.path.includes('/favoritos') }" @click.prevent="console.log('🚨 [HEADER] Indo para FAVORITOS. isLoggedIn:', isLoggedIn); router.push('/marketplace/favoritos')">Favoritos</button>

                <div class="header-divider d-none d-lg-block mx-2"></div>

                <button type="button" class="nav-link" :class="{ active: route.path.includes('/pilotos') }" @click.prevent="console.log('🚨 [HEADER] Indo para PILOTOS'); router.push('/marketplace/pilotos')">Solicitar Piloto</button>

                <button type="button" class="nav-link premium-vip-btn" @click.prevent="console.log('🚨 [HEADER] Indo para STUDIO VIP'); router.push('/marketplace/desenvolvimento')">
                  <v-icon size="16" class="vip-crown-icon mr-1">mdi-crown</v-icon>
                  <span class="font-weight-bold">Deseja Desenvolver?</span>
                </button>
              </nav>

              <div class="header-actions">
                <v-btn icon variant="tonal" size="small" class="theme-toggle" @click.prevent="console.log('🚨 [HEADER] Trocou Tema'); toggleTheme()">
                  <v-icon>{{ isDark ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
                </v-btn>

                <template v-if="isLoggedIn">
                  <div class="premium-user-pill d-none d-xl-flex" @click.prevent="console.log('🚨 [HEADER] Clicou no Avatar (PERFIL). isLoggedIn:', isLoggedIn); router.push('/marketplace/perfil')" title="Meu Perfil">
                    <div class="user-avatar" :class="{'vip-border': hasVipAccess}">
                      <img v-if="userProfile.avatar_url" :src="userProfile.avatar_url" alt="Avatar" />
                      <span v-else>{{ getUserInitials(userProfile.name) }}</span>
                    </div>
                    <div class="user-info">
                      <span class="user-greeting d-flex align-center gap-1">
                        Olá, {{ userProfile.name?.split(' ')[0] || 'Visitante' }}
                        <v-icon v-if="hasVipAccess" color="warning" size="14" class="vip-glow" title="Acesso VIP Ativo">mdi-crown</v-icon>
                      </span>
                      <span class="user-location"><v-icon size="10" class="mr-1 opacity-70">mdi-map-marker</v-icon>{{ userProfile.location || 'Brasil' }}</span>
                    </div>
                  </div>

                  <div class="header-divider d-none d-lg-block"></div>

                  <button type="button" class="premium-cart-btn" @click.prevent="console.log('🚨 [HEADER] Abriu Carrinho'); moodboardOpen = true">
                    <v-icon size="20" class="cart-icon">mdi-shopping-outline</v-icon>
                    <span class="cart-text">Carrinho</span>
                    <div v-if="moodboard.length" class="premium-cart-badge">
                      <span>{{ moodboard.length }}</span>
                    </div>
                  </button>
                </template>

                <template v-else>
                  <v-btn color="primary" variant="flat" class="text-none px-6 rounded-pill font-weight-bold" @click.prevent="console.log('🚨 [HEADER] Clicou Entrar'); router.push('/marketplace-login')">
                    <v-icon start size="18">mdi-login</v-icon>
                    Entrar
                  </v-btn>
                </template>
              </div>
            </div>
          </header>

          <nav class="mobile-dock d-md-none mj-glass mj-border hide-scrollbar">
            <button type="button" class="dock-btn" :class="{ active: route.path === '/marketplace' }" @click.prevent="console.log('🚨 [DOCK] Indo para INÍCIO'); router.push('/marketplace')">
              <v-icon size="20">mdi-home-outline</v-icon>
              <span>Início</span>
            </button>
            <button type="button" class="dock-btn" :class="{ active: route.path.includes('/marketplace/catalogo') || route.path.includes('/marketplace/descobrir') }" @click.prevent="console.log('🚨 [DOCK] Indo para ACERVO. hasVipAccess:', hasVipAccess); router.push('/marketplace/catalogo')">
              <v-icon size="20">mdi-lock-outline</v-icon>
              <span>Acervo</span>
            </button>

            <template v-if="isLoggedIn">
              <button type="button" class="dock-btn" :class="{ active: route.path.includes('/marketplace/pilotos') }" @click.prevent="console.log('🚨 [DOCK] Indo para PILOTOS'); router.push('/marketplace/pilotos')">
                <v-icon size="20">mdi-flask-outline</v-icon>
                <span>Pilotos</span>
              </button>

              <button type="button" class="dock-btn" :class="{ active: route.path.includes('/marketplace/desenvolvimento') }" @click.prevent="console.log('🚨 [DOCK] Indo para STUDIO'); router.push('/marketplace/desenvolvimento')">
                <v-icon size="20">mdi-crown</v-icon>
                <span>Studio</span>
              </button>

              <button type="button" class="dock-btn" :class="{ active: route.path.includes('/marketplace/favoritos') }" @click.prevent="console.log('🚨 [DOCK] Indo para FAVORITOS'); router.push('/marketplace/favoritos')">
                <v-icon size="20">mdi-heart-multiple-outline</v-icon>
                <span>Favoritos</span>
              </button>

              <button type="button" class="dock-btn" :class="{ active: route.path.includes('/marketplace/perfil') }" @click.prevent="console.log('🚨 [DOCK] Indo para PERFIL. isLoggedIn:', isLoggedIn); router.push('/marketplace/perfil')">
                <v-icon size="20" :color="hasVipAccess ? 'warning' : ''" :class="{'vip-glow': hasVipAccess}">
                  {{ hasVipAccess ? 'mdi-crown' : 'mdi-account-outline' }}
                </v-icon>
                <span :class="{'vip-text-gradient': hasVipAccess}">Perfil</span>
              </button>

              <button type="button" class="dock-btn" @click.prevent="console.log('🚨 [DOCK] Abriu Carrinho'); moodboardOpen = true">
                <v-icon size="20">mdi-palette-swatch-outline</v-icon>
                <span>Carrinho</span>
                <span v-if="moodboard.length" class="mobile-badge">{{ moodboard.length }}</span>
              </button>
            </template>
            <template v-else>
              <button type="button" class="dock-btn" @click.prevent="console.log('🚨 [DOCK] Clicou Entrar (Visitante)'); router.push('/marketplace-login')">
                <v-icon size="20">mdi-login</v-icon>
                <span>Entrar</span>
              </button>
            </template>
          </nav>

          <div v-if="settings.maintenance_mode" class="maintenance-bar">
            <v-icon size="14">mdi-alert</v-icon>
            Loja em manutenção — apenas administradores possuem acesso.
          </div>

<main class="content-scroll">
            <transition name="layout-fade" mode="out-in">

              <!-- 1. BLOQUEIO DE VISITANTE (Rotas restritas para quem não tem conta) -->
              <div v-if="showGuestLock" key="guest-lock" class="premium-lock-view">
                <div class="lock-bg-pattern"></div>
                <v-container class="fill-height d-flex align-center justify-center position-relative z-index-2">
                  <div class="premium-lock-card mj-glass mj-border">
                    <div class="lock-icon-wrapper">
                      <v-icon size="42" class="text-main opacity-80">mdi-account-lock-outline</v-icon>
                    </div>

                    <div class="eyebrow solid mb-4 text-main">Requer Cadastro</div>
                    <h1 class="text-h3 font-weight-black text-main mb-4 lock-title">Faça Login</h1>

                    <p class="text-h6 text-muted mb-10 max-copy font-weight-light">
                      Crie sua conta ou faça login para acessar esta área, gerenciar pedidos, solicitar desenvolvimentos e muito mais.
                    </p>

                    <div class="lock-actions">
                      <v-btn color="primary" size="x-large" class="lock-btn primary-lock-btn rounded-pill" @click="router.push('/marketplace-login')">
                        <v-icon start size="20">mdi-login</v-icon>
                        Entrar ou Cadastrar
                      </v-btn>
                    </div>
                  </div>
                </v-container>
              </div>

<!-- 2. BLOQUEIO VIP (Logado, tentando acessar catálogo VIP sem a Chave) -->
              <div v-else-if="showVipLock" key="vip-lock" class="premium-lock-view">
                <div class="lock-bg-pattern"></div>

                <v-container class="lock-container px-4 px-md-8">
                  <div class="vip-split-layout">

                    <!-- LADO ESQUERDO: SHOWCASE "DIV ELEGANTE" -->
                    <div class="vip-showcase-wrapper mj-surface mj-border">
                      <div class="showcase-content">
                        <div class="vip-eyebrow mb-6">
                          <v-icon size="14" class="mr-2" color="warning">mdi-crown</v-icon> Propriedade Intelectual
                        </div>

                        <h2 class="showcase-title text-main mb-4">Arte para<br>marcas exigentes.</h2>
                        <p class="showcase-desc text-muted-custom mb-10">
                          O Acervo Digital MJ contém estampas desenvolvidas em alto padrão de engenharia têxtil. Para proteger a exclusividade de nossos parceiros, blindamos nosso portfólio contra plágio e engenharia reversa.
                        </p>

                        <!-- Carrossel Interativo com Blur e ANTI-PLÁGIO -->
                        <div class="showcase-gallery" @contextmenu.prevent="triggerPlagiarismWarning">
                          <div class="gallery-track">
                            <!-- Loop 1 -->
                            <div class="gallery-item" v-for="n in 5" :key="'g1-'+n" :class="{'is-exclusive': n === 2 || n === 4}">
                              <div v-if="n === 2 || n === 4" class="exclusive-badge"><v-icon size="10" class="mr-1">mdi-lock</v-icon> EXCLUSIVO</div>
                              <img :src="getStamp(n)" class="gallery-img" />
                            </div>
                            <!-- Loop 2 -->
                            <div class="gallery-item" v-for="n in 5" :key="'g2-'+n" :class="{'is-exclusive': n === 2 || n === 4}">
                              <div v-if="n === 2 || n === 4" class="exclusive-badge"><v-icon size="10" class="mr-1">mdi-lock</v-icon> EXCLUSIVO</div>
                              <img :src="getStamp(n)" class="gallery-img" />
                            </div>
                          </div>
                        </div>

                        <!-- Card 3D Inclinado -->
                        <div class="tilted-3d-card mj-surface-2 border mt-10">
                          <div class="d-flex align-center gap-4">
                            <div class="tilted-icon mj-surface border">
                              <v-icon size="28" color="primary">mdi-police-badge-outline</v-icon>
                            </div>
                            <div>
                              <h4 class="text-body-1 font-weight-black text-main m-0" style="line-height: 1;">Acesso Monitorado</h4>
                              <p class="text-caption text-muted-custom m-0 mt-1">Direitos autorais amparados pela Lei nº 9.610/98.</p>
                            </div>
                          </div>
                        </div>

                      </div>
                    </div>

                    <!-- LADO DIREITO: CARD DE ACESSO (Mais largo e orgânico) -->
                    <div class="lock-card-wrapper">
                      <!-- Usando justify-space-between e flex-column pra espalhar bonito -->
                      <div class="premium-lock-card mj-glass mj-border security-gateway py-10 px-8 px-sm-12 w-100 d-flex flex-column justify-space-between">

                        <div v-if="vipStep < 4" class="timeline-header mb-8 flex-shrink-0">
                          <div class="timeline-track"><div class="timeline-progress" :style="`width: ${(vipStep - 1) * 50}%`"></div></div>
                          <div class="timeline-steps">
                            <div class="step-dot" :class="{ active: vipStep >= 1 }"><v-icon size="16" v-if="vipStep > 1">mdi-check</v-icon><span v-else>1</span></div>
                            <div class="step-dot" :class="{ active: vipStep >= 2 }"><v-icon size="16" v-if="vipStep > 2">mdi-check</v-icon><span v-else>2</span></div>
                            <div class="step-dot" :class="{ active: vipStep >= 3 }"><v-icon size="16" v-if="vipStep > 3">mdi-check</v-icon><span v-else>3</span></div>
                          </div>
                        </div>

                        <transition name="slide-x" mode="out-in">
                          <!-- PASSO 1 -->
                          <div v-if="vipStep === 1" key="step1" class="d-flex flex-column flex-grow-1">
                            <div>
                              <h2 class="section-title mb-2">Seu Interesse</h2>
                              <p class="section-copy mb-8 text-muted-custom">Qual é o foco principal da sua marca ao acessar nosso acervo?</p>
                            </div>
                            <div class="options-group my-auto">
                              <button v-for="opt in interestOptions" :key="opt" class="source-card" :class="{ 'active': vipForm.interest === opt }" @click="vipForm.interest = opt">{{ opt }}</button>
                            </div>
                            <div class="d-flex justify-end mt-auto pt-8">
                              <v-btn color="primary" size="large" class="cta-btn flex-grow-1" elevation="0" :disabled="!vipForm.interest" @click="nextVipStep">Avançar</v-btn>
                            </div>
                          </div>

                          <!-- PASSO 2 -->
                          <div v-else-if="vipStep === 2" key="step2" class="d-flex flex-column flex-grow-1">
                            <div>
                              <h2 class="section-title mb-2">Metragem de Piloto</h2>
                              <p class="section-copy mb-8 text-muted-custom">Qual a previsão de metragem inicial para o seu teste físico?</p>
                            </div>
                            <div class="options-group my-auto">
                              <button v-for="opt in meterageOptions" :key="opt" class="source-card" :class="{ 'active': vipForm.pilotMeterage === opt }" @click="vipForm.pilotMeterage = opt">{{ opt }}</button>
                            </div>
                            <div class="d-flex gap-4 mt-auto pt-8">
                              <v-btn variant="tonal" size="large" class="rounded-xl px-4 cta-btn" @click="prevVipStep"><v-icon>mdi-arrow-left</v-icon></v-btn>
                              <v-btn color="primary" size="large" class="cta-btn flex-grow-1" elevation="0" :disabled="!vipForm.pilotMeterage" @click="nextVipStep">Avançar</v-btn>
                            </div>
                          </div>

                          <!-- PASSO 3 -->
                          <div v-else-if="vipStep === 3" key="step3" class="d-flex flex-column flex-grow-1">
                            <div>
                              <h2 class="section-title mb-2">Sua Operação</h2>
                              <p class="section-copy mb-8 text-muted-custom">Isso nos ajuda a direcionar as melhores opções de preço (Opcional).</p>
                            </div>
                            <div class="options-group my-auto">
                              <button v-for="opt in operationOptions" :key="opt" class="source-card" :class="{ 'active': vipForm.operationSize === opt }" @click="vipForm.operationSize = opt">{{ opt }}</button>
                            </div>
                            <div class="d-flex gap-4 mt-auto pt-8">
                              <v-btn variant="tonal" size="large" class="rounded-xl px-4 cta-btn" @click="prevVipStep"><v-icon>mdi-arrow-left</v-icon></v-btn>
                              <v-btn color="primary" size="large" class="cta-btn flex-grow-1" elevation="0" @click="vipStep = 4">Concluir Análise</v-btn>
                            </div>
                          </div>

                          <!-- PASSO 4: CADEADO (Tudo distribuido perfeitamente) -->
                          <div v-else-if="vipStep === 4" key="step4" class="d-flex flex-column flex-grow-1">
                            <!-- Bloco Superior -->
                              <div class="text-center flex-shrink-0 mt-2">
                                <div class="status-icon-wrapper primary mb-4 mx-auto">
                                  <v-icon size="36" color="primary">mdi-shield-lock-outline</v-icon>
                                </div>
                                <h2 class="section-title mb-2">Acesso Protegido</h2>
                                <p class="section-copy text-body-2 px-2 text-muted-custom">
                                  Por segurança, o acervo premium requer a chave de liberação temporária.
                                </p>

                                <div class="d-flex align-center justify-center gap-2 mt-4 animate-pulse">
                                  <v-progress-circular indeterminate size="16" color="primary" width="2"></v-progress-circular>
                                  <span class="text-caption font-weight-bold text-primary">Aguardando análise do consultor...</span>
                                </div>
                              </div>

                            <v-alert v-if="vipError" type="error" variant="tonal" class="my-3 text-caption text-left border-error">{{ vipError }}</v-alert>
                            <v-alert v-if="vipSuccess" type="success" variant="tonal" class="my-3 text-caption text-center border-success">{{ vipSuccess }}</v-alert>

                            <!-- Bloco Central (Input, Botão e Aviso de Spam) -->
                            <div class="my-auto w-100">
                              <div class="security-input-box mb-6">
                                <label class="text-caption font-weight-bold text-uppercase tracking-wider text-muted-custom d-block text-center mb-4">Insira sua Chave</label>
                                <input id="vipCode" name="vipCode" v-model="codeInput" type="text" class="code-input" :disabled="isSubmittingCode" placeholder="------" maxlength="8" @keyup.enter="validateVipCode" autocomplete="off" />
                              </div>

                              <v-btn color="primary" block class="cta-btn giant-fix-btn" elevation="0" :loading="isSubmittingCode" @click="validateVipCode">
                                Desbloquear Acervo
                              </v-btn>

                              <!-- NOVO AVISO DE SPAM / E-MAIL -->
                              <v-alert color="warning" variant="tonal" density="compact" class="mt-5 border-warning rounded-lg text-left pa-3">
                                <div class="d-flex align-center">
                                  <v-icon size="20" color="warning" class="mr-3 flex-shrink-0">mdi-email-alert-outline</v-icon>
                                  <span class="text-caption font-weight-bold text-warning" style="line-height: 1.3;">
                                    A chave será enviada por e-mail. Caso não encontre na caixa de entrada, <strong>verifique a pasta de Spam</strong>.
                                  </span>
                                </div>
                              </v-alert>
                            </div>

                            <!-- Bloco Inferior (Ações Auxiliares) -->
                            <div class="mt-auto w-100 pt-4">
                              <div class="divider-container mb-6">
                                <div class="divider-line"></div><span class="divider-text text-muted-custom">PRECISA DE UMA CHAVE?</span><div class="divider-line"></div>
                              </div>

                              <div class="d-flex align-center gap-3 pb-2">
                                <button type="button" class="mini-social-btn email-btn" :disabled="isRequestingCode" @click="requestNewCode">
                                  <v-icon size="16">mdi-email-outline</v-icon> Por E-mail
                                </button>
                                <button type="button" class="mini-social-btn wa-premium-btn" @click="handleVipWhatsApp">
                                  <v-icon size="18" color="white">mdi-whatsapp</v-icon> Via WhatsApp
                                </button>
                              </div>
                            </div>

                          </div>
                        </transition>

                      </div>
                    </div>

                  </div>
                </v-container>
              </div>

              <!-- 3. CONTEÚDO LIBERADO -->
              <div v-else key="content-view" class="w-100">
                <router-view :settings="settings"></router-view>
              </div>

            </transition>

            <footer class="site-footer">
              <div class="footer-glow-line"></div>

              <v-container class="container-xl footer-inner">
                <div class="footer-main-grid">
                  <div class="footer-brand-col">
                    <img
                      :src="settings.logo_url || currentLogo"
                      alt="Logo"
                      class="brand-logo footer-logo"
                      :class="{ 'invert-logo': isDark && !settings.logo_url }"
                    />
                    <p class="brand-desc">
                      O ecossistema definitivo para confecções e marcas de moda. Curadoria de estampas premium, tecidos de alta tecnologia e gestão de produção integrada em uma única plataforma.
                    </p>
                    <div class="social-links">
                      <a href="javascript:void(0)" class="social-btn"><v-icon size="20">mdi-instagram</v-icon></a>
                      <a href="javascript:void(0)" class="social-btn"><v-icon size="20">mdi-pinterest</v-icon></a>
                      <a href="javascript:void(0)" class="social-btn"><v-icon size="20">mdi-linkedin</v-icon></a>
                    </div>
                  </div>

                  <div class="footer-nav-col">
                    <h4 class="nav-title">Acervo Digital</h4>
                    <ul class="nav-list">
                      <li><a href="javascript:void(0)" @click="router.push('/marketplace')">Início</a></li>
                      <li><a href="javascript:void(0)" @click="router.push('/marketplace/catalogo')">Explorar Coleções</a></li>
                      <li><a href="javascript:void(0)" @click="moodboardOpen = true">Meu Moodboard (Carrinho)</a></li>
                    </ul>
                  </div>

                  <div class="footer-nav-col">
                    <h4 class="nav-title">Área do Cliente</h4>
                    <ul class="nav-list">
                      <li><a href="javascript:void(0)" @click="router.push('/marketplace/perfil')">Minha Conta</a></li>
                      <li><a href="javascript:void(0)" @click="router.push('/marketplace/desenvolvimento')">Estúdio VIP</a></li>
                      <li><a href="javascript:void(0)" @click="router.push('/marketplace/pilotos')">Meus Pilotos</a></li>
                    </ul>
                  </div>

                  <div class="footer-contact-col">
                    <h4 class="nav-title">Acesso Exclusivo</h4>
                    <p class="newsletter-desc">Receba drops de novas coleções em primeira mão e condições especiais de atacado.</p>

                    <div class="newsletter-box mj-surface-2 mj-border">
                      <input type="email" placeholder="Seu melhor e-mail corporativo" class="newsletter-input" />
                      <button class="newsletter-btn"><v-icon>mdi-arrow-right</v-icon></button>
                    </div>

                    <div class="contact-info">
                      <div class="contact-item">
                        <v-icon size="16">mdi-email-outline</v-icon>
                        <span>contato@mjprocess.com.br</span>
                      </div>
                      <div class="contact-item">
                        <v-icon size="16">mdi-map-marker-outline</v-icon>
                        <span>Tietê, SP - Brasil</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="footer-bottom border-t border-opacity-10">
                  <div class="copyright">
                    &copy; {{ new Date().getFullYear() }} MJ Process. Desenvolvido para a Indústria Têxtil.
                  </div>

                  <div class="legal-links">
                    <a href="javascript:void(0)">Termos de Uso</a>
                    <span class="dot-separator">•</span>
                    <a href="javascript:void(0)">Política de Privacidade</a>
                  </div>

                  <div class="security-badges">
                    <v-tooltip location="top" text="Pagamento Seguro">
                      <template v-slot:activator="{ props }"><v-icon v-bind="props" size="22">mdi-shield-check</v-icon></template>
                    </v-tooltip>
                    <v-tooltip location="top" text="Transação via PIX">
                      <template v-slot:activator="{ props }"><v-icon v-bind="props" size="22">mdi-qrcode-scan</v-icon></template>
                    </v-tooltip>
                    <v-tooltip location="top" text="Criptografia SSL de Ponta a Ponta">
                      <template v-slot:activator="{ props }"><v-icon v-bind="props" size="22">mdi-lock</v-icon></template>
                    </v-tooltip>
                  </div>
                </div>
              </v-container>
            </footer>
          </main>

          <v-navigation-drawer
            v-model="moodboardOpen"
            location="right"
            temporary
            width="420"
            class="moodboard-drawer"
          >
            <div class="drawer-head mj-surface mj-border">
              <div>
                <div class="eyebrow">Seleção</div>
                <h3 class="section-title small">Carrinho</h3>
                <p class="drawer-sub">{{ moodboard.length }} item(ns)</p>
              </div>
              <v-btn icon="mdi-close" variant="tonal" size="small" @click="moodboardOpen = false" />
            </div>

            <div class="drawer-body">
              <div v-if="isSyncing" class="d-flex justify-center pa-8">
                <v-progress-circular indeterminate color="primary" />
              </div>
              <div v-else-if="!moodboard.length" class="drawer-empty mj-surface-2 mj-border">
                <v-icon size="52">mdi-folder-open-outline</v-icon>
                <h4>Sua seleção está vazia</h4>
                <p>As estampas que você adicionar em qualquer dispositivo aparecerão aqui.</p>
              </div>

              <div v-else class="drawer-list">
                <article v-for="(item, index) in moodboard" :key="item.id || index" class="drawer-item mj-surface mj-border">
                  <img :src="item.stamp?.main_image_url || '/placeholder.png'" alt="Estampa" class="drawer-item-image" />

                  <div class="drawer-item-info">
                    <div class="d-flex align-center gap-2 mb-1">
                      <span class="stamp-ref">{{ item.stamp?.ref_code || 'N/A' }}</span>
                      <span :class="item.is_physical ? 'badge-physical' : 'badge-digital'">
                        {{ item.is_physical ? 'Físico' : 'Digital' }}
                      </span>
                    </div>

                    <h4>{{ item.stamp?.title || 'Estampa' }}</h4>

                    <p v-if="item.is_physical" class="item-meta">{{ item.fabric_name || 'Tecido Selecionado' }} - {{ item.quantity }}m</p>
                    <p v-else class="item-meta text-primary">Arquivo PSD</p>
                  </div>

                  <v-btn icon="mdi-close" variant="text" color="error" size="small" @click="removeFromCarrinho(item)" :loading="item.isDeleting" />
                </article>
              </div>
            </div>

            <div v-if="moodboard.length" class="drawer-footer mj-surface mj-border" style="display: flex; flex-direction: column; gap: 12px;">
              <v-btn block color="primary" size="x-large" class="buy-btn" @click="sendToWhatsAppDirect">
                <v-icon start>mdi-whatsapp</v-icon>
                Orçar Produção (Físico)
              </v-btn>
              <v-btn block color="success" size="x-large" class="buy-btn" @click="goToCheckout" variant="tonal">
                <v-icon start>mdi-lock-outline</v-icon>
                Comprar PSDs (Digital)
              </v-btn>
            </div>
          </v-navigation-drawer>

        </section>
      </transition>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch, provide } from 'vue'
import { useTheme } from 'vuetify'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

import LogoDark from '@/assets/logo.png'
import LogoLight from '@/assets/logomjlm.png'

import Stamp1 from '@/assets/1.jpg'
import Stamp2 from '@/assets/2.jpg'
import Stamp3 from '@/assets/3.jpg'
import Stamp4 from '@/assets/4.jpg'
import Stamp5 from '@/assets/5.jpg'

const theme = useTheme()
const router = useRouter()
const route = useRoute()
const userStore = useMarketplaceUserStore()

const isDark = computed(() => theme.global.current.value.dark)
const currentLogo = computed(() => (isDark.value ? LogoDark : LogoLight))

const isLoading = ref(true)
const isSyncing = ref(false)
const moodboardOpen = ref(false)
const settings = ref<any>({ grids_config: [] })
const moodboard = ref<any[]>([])
const userProfile = ref<any>({ id: '', name: 'Visitante', email: '', location: '', document: '', phone: '', design_access_status: 'none' })
const isLoggedIn = ref(false)

// Variáveis de Controle VIP
const hasVipAccess = ref(false)
const codeInput = ref('')
const isSubmittingCode = ref(false)
const isRequestingCode = ref(false)
const vipError = ref('')
const vipSuccess = ref('')

const showGuestLock = computed(() => isGuestRestrictedRoute(route) && !isLoggedIn.value)
const showVipLock = computed(() => isVipRestrictedRoute(route) && isLoggedIn.value && !hasVipAccess.value)

const stampImages = [Stamp1, Stamp2, Stamp3, Stamp4, Stamp5]
const getStamp = (index: number) => stampImages[(index - 1) % stampImages.length]

let authSubscription: any = null
let authCheckInterval: any = null

provide('marketplaceCart', {
  moodboard,
  moodboardOpen,
  addToCarrinho,
  removeFromCarrinho
})

// Tratamento seguro para troca de temas
const toggleTheme = () => {
  const newTheme = isDark.value ? 'light' : 'dark'
  if (typeof (theme as any).change === 'function') {
    (theme as any).change(newTheme)
  } else {
    theme.global.name.value = newTheme
  }
  localStorage.setItem('mj_theme', newTheme)
}

function getUserInitials(name: string) {
  if (!name || name === 'Visitante') return 'VI'
  const parts = name.trim().split(' ')
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  return name.substring(0, 2).toUpperCase()
}

// ==========================================
// ROTAS RESTRITAS (Controle de Acesso)
// ==========================================

// Exigem apenas ter uma conta logada (Inclui catálogo aqui para forçar Visitante a Logar primeiro)
const isGuestRestrictedRoute = (r: any) => {
    const p = r.path || '';
    return p.includes('/perfil') || p.includes('/favoritos') || p.includes('/desenvolvimento') || p.includes('/pilotos') || p.includes('/checkout') || p.includes('/catalogo') || p.includes('/descobrir');
}

// Exigem a CHAVE VIP (Para quem JÁ está logado)
const isVipRestrictedRoute = (r: any) => {
    const p = r.path || '';
    return p.includes('/catalogo') || p.includes('/descobrir');
}

// ==========================================
// VALIDAÇÃO VIP (O GATEKEEPER)
// ==========================================
async function gatherDeviceContext() {
  const userAgent = navigator.userAgent;
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const screenRes = `${window.screen.width}x${window.screen.height}`;
  const language = navigator.language;
  const rawFingerprint = `${userAgent}-${screenRes}-${timezone}-${language}`;
  const encoder = new TextEncoder();
  const data = encoder.encode(rawFingerprint);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return { user_agent: userAgent, timezone, language, fingerprint: hashArray.map(b => b.toString(16).padStart(2, '0')).join('') };
}

async function validateVipCode() {
    vipError.value = ''; vipSuccess.value = '';
    if (!codeInput.value) return;
    isSubmittingCode.value = true;
    try {
        const ctx = await gatherDeviceContext();
        const { data, error } = await supabase.rpc('validate_premium_access', {
            p_email: userProfile.value.email, p_code: codeInput.value.trim().toUpperCase(), p_context: ctx
        });
        if (error) throw error;
        if (data && data.status === 'success') {
            localStorage.setItem('mj_premium_session_token', data.session_token);
            localStorage.setItem('mj_active_code', codeInput.value.trim().toUpperCase());
            hasVipAccess.value = true;
            vipSuccess.value = 'Acesso liberado!';
        } else throw new Error('Código inválido ou expirado.');
    } catch(e:any) { vipError.value = e.message; }
    finally { isSubmittingCode.value = false; }
}

async function requestNewCode() {
  isRequestingCode.value = true
  vipError.value = ''
  vipSuccess.value = ''

  try {
    const { error: updateError } = await supabase
      .from('public_leads')
      .update({
        vip_interest: vipForm.value.interest || null,
        vip_pilot_meterage: vipForm.value.pilotMeterage || null,
        vip_operation_size: vipForm.value.operationSize || null,
        auth_code_requested: true // <--- O SEGREDO TAVA AQUI, FALTAVA ISSO!
      })
      .eq('email', userProfile.value.email)

    if (updateError) throw updateError

    const { error: rpcError } = await supabase.rpc('generate_premium_access_code', {
      p_email: userProfile.value.email
    })

    if (rpcError) throw rpcError

    vipSuccess.value = 'Pedido enviado! Nossa equipe avaliará seu perfil e você receberá a chave no e-mail.'

  } catch (err: any) {
    vipError.value = 'Erro ao solicitar chave: ' + err.message
  } finally {
    isRequestingCode.value = false
  }
}

async function checkVipAccessSilent(email: string) {
    const { data } = await supabase.from('public_leads').select('access_status, temp_auth_code, temp_auth_expires_at').eq('email', email).maybeSingle();

    if (data && data.access_status === 'active') {
        const activeLocalCode = localStorage.getItem('mj_active_code');

        if (data.temp_auth_code === 'TEAM-MJ' && activeLocalCode === 'TEAM-MJ') {
            hasVipAccess.value = true;
            return;
        }

        const sessionToken = localStorage.getItem('mj_premium_session_token');
        const expiresAt = data.temp_auth_expires_at ? new Date(data.temp_auth_expires_at) : null;

        if (expiresAt && expiresAt > new Date()) {
            // SE FOR APROVAÇÃO DIRETA (Código nulo) -> Liberar imediatamente
            if (data.temp_auth_code === null) {
                hasVipAccess.value = true;
            }
            // SE FOR POR CÓDIGO (Validar device binding)
            else if (data.temp_auth_code === activeLocalCode && sessionToken) {
                const { data: ctxData } = await supabase.rpc('check_premium_context', { p_email: email, p_context: await gatherDeviceContext() });
                hasVipAccess.value = !!(ctxData && ctxData.status === 'ok');
            } else {
                hasVipAccess.value = false;
            }
        } else {
            hasVipAccess.value = false;
        }
    } else {
        hasVipAccess.value = false;
    }
}

// ==========================================
// CONTROLES DO ONBOARDING VIP (NOVO - COM PERSISTÊNCIA F5)
// ==========================================
const vipStep = ref(Number(sessionStorage.getItem('mj_vip_step')) || 1)
const savedForm = sessionStorage.getItem('mj_vip_form')
const vipForm = ref(savedForm ? JSON.parse(savedForm) : {
  interest: '',
  pilotMeterage: '',
  operationSize: ''
})

// Salva instantaneamente no navegador ao alterar
watch(vipStep, (val) => sessionStorage.setItem('mj_vip_step', val.toString()))
watch(vipForm, (val) => sessionStorage.setItem('mj_vip_form', JSON.stringify(val)), { deep: true })

const interestOptions = ['Desenvolvimento VIP', 'Piloto Físico', 'Ambos (Dev + Piloto)']
const meterageOptions = ['Até 50 metros', '50m a 200 metros', 'Mais de 200 metros']
const operationOptions = ['Pequena (Até 1k peças/mês)', 'Média (1k a 10k peças/mês)', 'Grande (+10k peças/mês)']

function nextVipStep() {
  if (vipStep.value === 1 && vipForm.value.interest === 'Desenvolvimento VIP') {
    vipStep.value = 3 // Pula a metragem se for só Dev
  } else {
    vipStep.value++
  }
}

function prevVipStep() {
  if (vipStep.value === 3 && vipForm.value.interest === 'Desenvolvimento VIP') {
    vipStep.value = 1
  } else {
    vipStep.value--
  }
}

function handleVipWhatsApp() {
  let msg = 'Olá! Gostaria de solicitar minha chave de acesso de segurança para o acervo digital.\n\n'
  msg += `*Interesse principal:* ${vipForm.value.interest || 'Não informado'}\n`
  if (vipForm.value.interest !== 'Desenvolvimento VIP' && vipForm.value.pilotMeterage) {
    msg += `*Metragem de Piloto:* ${vipForm.value.pilotMeterage}\n`
  }
  if (vipForm.value.operationSize) {
    msg += `*Tamanho da Operação:* ${vipForm.value.operationSize}\n`
  }
  window.open(`https://wa.me/5515991876055?text=${encodeURIComponent(msg)}`, '_blank')
}

// ==========================================
// CARRINHO E DADOS DE USUÁRIO
// ==========================================
async function fetchUserCart() {
  isSyncing.value = true
  try {
    const { data, error } = await supabase
      .from('marketplace_cart')
      .select('*, stamp:catalog_stamps(*)')
      .eq('user_id', userProfile.value.auth_id)

    if (error) throw error

    moodboard.value = data.map(item => ({
      id: item.id,
      stamp: item.stamp,
      quantity: item.quantity,
      is_physical: item.is_physical,
      fabric_id: item.fabric_id,
      fabric_name: item.is_physical ? 'Tecido Selecionado' : ''
    }))
  } catch (e) {
    console.error("Erro ao carregar carrinho do banco", e)
  } finally {
    isSyncing.value = false
  }
}

async function addToCarrinho(stamp: any, quantity: number) {
  if (!stamp || !userProfile.value.auth_id) return

  const isPhysical = stamp.is_physical !== false
  const fabricId = stamp.fabric_id || null

  try {
    const { error } = await supabase
      .from('marketplace_cart')
      .upsert({
        user_id: userProfile.value.auth_id,
        stamp_id: stamp.id,
        quantity: quantity,
        fabric_id: fabricId,
        is_physical: isPhysical
      }, { onConflict: 'user_id, stamp_id, fabric_id, is_physical' })

    if (error) throw error

    await fetchUserCart()
    moodboardOpen.value = true
  } catch (e) {
    alert("Erro ao salvar item no seu carrinho remoto.")
  }
}

async function removeFromCarrinho(cartItem: any) {
  if (!cartItem.id) return

  cartItem.isDeleting = true
  try {
    const { error } = await supabase
      .from('marketplace_cart')
      .delete()
      .eq('id', cartItem.id)

    if (error) throw error
    moodboard.value = moodboard.value.filter(item => item.id !== cartItem.id)
  } catch (e) {
    alert("Erro ao remover item do banco.")
  } finally {
    cartItem.isDeleting = false
  }
}

function sendToWhatsAppDirect() {
  const physicalItems = moodboard.value.filter(item => item.is_physical)

  if (!physicalItems.length) {
    alert('Você não possui itens físicos de estamparia no carrinho para orçar.')
    return
  }

  const attendantPhone = '5515991876055'
  let msg = `*OLÁ! GOSTARIA DE FAZER UM PEDIDO FÍSICO (PRODUÇÃO)*\n\n*Cliente:* ${userProfile.value.name}\n*CNPJ/CPF:* ${userProfile.value.document}\n*Local:* ${userProfile.value.location}\n\n*ITENS SELECIONADOS:*\n`

  physicalItems.forEach((item) => {
    msg += `▪️ ${item.stamp.title} (Ref: ${item.stamp.ref_code})\n`
    if (item.fabric_name) {
      msg += `   Tecido: ${item.fabric_name}\n`
    }
    msg += `   Metragem: ${item.quantity}m\n\n`
  })

  window.open(`https://wa.me/${attendantPhone}?text=${encodeURIComponent(msg)}`, '_blank')
}

function goToCheckout() {
  const digitalItems = moodboard.value.filter(item => !item.is_physical)

  if (!digitalItems.length) {
    alert('Você não possui arquivos digitais no carrinho para comprar.')
    return
  }

  const firstDigital = digitalItems[0]
  moodboardOpen.value = false
  router.push(`/marketplace/checkout?digital_stamp=${firstDigital.stamp.id}`)
}

watch(() => route.path, () => {
  const scrollToTop = () => {
    const scrollContainer = document.querySelector('.content-scroll')
    if (scrollContainer) {
      scrollContainer.scrollTo({ top: 0, behavior: 'instant' })
    }
    window.scrollTo({ top: 0, behavior: 'instant' })
  }

  requestAnimationFrame(scrollToTop)
  setTimeout(scrollToTop, 300)
})

onMounted(async () => {
  isLoading.value = true

  const savedTheme = localStorage.getItem('mj_theme')
  if (savedTheme === 'dark' || savedTheme === 'light') {
    if (typeof (theme as any).change === 'function') {
      (theme as any).change(savedTheme)
    } else {
      theme.global.name.value = savedTheme
    }
  }

  try {
    const { data: { session } } = await supabase.auth.getSession()

    if (session) {
      isLoggedIn.value = true
      const { data: leadData } = await supabase
        .from('public_leads')
        .select('*')
        .eq('email', session.user.email)
        .maybeSingle()

      if (leadData && leadData.document && leadData.name) {
        userProfile.value = { ...leadData, auth_id: session.user.id }

        // VITAL: Sincroniza a Store do Vuex/Pinia com o Usuário para as Rotas Internas entenderem
        await userStore.setUser({
            id: leadData.id,
            name: leadData.name,
            email: leadData.email,
            phone: leadData.phone,
            document: leadData.document,
            avatarUrl: leadData.avatar_url
        })

        await fetchUserCart()

        // Verifica silenciosamente o acesso VIP
        await checkVipAccessSilent(session.user.email)

        // -----------------------------------------------------
        // INICIA O REALTIME SOMENTE SE ELE TIVER CONTA DE LEAD
        // -----------------------------------------------------
if (session.user.email) {
  authSubscription = supabase
    .channel('public_leads_auth_monitor')
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'public_leads',
        filter: `email=eq.${session.user.email}`
      },
      (payload) => {
        const { temp_auth_code, temp_auth_expires_at, access_status } = payload.new

        const now = new Date()
        const expiresAt = temp_auth_expires_at ? new Date(temp_auth_expires_at) : null
        const activeLocalCode = localStorage.getItem('mj_active_code')

        // Se expirou ou o status não for active, barra.
        if (!expiresAt || expiresAt < now || access_status !== 'active') {
          hasVipAccess.value = false
        }
        // APROVAÇÃO DIRETA (O Consultor apertou o botão mágico)
        else if (temp_auth_code === null) {
          hasVipAccess.value = true
          vipSuccess.value = 'Acesso liberado automaticamente pelo consultor!'
        }
        // CONTROLE PADRÃO POR CÓDIGO
        else if (temp_auth_code !== activeLocalCode) {
          hasVipAccess.value = false
        }
      }
    )
    .subscribe()

          authCheckInterval = setInterval(() => {
            checkVipAccessSilent(session.user.email)
          }, 60000)
        }
        // -----------------------------------------------------

      } else {
        await supabase.auth.signOut()
        isLoggedIn.value = false
      }
    } else {
      isLoggedIn.value = false
    }

    const { data: configData } = await supabase
      .from('storefront_settings')
      .select('*')
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (configData) {
      settings.value = { ...settings.value, ...configData }
      if (!Array.isArray(settings.value.grids_config)) settings.value.grids_config = []
    }

  } catch (error) {
    console.error('Erro ao iniciar portal:', error)
  } finally {
    isLoading.value = false
  }
})

onUnmounted(() => {
  if (authSubscription) {
    supabase.removeChannel(authSubscription)
  }
  if (authCheckInterval) {
    clearInterval(authCheckInterval)
  }
})
</script>

<style scoped>
.mj-marketplace {
  min-height: 100vh;
  width: 100%;
  background: var(--bg-main);
  color: var(--text-main);
  transition: background-color 0.25s ease, color 0.25s ease;
}

.theme-dark {
  --v-theme-primary: 161, 75, 18 !important;
  --bg-main: #09090b;
  --bg-surface: #111317;
  --bg-surface-2: #171a20;
  --bg-elevated: rgba(20, 23, 29, 0.86);
  --bg-soft: #0d1015;
  --text-main: #f5f7fb;
  --text-soft: #c3cad7;
  --text-muted: #8f98a8;
  --border-color: rgba(255, 255, 255, 0.08);
  --border-strong: rgba(255, 255, 255, 0.12);
  --overlay-dark: linear-gradient(180deg, rgba(9, 9, 11, 0.08) 0%, rgba(9, 9, 11, 0.76) 100%);
  --overlay-soft: linear-gradient(180deg, rgba(9, 9, 11, 0.2) 0%, rgba(9, 9, 11, 0.88) 100%);
  --hero-shadow: 0 30px 80px rgba(0, 0, 0, 0.45);
  --surface-shadow: 0 16px 40px rgba(0, 0, 0, 0.35);
  --hover-shadow: 0 22px 56px rgba(0, 0, 0, 0.5);
  --input-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
  --glass-blur: blur(10px);
}

.theme-light {
  --v-theme-primary: 161, 75, 18 !important;
  --bg-main: #f5f7fb;
  --bg-surface: #ffffff;
  --bg-surface-2: #f7f9fc;
  --bg-elevated: rgba(255, 255, 255, 0.8);
  --bg-soft: #eef2f7;
  --text-main: #0c1424;
  --text-soft: #3c4a61;
  --text-muted: #6d7890;
  --border-color: rgba(12, 20, 36, 0.08);
  --border-strong: rgba(12, 20, 36, 0.12);
  --overlay-dark: linear-gradient(180deg, rgba(245, 247, 251, 0.06) 0%, rgba(245, 247, 251, 0.72) 100%);
  --overlay-soft: linear-gradient(180deg, rgba(255, 255, 255, 0.18) 0%, rgba(245, 247, 251, 0.92) 100%);
  --hero-shadow: 0 30px 80px rgba(22, 28, 45, 0.08);
  --surface-shadow: 0 16px 40px rgba(22, 28, 45, 0.08);
  --hover-shadow: 0 24px 54px rgba(22, 28, 45, 0.12);
  --input-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.7);
  --glass-blur: blur(10px);
}

:deep(body),
:deep(.v-application),
:deep(.v-main),
:deep(.v-navigation-drawer),
:deep(.v-overlay__content) {
  background: var(--bg-main);
  color: var(--text-main);
}

:deep(.v-navigation-drawer__content) {
  background: var(--bg-surface);
}

* {
  box-sizing: border-box;
}

button,
input,
textarea,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

img {
  display: block;
  max-width: 100%;
}

.mj-surface {
  background: var(--bg-surface);
  color: var(--text-main);
  box-shadow: var(--surface-shadow);
}

.mj-surface-2 {
  background: var(--bg-surface-2);
  color: var(--text-main);
}

.mj-glass {
  background: var(--bg-elevated);
  backdrop-filter: var(--glass-blur);
  -webkit-backdrop-filter: var(--glass-blur);
}

.mj-border {
  border: 1px solid var(--border-color);
}

.app-shell,
.store-shell,
.content-scroll {
  min-height: 100vh;
}

.boot-screen {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: var(--bg-main);
}

.boot-box {
  width: min(360px, calc(100vw - 32px));
  display: grid;
  gap: 20px;
  justify-items: center;
}

.boot-logo {
  height: 50px;
}

.boot-line {
  width: 100%;
  height: 4px;
  border-radius: 999px;
  background: linear-gradient(90deg, transparent 0%, rgba(var(--v-theme-primary), 0.22) 20%, rgba(var(--v-theme-primary), 0.9) 50%, rgba(var(--v-theme-primary), 0.22) 80%, transparent 100%);
  animation: pulseLine 1.6s ease-in-out infinite;
}

.boot-text {
  margin: 0;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 12px;
  font-weight: 700;
}

@keyframes pulseLine {
  0%,
  100% { opacity: 0.4; transform: scaleX(0.96); }
  50% { opacity: 1; transform: scaleX(1); }
}

/* =========================================================
   DESTAQUES VIP DOURADOS (HEADER / BOTOES)
========================================================= */

.header-nav {
  display: flex;
  align-items: center;
  gap: 12px;
}

.premium-vip-btn {
  position: relative;
  overflow: hidden;
  background: #a14b122f !important;
  color: #a14b12 !important;
  border: 1px solid #a14b1259 !important;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 12px #a14b1228;
  transition: all 0.3s ease;
}

.premium-vip-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 50%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.4), transparent);
  transform: skewX(-20deg);
  animation: shine 3.5s infinite;
}

.theme-dark .premium-vip-btn::before {
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.15), transparent);
}

@keyframes shine {
  0% { left: -100%; }
  20% { left: 200%; }
  100% { left: 200%; }
}

.premium-vip-btn:hover {
  background: rgba(245, 158, 11, 0.15) !important;
  border-color: rgba(245, 158, 11, 0.6) !important;
  box-shadow: 0 4px 16px rgba(245, 158, 11, 0.25);
  transform: translateY(-1px);
}

.vip-crown-icon {
  filter: drop-shadow(0 0 4px rgba(245, 158, 11, 0.6));
}

.vip-text-gradient {
  background: linear-gradient(45deg, #F59E0B, #FCD34D, #F59E0B);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 900;
}

.vip-glow {
  filter: drop-shadow(0 0 8px rgba(245, 158, 11, 0.6));
}

.vip-border {
  border: 2px solid #F59E0B;
}

/* ========================================================= */

.hero-media,
.parallax-media {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.hero-layer,
.parallax-layer {
  position: absolute;
  inset: 0;
  background: var(--overlay-dark);
}

.brand-logo {
  height: 42px;
  width: auto;
  object-fit: contain;
}

.theme-toggle {
  flex-shrink: 0;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  min-height: 30px;
  padding: 0 14px;
  border-radius: 999px;
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
  font-weight: 800;
  font-size: 12px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.eyebrow.solid {
  background: rgba(var(--v-theme-primary), 0.18);
}

.hero-title,
.product-title,
.section-title {
  margin: 0;
  color: var(--text-main);
  letter-spacing: -0.04em;
  line-height: 1.02;
}

.hero-copy,
.product-description,
.section-copy,
.drawer-sub,
.footer-brand p,
.empty-state p,
.drawer-empty p {
  color: var(--text-soft);
  line-height: 1.7;
}

.section-title {
  font-size: clamp(1.8rem, 2.2vw, 2.6rem);
  margin-top: 14px;
}

.section-title.large {
  font-size: clamp(2rem, 2.6vw, 3rem);
}

.section-title.xl {
  font-size: clamp(2.2rem, 3vw, 3.6rem);
}

.section-title.small {
  font-size: 1.5rem;
}

.section-copy {
  margin: 16px 0 0;
}

.search-input,
.qty-input {
  width: 100%;
  background: var(--bg-surface-2);
  color: var(--text-main);
  border: 1px solid var(--border-color);
  border-radius: 18px;
  outline: none;
  box-shadow: var(--input-shadow);
}

.search-input::placeholder {
  color: var(--text-muted);
}

.search-input:focus,
.qty-input:focus {
  border-color: rgba(var(--v-theme-primary), 0.65);
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.12);
}

.hero-cta,
.buy-btn,
.moodboard-btn {
  min-height: 56px;
  border-radius: 18px !important;
  font-weight: 800 !important;
  letter-spacing: 0.01em;
}

/* =========================================================
   HEADER PREMIUM & AVATAR
========================================================= */
.store-header {
  position: fixed;
  left: 0;
  right: 0;
  z-index: 9999 !important;
  height: 82px;
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  background: rgba(var(--bg-surface-rgb), 0.65);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.premium-user-pill {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 16px 6px 6px;
  border-radius: 999px;
  background: var(--bg-surface-2);
  border: 1px solid var(--border-color);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.premium-user-pill:hover {
  background: var(--bg-surface);
  border-color: rgba(var(--v-theme-primary), 0.4);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transform: translateY(-1px);
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.8), rgba(var(--v-theme-primary), 0.4));
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.05em;
  overflow: hidden;
  box-shadow: inset 0 2px 4px rgba(255,255,255,0.2);
}

.user-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-info {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.user-greeting {
  font-size: 0.9rem;
  font-weight: 800;
  color: var(--text-main);
  line-height: 1.1;
}

.user-location {
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: 2px;
  display: flex;
  align-items: center;
}

.header-divider {
  width: 1px;
  height: 24px;
  background: var(--border-strong);
}

.premium-cart-btn {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 0 20px;
  border-radius: 999px;
  background: rgb(var(--v-theme-primary));
  color: #ffffff;
  font-weight: 700;
  font-size: 0.95rem;
  border: none;
  transition: all 0.3s ease;
  box-shadow: 0 4px 14px rgba(var(--v-theme-primary), 0.25);
}

.premium-cart-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(var(--v-theme-primary), 0.4);
  filter: brightness(1.1);
}

.cart-icon {
  margin-right: -2px;
}

.premium-cart-badge {
  position: absolute;
  top: -6px;
  right: -6px;
  background: #ef4444;
  color: #fff;
  min-width: 22px;
  height: 22px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 900;
  padding: 0 6px;
  border: 2px solid var(--bg-main);
  box-shadow: 0 2px 8px rgba(239, 68, 68, 0.4);
  animation: badgePop 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes badgePop {
  0% { transform: scale(0); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

.nav-link {
  min-height: 42px;
  padding: 0 18px;
  border: 0;
  background: transparent;
  color: var(--text-muted);
  border-radius: 999px;
  font-weight: 700;
  transition: all 0.2s ease;
}

.nav-link:hover,
.nav-link.active {
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
}

.maintenance-bar {
  position: sticky;
  top: 0;
  z-index: 40;
  min-height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 6px 16px;
  background: #b91c1c;
  color: #fff;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.content-scroll {
  background: var(--bg-main);
  overflow-x: hidden;
  overflow-y: auto;
}

.view-wrap {
  padding-top: 82px;
}

.home-view,
.discover-view,
.product-view {
  min-height: calc(100vh - 82px);
}

.hero-block {
  position: relative;
  min-height: 72vh;
  overflow: hidden;
  border-radius: 0 0 36px 36px;
  box-shadow: var(--hero-shadow);
}

.parallax-section {
  position: relative;
  overflow: hidden;
  min-height: 50vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
}

.parallax-content {
  position: relative;
  z-index: 2;
  width: 100%;
  padding: 0 16px;
}

.hero-container {
  position: relative;
  z-index: 2;
  width: min(1100px, calc(100% - 32px));
  margin: 0 auto;
  min-height: 72vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: 80px 0;
}

.hero-title {
  margin-top: 20px;
  font-size: clamp(2.8rem, 5vw, 5.4rem);
  max-width: 980px;
}

.hero-title.compact {
  font-size: clamp(2.2rem, 4vw, 4rem);
}

.hero-copy {
  margin: 20px auto 0;
  max-width: 760px;
  font-size: 1.08rem;
}

.hero-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
  margin-top: 28px;
}

.section-block,
.discover-grid-wrap,
.related-block {
  padding: 56px 0 20px;
}

.container-xl {
  width: min(1440px, calc(100% - 32px));
  margin: 0 auto;
}

.showcase-block + .showcase-block {
  margin-top: 56px;
}

.section-head {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 24px;
  margin-bottom: 24px;
}

.section-link {
  border-radius: 999px !important;
  min-height: 46px;
  font-weight: 700 !important;
}

.stamp-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 22px;
}

.stamp-card,
.discover-card,
.highlight-card,
.buy-card,
.zoom-card,
.product-visual,
.mockup-thumb,
.empty-state,
.drawer-item,
.drawer-empty {
  border-radius: 28px;
  transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
}

.stamp-card,
.discover-card,
.mockup-thumb {
  overflow: hidden;
}

.stamp-card:hover,
.discover-card:hover,
.mockup-thumb:hover,
.drawer-item:hover {
  transform: translateY(-4px);
  box-shadow: var(--hover-shadow);
  border-color: rgba(var(--v-theme-primary), 0.36);
}

.stamp-media-wrap {
  aspect-ratio: 1 / 1;
  overflow: hidden;
  background: var(--bg-surface-2);
}

.stamp-media {
  width: 100%;
  height: 100%;
  background-position: center;
  background-size: cover;
  background-repeat: no-repeat;
  transition: transform 0.5s ease;
}

.stamp-card:hover .stamp-media {
  transform: scale(1.05);
}

.stamp-meta {
  padding: 18px;
}

.stamp-topline {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 8px;
}

.stamp-ref,
.dark-ref {
  color: var(--text-muted);
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.stamp-title,
.discover-title,
.drawer-item-info h4 {
  margin: 0;
  color: var(--text-main);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.stamp-swatch,
.swatch-large {
  display: inline-block;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
}

.stamp-swatch {
  width: 16px;
  height: 16px;
}

.discover-top {
  padding: 46px 0 28px;
  background: linear-gradient(180deg, rgba(var(--v-theme-primary), 0.06), transparent 90%);
}

.discover-top-inner {
  width: min(1200px, calc(100% - 32px));
  margin: 0 auto;
  text-align: center;
}

.search-shell {
  margin: 28px auto 0;
  max-width: 820px;
  min-height: 68px;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 0 20px;
}

.search-icon {
  color: var(--text-muted);
}

.search-input {
  height: 56px;
  border: 0;
  background: transparent;
  box-shadow: none;
  font-size: 1.05rem;
}

.filter-bar {
  margin: 22px auto 0;
  max-width: 1200px;
  padding: 10px;
  border-radius: 999px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: center;
}

.filter-chip {
  min-height: 42px;
  padding: 0 18px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--text-muted);
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.filter-chip.active,
.filter-chip:hover {
  background: var(--bg-surface);
  color: var(--text-main);
  border-color: var(--border-color);
}

.discover-container {
  padding-top: 22px;
}

.masonry-layout {
  column-count: 4;
  column-gap: 22px;
}

.masonry-item {
  break-inside: avoid;
  margin-bottom: 22px;
}

.discover-image {
  width: 100%;
  height: auto;
}

.discover-placeholder {
  min-height: 260px;
  display: grid;
  place-items: center;
  color: var(--text-muted);
  background: var(--bg-surface-2);
}

.discover-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: end;
  background: linear-gradient(180deg, rgba(0, 0, 0, 0.02) 30%, rgba(0, 0, 0, 0.72) 100%);
  opacity: 0;
  transition: opacity 0.25s ease;
}

.discover-card {
  position: relative;
}

.discover-card:hover .discover-overlay {
  opacity: 1;
}

.discover-overlay-inner {
  width: 100%;
  padding: 22px;
}

.discover-title,
.discover-category,
.dark-ref {
  color: #ffffff;
}

.discover-category {
  margin-top: 8px;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  opacity: 0.84;
}

.empty-state {
  min-height: 320px;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 32px;
}

.product-container {
  padding-top: 34px;
  padding-bottom: 42px;
}

.product-breadcrumb {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 20px;
}

.product-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.06fr) minmax(0, 0.94fr);
  gap: 28px;
  align-items: start;
}

.product-visual {
  position: relative;
  aspect-ratio: 4 / 5;
  min-height: 720px;
  overflow: hidden;
  background: radial-gradient(circle at center, rgba(var(--v-theme-primary), 0.06), transparent 35%), var(--bg-surface-2);
}

.pattern-fill,
.mockup-base,
.mockup-mask,
.mockup-shadow {
  position: absolute;
  inset: 0;
}

.pattern-fill.full {
  inset: 0;
}

.mockup-base,
.mockup-shadow {
  width: 100%;
  height: 100%;
  object-fit: contain;
  pointer-events: none;
}

.mockup-shadow {
  mix-blend-mode: multiply;
}

.zoom-card {
  margin-top: 18px;
  padding: 18px 20px;
}

.zoom-row {
  display: flex;
  align-items: center;
  gap: 14px;
}

.zoom-range {
  flex: 1;
  appearance: none;
  height: 6px;
  border-radius: 999px;
  background: var(--border-strong);
}

.zoom-range::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 22px;
  height: 22px;
  border-radius: 999px;
  border: 2px solid var(--bg-surface);
  background: rgb(var(--v-theme-primary));
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.2);
}

.zoom-caption {
  margin-top: 10px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  text-align: center;
}

.mockup-selector {
  margin-top: 20px;
}

.mockup-selector-title {
  margin-bottom: 12px;
  color: var(--text-main);
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

.mockup-list {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.mockup-thumb {
  width: 92px;
  height: 118px;
  padding: 8px;
  flex: 0 0 auto;
}

.mockup-thumb.active {
  border-color: rgba(var(--v-theme-primary), 0.72);
  box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.12);
}

.mockup-thumb img,
.drawer-item-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 20px;
}

.mockup-thumb-fallback {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  color: var(--text-muted);
}

.product-info-column {
  position: sticky;
  top: 110px;
}

.product-kicker {
  display: inline-flex;
  min-height: 34px;
  align-items: center;
  padding: 0 14px;
  border-radius: 999px;
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.product-title {
  margin-top: 18px;
  font-size: clamp(2.4rem, 4vw, 4.6rem);
}

.product-description {
  margin: 18px 0 0;
  font-size: 1.04rem;
}

.product-highlights {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  margin-top: 24px;
}

.highlight-card {
  min-height: 104px;
  padding: 18px;
  display: flex;
  align-items: center;
  gap: 14px;
}

.swatch-large {
  width: 52px;
  height: 52px;
}

.highlight-icon {
  width: 52px;
  height: 52px;
  border-radius: 18px;
  display: grid;
  place-items: center;
  background: var(--bg-surface-2);
  color: rgb(var(--v-theme-primary));
}

.highlight-label {
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.highlight-value {
  margin-top: 6px;
  color: var(--text-main);
  font-weight: 800;
}

.buy-card {
  margin-top: 18px;
  padding: 22px;
}

.buy-card-title {
  color: var(--text-main);
  font-size: 1.05rem;
  font-weight: 800;
  margin-bottom: 16px;
}

.buy-row {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: 14px;
}

.qty-box {
  min-height: 58px;
  border-radius: 18px;
  display: grid;
  grid-template-columns: 48px 1fr auto 48px;
  align-items: center;
  overflow: hidden;
}

.qty-btn {
  height: 100%;
  border: 0;
  background: transparent;
  color: var(--text-main);
  font-size: 1.5rem;
}

.qty-input {
  height: 100%;
  text-align: center;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
  font-size: 1.2rem;
  font-weight: 800;
}

.qty-unit {
  color: var(--text-muted);
  font-size: 0.95rem;
  font-weight: 700;
  padding-right: 8px;
}

/* =========================================================
   SUPER FOOTER PREMIUM
========================================================= */
.site-footer {
  position: relative;
  margin-top: 64px;
  background: var(--bg-surface);
  border-top: 1px solid var(--border-color);
  overflow: hidden;
}

.footer-glow-line {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(var(--v-theme-primary), 0.8), transparent);
  box-shadow: 0 0 15px rgba(var(--v-theme-primary), 0.6);
}

.footer-inner {
  padding: 64px 0 0;
}

.footer-main-grid {
  display: grid;
  grid-template-columns: 1.6fr 1fr 1fr 1.4fr;
  gap: 48px;
  margin-bottom: 56px;
}

.footer-brand-col .footer-logo {
  height: 42px;
  margin-bottom: 20px;
}

.brand-desc {
  color: var(--text-soft);
  font-size: 0.95rem;
  line-height: 1.7;
  max-width: 320px;
  margin-bottom: 24px;
}

.social-links {
  display: flex;
  gap: 12px;
}

.social-btn {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: var(--bg-surface-2);
  color: var(--text-main);
  display: grid;
  place-items: center;
  border: 1px solid var(--border-color);
  text-decoration: none;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.social-btn:hover {
  background: rgb(var(--v-theme-primary));
  border-color: rgb(var(--v-theme-primary));
  color: #fff;
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(var(--v-theme-primary), 0.3);
}

.nav-title {
  color: var(--text-main);
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: -0.01em;
  margin-bottom: 20px;
}

.nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.nav-list a {
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.95rem;
  font-weight: 600;
  transition: color 0.2s ease;
  position: relative;
  display: inline-block;
  width: fit-content;
}

.nav-list a::after {
  content: '';
  position: absolute;
  width: 0;
  height: 2px;
  bottom: -4px;
  left: 0;
  background-color: rgb(var(--v-theme-primary));
  transition: width 0.3s ease;
}

.nav-list a:hover {
  color: var(--text-main);
}

.nav-list a:hover::after {
  width: 100%;
}

.newsletter-desc {
  color: var(--text-soft);
  font-size: 0.9rem;
  margin-bottom: 16px;
  line-height: 1.5;
}

.newsletter-box {
  display: flex;
  align-items: center;
  height: 52px;
  border-radius: 16px;
  padding: 6px;
  margin-bottom: 24px;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.newsletter-box:focus-within {
  border-color: rgb(var(--v-theme-primary));
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1);
}

.newsletter-input {
  flex: 1;
  height: 100%;
  border: none;
  background: transparent;
  padding: 0 16px;
  color: var(--text-main);
  font-size: 0.9rem;
  outline: none;
}

.newsletter-btn {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: rgb(var(--v-theme-primary));
  color: #fff;
  border: none;
  display: grid;
  place-items: center;
  transition: transform 0.2s ease;
}

.newsletter-btn:hover {
  transform: scale(1.05);
}

.contact-info {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--text-muted);
  font-size: 0.85rem;
  font-weight: 600;
}

.contact-item .v-icon {
  color: rgb(var(--v-theme-primary));
}

.footer-bottom {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28px 0;
  border-top-color: var(--border-color) !important;
}

.copyright {
  color: var(--text-muted);
  font-size: 0.85rem;
  font-weight: 600;
}

.legal-links {
  display: flex;
  align-items: center;
  gap: 12px;
}

.legal-links a {
  color: var(--text-muted);
  font-size: 0.85rem;
  font-weight: 700;
  text-decoration: none;
  transition: color 0.2s ease;
}

.legal-links a:hover {
  color: var(--text-main);
}

.dot-separator {
  color: var(--text-muted);
  opacity: 0.5;
}

.security-badges {
  display: flex;
  align-items: center;
  gap: 16px;
  color: var(--text-muted);
}

.floating-whatsapp {
  position: fixed;
  right: 20px;
  bottom: 20px;
  z-index: 36;
  min-height: 54px;
  border: 0;
  border-radius: 999px;
  padding: 0 18px;
  display: flex;
  align-items: center;
  gap: 10px;
  background: #25d366;
  color: #ffffff;
  font-weight: 800;
  box-shadow: 0 18px 38px rgba(37, 211, 102, 0.34);
}

/* =========================================================
   NOVA MOBILE DOCK RESPONSIVA COM SCROLL HORIZONTAL
========================================================= */
.mobile-dock {
  position: fixed;
  left: 12px;
  right: 12px;
  bottom: 12px;
  z-index: 50;
  min-height: 74px;
  border-radius: 26px;
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  gap: 8px;
  padding: 8px 12px;
  align-items: center;
}

.dock-btn {
  flex: 0 0 68px; /* Força largura fixa pra scrollar em vez de espremer */
  scroll-snap-align: start;
  min-height: 58px;
  border: 0;
  background: transparent;
  border-radius: 18px;
  color: #6f492f;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 800;
  position: relative;
}

.dock-btn.active {
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
}

.dock-btn.danger {
  color: #ef4444;
}

/* Oculta scrollbar mas mantém funcionando */
.hide-scrollbar::-webkit-scrollbar { display: none; }
.hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

.moodboard-drawer {
  background: var(--bg-surface) !important;
}

.drawer-head,
.drawer-footer {
  padding: 18px;
}

.drawer-body {
  padding: 18px;
  background: var(--bg-main);
  min-height: calc(100vh - 180px);
}

.drawer-empty {
  min-height: 260px;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 24px;
}

.drawer-list {
  display: grid;
  gap: 12px;
}

.drawer-item {
  padding: 10px;
  display: grid;
  grid-template-columns: 76px 1fr auto;
  gap: 12px;
  align-items: center;
}

.drawer-item-image {
  height: 76px;
  border-radius: 8px;
  object-fit: cover;
}

.drawer-item-info h4 {
  margin: 0;
  font-size: 1rem;
}

.item-meta {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 4px;
}

.max-copy {
  max-width: 760px;
  margin-left: auto;
  margin-right: auto;
}

.invert-logo {
  filter: brightness(0) invert(1);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.24s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.content-scroll::-webkit-scrollbar,
.mockup-list::-webkit-scrollbar {
  width: 10px;
  height: 10px;
}

.content-scroll::-webkit-scrollbar-thumb,
.mockup-list::-webkit-scrollbar-thumb {
  background: var(--border-strong);
  border-radius: 999px;
}

/* BADGES FÍSICO/DIGITAL */
.badge-physical, .badge-digital {
  font-size: 9px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  padding: 2px 6px;
  border-radius: 4px;
}

.badge-physical {
  background: rgba(var(--v-theme-primary), 0.15);
  color: rgb(var(--v-theme-primary));
}

.badge-digital {
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
}

.item-meta {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-top: 4px !important;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 220px;
}

.item-qty {
  color: var(--text-main);
  font-weight: 700;
  font-size: 0.9rem;
  margin-top: 2px !important;
}

@media (max-width: 1399px) {
  .stamp-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  .masonry-layout { column-count: 3; }
}

@media (max-width: 1199px) {
  .product-grid { grid-template-columns: 1fr; }
  .product-info-column { position: static; }
  .footer-inner { grid-template-columns: 1fr 1fr; }
  .footer-main-grid {
    grid-template-columns: 1fr 1fr;
    gap: 40px;
  }
}

@media (max-width: 959px) {
  .view-wrap { padding-top: 0; padding-bottom: 96px; }
  .home-view,
  .discover-view,
  .product-view { min-height: 100vh; }
  .hero-block { min-height: 62vh; border-radius: 0 0 28px 28px; }
  .hero-container { min-height: 62vh; }
  .stamp-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .masonry-layout { column-count: 2; }
  .buy-row { grid-template-columns: 1fr; }
  .product-highlights { grid-template-columns: 1fr; }
  .floating-whatsapp { bottom: 100px; }
}

@media (max-width: 767px) {
  .section-head { flex-direction: column; align-items: stretch; }

  .stamp-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }
  .stamp-meta {
    padding: 10px;
  }
  .stamp-title {
    font-size: 0.85rem;
  }
  .stamp-ref {
    font-size: 9px;
  }
  .stamp-card {
    border-radius: 20px;
  }

  .masonry-layout {
    column-count: 2;
    column-gap: 12px;
  }
  .masonry-item {
    margin-bottom: 12px;
  }
  .discover-overlay-inner {
    padding: 12px;
  }
  .discover-title {
    font-size: 0.95rem;
  }
  .discover-category {
    font-size: 9px;
    margin-top: 4px;
  }

  .product-visual { min-height: 420px; }
  .container-xl,
  .discover-top-inner,
  .header-inner { width: min(100%, calc(100% - 20px)); }
  .footer-inner { grid-template-columns: 1fr; }

  .footer-main-grid {
    grid-template-columns: 1fr;
    gap: 32px;
  }
  .brand-desc {
    max-width: 100%;
  }
  .footer-bottom {
    flex-direction: column;
    gap: 16px;
    text-align: center;
  }
}

@media (max-width: 479px) {
  .mobile-dock { left: 8px; right: 8px; bottom: 8px; padding: 6px; }
  .dock-btn { min-height: 56px; font-size: 10px; flex: 0 0 62px; }
  .floating-whatsapp { right: 12px; }
}

/* =========================================
   HEADER NAV - EXTREMIDADES REAIS E FLUIDEZ
========================================== */

.custom-premium-glass {
  background-color: color-mix(in srgb, var(--bg-surface) 60%, transparent) !important;
  backdrop-filter: blur(12px) !important;
  -webkit-backdrop-filter: blur(12px) !important;
  border-bottom: 1px solid var(--border-color) !important;
  transition: background-color 0.3s ease, border-color 0.3s ease;
  height: clamp(64px, 5.5vw, 98px);
  display: flex;
  align-items: center;
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0 clamp(16px, 3vw, 48px);
  gap: clamp(8px, 1.5vw, 24px);
  max-width: 100% !important;
  margin: 0 !important;
  min-width: 0;
}

.brand-logo.header-logo {
  height: clamp(32px, 3vw, 70px) !important;
  width: auto;
  object-fit: contain;
}

.header-nav {
  display: flex !important;
  flex-direction: row !important;
  align-items: center;
  justify-content: center;
  flex-wrap: nowrap !important;
  gap: clamp(2px, 0.6vw, 16px);
  flex: 1;
  min-width: 0;
  overflow: visible !important;
}

.header-nav .nav-link,
.header-nav .premium-vip-btn {
  white-space: nowrap !important;
  display: inline-flex;
  align-items: center;
  font-size: clamp(9px, 0.75vw, 14px) !important;
  padding: clamp(4px, 0.4vw, 8px) clamp(4px, 0.5vw, 12px) !important;
  letter-spacing: -0.02em;
  font-weight: 600;
  flex-shrink: 0 !important;
}

.header-brand,
.header-actions {
  flex-shrink: 0 !important;
  display: flex;
  align-items: center;
}

.header-actions {
  gap: clamp(8px, 1vw, 16px);
}

/* =========================================================
   PREMIUM LOCK WALL (APPLE / EXCLUSIVE STYLE)
========================================================= */
.premium-lock-view {
  position: relative;
  min-height: calc(100vh - 82px);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: var(--bg-main);
  padding: 24px;
}

.lock-bg-pattern {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(var(--border-strong) 1px, transparent 1px);
  background-size: 32px 32px;
  opacity: 0.5;
}

.lock-glow-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.25;
  z-index: 0;
  animation: orbFloat 12s ease-in-out infinite alternate;
}
.theme-light .lock-glow-orb { opacity: 0.15; }

.orb-1 {
  width: 450px; height: 450px;
  background: rgb(var(--v-theme-primary));
  top: -10%; right: -5%;
}
.orb-2 {
  width: 550px; height: 550px;
  background: #F59E0B;
  bottom: -20%; left: -10%;
  animation-delay: -6s;
}

@keyframes orbFloat {
  0% { transform: translate(0, 0) scale(1); }
  100% { transform: translate(-40px, 60px) scale(1.15); }
}

.premium-lock-card {
  position: relative;
  z-index: 2;
  max-width: 800px;
  width: 100%;
  padding: clamp(40px, 6vw, 72px) clamp(24px, 5vw, 64px);
  border-radius: 40px;
  text-align: center;
  box-shadow: var(--hero-shadow);
  background: var(--bg-elevated);
}

.lock-icon-wrapper {
  width: 96px;
  height: 96px;
  margin: 0 auto 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.08), transparent);
  border: 1px solid var(--border-color);
  box-shadow: inset 0 2px 16px rgba(255,255,255,0.03);
}

.theme-light .lock-icon-wrapper {
  background: var(--bg-surface);
  box-shadow: 0 8px 24px rgba(0,0,0,0.04);
}

.lock-title {
  background: linear-gradient(110deg, var(--text-main) 30%, var(--text-muted) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  line-height: 1.1;
}

.lock-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

.lock-btn {
  min-width: 240px;
  font-weight: 800 !important;
  letter-spacing: 0.02em;
}

.primary-lock-btn {
  box-shadow: 0 8px 28px rgba(var(--v-theme-primary), 0.35) !important;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}
.primary-lock-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 32px rgba(var(--v-theme-primary), 0.5) !important;
}

.secondary-lock-btn {
  border-width: 2px !important;
  background: transparent !important;
}

/* INPUT VIP */
.mj-input {
  width: 100%; height: 56px; padding: 0 16px;
  background: var(--bg-surface-variant); border: 1px solid var(--border-color);
  border-radius: 12px; color: var(--text-main); font-size: 1rem;
  transition: all 0.2s ease; outline: none;
}
.mj-input:focus {
  border-color: rgba(245, 158, 11, 0.6); box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.15); background: var(--bg-surface);
}
.code-input-vip {
  letter-spacing: 0.4em; text-transform: uppercase; font-size: 1.5rem; height: 64px;
}
.btn-3d {
  border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
  transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important;
}
.btn-3d:active {
  transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.layout-fade-enter-active,
.layout-fade-leave-active {
  transition: opacity 0.3s ease;
}

.layout-fade-enter-from,
.layout-fade-leave-to {
  opacity: 0;
}

/* =========================================================
   NOVA ESTRUTURA VIP LOCK (SPLIT LAYOUT, TIMELINE & 3D)
========================================================= */
.premium-lock-view {
  position: relative;
  min-height: 100vh;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding-top: 82px; /* Garante que o header não corte */
  overflow: hidden;
}

.lock-bg-pattern {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(var(--border-strong) 1px, transparent 1px);
  background-size: 32px 32px;
  opacity: 0.5;
}

.lock-container {
  max-width: 1300px;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  margin: 0 auto;
}

.vip-split-layout {
  display: grid;
  grid-template-columns: 1fr;
  width: 100%;
  gap: 32px;
  position: relative;
  align-items: stretch;
}

@media (min-width: 1024px) {
  .vip-split-layout {
    grid-template-columns: minmax(0, 1fr) 520px; /* Trava o formulário em 520px, a esquerda fica fluida */
    gap: 40px;
  }
}

/* --- LADO ESQUERDO: SHOWCASE (A DIV ELEGANTE) --- */
.vip-showcase-wrapper {
  position: relative;
  z-index: 20; /* Fica acima na animação pra cobrir o card saindo */
  display: flex; flex-direction: column; justify-content: center;
  padding: 48px; border-radius: 32px;
  box-shadow: 0 20px 50px rgba(0,0,0,0.1);
  min-width: 0; /* Impede que o carrossel estoure o Grid */
  overflow: hidden;
}

.vip-eyebrow {
  display: inline-flex; align-items: center; padding: 6px 16px; border-radius: 999px;
  background: rgba(245, 158, 11, 0.1); color: #f59e0b; font-weight: 800;
  font-size: 11px; letter-spacing: 0.15em; text-transform: uppercase;
  border: 1px solid rgba(245, 158, 11, 0.2); width: fit-content;
}

.showcase-title { font-size: clamp(2rem, 3vw, 3.2rem); font-weight: 900; line-height: 1.05; letter-spacing: -0.04em; }
.showcase-desc { font-size: 1.05rem; line-height: 1.6; max-width: 480px; }

/* Carrossel Interativo */
.showcase-gallery { width: 100%; overflow: hidden; position: relative; padding: 10px 0; }
.showcase-gallery::before, .showcase-gallery::after {
  content: ''; position: absolute; top: 0; width: 60px; height: 100%; z-index: 2;
}
.showcase-gallery::before { left: 0; background: linear-gradient(to right, var(--bg-surface) 0%, transparent 100%); }
.showcase-gallery::after { right: 0; background: linear-gradient(to left, var(--bg-surface) 0%, transparent 100%); }

.gallery-track { display: flex; gap: 16px; width: max-content; animation: scrollInfinite 25s linear infinite; }
.gallery-track:hover { animation-play-state: paused; }
@keyframes scrollInfinite { from { transform: translateX(0); } to { transform: translateX(-50%); } }

.gallery-item {
  width: 140px; aspect-ratio: 3/4; border-radius: 16px; overflow: hidden;
  background: var(--bg-surface-2); border: 1px solid var(--border-color);
  transition: filter 0.3s ease, transform 0.3s ease; flex-shrink: 0; cursor: default;
  position: relative;
}
.gallery-img { width: 100%; height: 100%; object-fit: cover; }

/* Efeito Blur Exclusivo (Anti-plágio visual) */
.gallery-item.is-exclusive .gallery-img {
  filter: blur(12px) brightness(0.7) contrast(1.2);
}
.exclusive-badge {
  position: absolute; top: 12px; left: 50%; transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.7); color: #fff; font-size: 9px; font-weight: 900;
  padding: 4px 10px; border-radius: 999px; letter-spacing: 0.15em;
  border: 1px solid rgba(255, 255, 255, 0.2); z-index: 5;
  display: flex; align-items: center; white-space: nowrap;
}
.gallery-item:not(.is-exclusive):hover { filter: blur(5px); transform: scale(0.95); }

/* Card 3D Inclinado */
.tilted-3d-card {
  padding: 24px; border-radius: 20px; max-width: 420px;
  transform: perspective(1000px) rotateX(8deg) rotateY(8deg); transform-style: preserve-3d;
  box-shadow: 10px 20px 30px rgba(0,0,0,0.1);
  transition: transform 0.4s ease, box-shadow 0.4s ease;
}
.tilted-3d-card:hover { transform: perspective(1000px) rotateX(2deg) rotateY(2deg) translateY(-5px); box-shadow: 5px 10px 20px rgba(0,0,0,0.15); }
.tilted-icon { width: 56px; height: 56px; border-radius: 14px; display: grid; place-items: center; }

/* --- LADO DIREITO: O CARD DO FORMULÁRIO --- */
.lock-card-wrapper {
  position: relative; z-index: 10;
  animation: slideOutFromBehind 1s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  display: flex;
}
@keyframes slideOutFromBehind {
  0% { transform: translateX(-100%); opacity: 0; }
  100% { transform: translateX(0); opacity: 1; }
}

.premium-lock-card {
  border-radius: 32px;
  box-shadow: 0 20px 50px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.05);
  min-height: 640px; /* Altura mínima pra distribuir bem os espaços no flex */
}

/* ELEMENTOS DO FORMULÁRIO E TIMELINE */
.status-icon-wrapper { width: 64px; height: 64px; border-radius: 20px; display: flex; align-items: center; justify-content: center; }
.status-icon-wrapper.primary { background: rgba(var(--v-theme-primary), 0.1); border: 1px solid rgba(var(--v-theme-primary), 0.2); }
.section-title { font-size: 1.8rem; font-weight: 800; color: var(--text-main); letter-spacing: -0.03em; margin: 0 0 8px 0; }
.section-copy { color: var(--text-soft); font-size: 0.95rem; line-height: 1.5; margin: 0; }
.text-muted-custom { color: var(--text-muted) !important; }
.text-main-custom { color: var(--text-main) !important; }

/* OPÇÕES */
.options-group { display: flex; flex-direction: column; gap: 12px; width: 100%; }
.source-card { height: 52px; border-radius: 12px; background: var(--bg-surface-variant); border: 1px solid var(--border-color); font-weight: 600; font-size: 0.9rem; color: var(--text-main); transition: all 0.2s ease; cursor: pointer; text-align: left; padding: 0 16px; }
.source-card:hover { border-color: var(--border-focus); background: var(--bg-surface); }
.source-card.active { background: rgba(var(--v-theme-primary), 0.05); color: rgb(var(--v-theme-primary)); border-color: rgb(var(--v-theme-primary)); box-shadow: inset 0 0 0 1px rgb(var(--v-theme-primary)); }

/* INPUT VIP */
.security-input-box { margin-bottom: 24px; }
.code-input { width: 100%; height: 64px; background: var(--bg-surface-variant); border: 2px dashed var(--border-focus); border-radius: 16px; color: rgb(var(--v-theme-primary)); font-size: 2rem; font-weight: 900; letter-spacing: 0.4em; text-align: center; transition: all 0.2s ease; outline: none; }
.code-input:focus { border-style: solid; border-color: rgb(var(--v-theme-primary)); background: var(--bg-surface); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
.code-input::placeholder { color: var(--text-muted); opacity: 0.4; }

/* BOTÕES: Trava rigorosa de altura pra NÃO virar sanfona! */
.giant-fix-btn, .cta-btn {
  height: 56px !important; min-height: 56px !important; max-height: 56px !important;
  flex: 0 0 auto !important; border-radius: 12px !important; font-weight: 800 !important;
  font-size: 1.05rem !important; letter-spacing: 0.02em;
}

.divider-container { display: flex; align-items: center; }
.divider-line { flex: 1; height: 1px; background: var(--border-color); }
.divider-text { padding: 0 12px; font-size: 0.7rem; font-weight: 800; letter-spacing: 0.1em; }

/* MINI BOTÕES WHATSAPP E EMAIL */
.mini-social-btn {
  flex: 1; height: 48px; border-radius: 12px; font-weight: 800; font-size: 0.85rem;
  display: flex; align-items: center; justify-content: center; gap: 8px; cursor: pointer;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
}
.email-btn { background: var(--bg-surface-variant); border: 1px solid var(--border-color); color: var(--text-main); }
.email-btn:hover { background: var(--bg-surface); }
.email-btn:active { transform: translateY(2px); }

.wa-premium-btn {
  background: linear-gradient(180deg, #25D366 0%, #128C7E 100%); color: #ffffff; border: none;
  box-shadow: 0 4px 12px rgba(37, 211, 102, 0.4), inset 0 1px 0 rgba(255,255,255,0.2);
  position: relative; overflow: hidden;
}
.wa-premium-btn:active { transform: translateY(2px); box-shadow: 0 2px 4px rgba(37, 211, 102, 0.4); }
.wa-premium-btn::before {
  content: ''; position: absolute; top: 0; left: -100%; width: 50%; height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.5), transparent);
  transform: skewX(-20deg); animation: shine 3s infinite;
}

/* TIMELINE */
.timeline-header { position: relative; }
.timeline-track { position: absolute; top: 50%; left: 0; right: 0; height: 2px; background: var(--border-color); transform: translateY(-50%); z-index: 1; }
.timeline-progress { height: 100%; background: rgb(var(--v-theme-primary)); transition: width 0.4s ease; }
.timeline-steps { position: relative; z-index: 2; display: flex; justify-content: space-between; }
.step-dot { width: 32px; height: 32px; display: grid; place-items: center; border-radius: 50%; background: var(--bg-surface); border: 2px solid var(--border-color); color: var(--text-muted); font-weight: 700; font-size: 13px; transition: all 0.3s ease; }
.step-dot.active { background: rgb(var(--v-theme-primary)); border-color: rgb(var(--v-theme-primary)); color: #fff; }

.slide-x-enter-active, .slide-x-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.slide-x-enter-from { opacity: 0; transform: translateX(20px); }
.slide-x-leave-to { opacity: 0; transform: translateX(-20px); }

@media (max-width: 599px) {
  .code-input { font-size: 1.5rem; letter-spacing: 0.3em; height: 56px; }
  .premium-lock-card { padding: 32px 20px !important; min-height: auto; }
  .vip-showcase-wrapper { padding: 32px 20px; border-radius: 20px; }
}
</style>
