<template>
  <v-app>
    <transition name="fade-boot">
      <div v-if="isBooting" class="enterprise-boot-screen">
        <div class="boot-content">
          <img :src="currentLogo" alt="MJ Process" class="boot-logo pulse-anim" />
          <div class="boot-loader-container">
            <div class="boot-loader-bar" :style="{ width: bootProgress + '%' }"></div>
          </div>
          <div class="boot-text font-monospace">{{ t.bootingText }}</div>
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
            <a href="#pilares">{{ t.nav.pillars }}</a>
            <a href="#arquitetura">{{ t.nav.architecture }}</a>
            <a href="#modulos">{{ t.nav.ecosystem }}</a>
            <a href="#planos">{{ t.nav.plans }}</a>
          </nav>

          <div class="header-actions">
            <v-menu transition="slide-y-transition" :close-on-content-click="true" location="bottom end">
              <template v-slot:activator="{ props }">
                <v-btn variant="text" v-bind="props" class="lang-btn font-weight-bold px-2">
                  <span class="mr-1 text-h6">{{ currentFlag }}</span> {{ currentLang.toUpperCase() }} <v-icon right>mdi-chevron-down</v-icon>
                </v-btn>
              </template>
              <v-list bg-color="var(--bg-surface)" class="border rounded-lg shadow-sm pa-1">
                <v-list-item @click="setLang('pt')" class="rounded mb-1" :active="currentLang === 'pt'" active-color="primary">
                  <template v-slot:prepend><span class="text-h6 mr-3">🇧🇷</span></template>
                  <v-list-item-title class="font-weight-medium">Português</v-list-item-title>
                </v-list-item>
                <v-list-item @click="setLang('en')" class="rounded mb-1" :active="currentLang === 'en'" active-color="primary">
                  <template v-slot:prepend><span class="text-h6 mr-3">🇺🇸</span></template>
                  <v-list-item-title class="font-weight-medium">English</v-list-item-title>
                </v-list-item>
                <v-list-item @click="setLang('es')" class="rounded" :active="currentLang === 'es'" active-color="primary">
                  <template v-slot:prepend><span class="text-h6 mr-3">🇪🇸</span></template>
                  <v-list-item-title class="font-weight-medium">Español</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>

            <v-btn icon variant="text" @click="toggleTheme" class="theme-btn ml-2">
              <v-icon>{{ isDark ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon>
            </v-btn>
            <a href="https://webmail.suaempresa.com" target="_blank" class="webmail-link ml-2">Webmail</a>
            <v-btn color="primary" variant="flat" class="login-btn ml-2" @click="initiateBootSequence">{{ t.nav.login }}</v-btn>
          </div>
        </div>
      </header>

      <div :class="['lang-transition-wrapper', { 'is-animating': isAnimatingLang }]">
        <main>
          <section class="hero-section">
            <div class="hero-glow"></div>
            <v-container class="hero-text-container reveal-up">
              <div class="d-flex justify-center w-100 mb-6">
                <div class="badge-premium">{{ t.hero.badge }}</div>
              </div>
              <h1 class="colossal-title" v-html="t.hero.title"></h1>
              <p class="hero-subtitle mx-auto mt-6">{{ t.hero.subtitle }}</p>
              <div class="d-flex justify-center flex-wrap gap-4 mt-10">
                <v-btn size="x-large" color="primary" variant="flat" class="font-weight-bold rounded-lg px-8 hero-btn-glow" @click="scrollToElement('#trial-form')">
                  {{ t.hero.ctaPrimary }}
                </v-btn>
                <v-btn size="x-large" variant="outlined" class="font-weight-bold rounded-lg px-8 mj-btn-outline" @click="scrollToElement('#pilares')">
                  {{ t.hero.ctaSecondary }}
                </v-btn>
              </div>
            </v-container>
            <v-container class="dashboard-3d-container reveal-up" style="transition-delay: 200ms;">
              <div class="dashboard-wrapper">
                <img :src="currentDashboard" alt="Dashboard MJ Process" class="dashboard-img" />
              </div>
            </v-container>
          </section>

          <section id="pilares" class="section-padding">
            <v-container>
              <div class="section-header reveal-up">
                <h2 class="tracking-tight">{{ t.pillars.sectionTitle }}</h2>
                <p>{{ t.pillars.sectionDesc }}</p>
              </div>

              <v-row class="mb-16">
                <v-col cols="12" md="6" class="reveal-up" v-for="(pillar, idx) in t.pillars.items" :key="idx" :style="{ 'transition-delay': (idx * 50) + 'ms' }">
                  <div class="mj-card pillar-card h-100">
                    <div :class="['pillar-icon', pillar.bgClass, pillar.textClass]"><v-icon size="32">{{ pillar.icon }}</v-icon></div>
                    <h3 class="text-h4 font-weight-bold mb-4 mt-6">{{ pillar.title }}</h3>
                    <p class="text-body-1 muted-text mb-6">{{ pillar.desc }}</p>
                    <div class="pillar-glow"></div>
                  </div>
                </v-col>
              </v-row>

              <div class="benefits-carousel-wrapper reveal-up" style="transition-delay: 300ms;">
                <div class="d-flex align-center justify-space-between mb-6">
                  <h4 class="text-h5 font-weight-bold">{{ t.carousel.title }}</h4>
                  <div class="carousel-controls">
                    <v-btn icon="mdi-chevron-left" variant="tonal" size="small" class="mr-2" @click="scrollCarousel(-1)"></v-btn>
                    <v-btn icon="mdi-chevron-right" variant="tonal" size="small" @click="scrollCarousel(1)"></v-btn>
                  </div>
                </div>
                <div class="benefits-carousel" ref="benefitsCarousel">
                  <div class="carousel-item mj-card pa-6" v-for="(item, idx) in t.carousel.items" :key="idx">
                    <v-icon :color="item.color" size="28" class="mb-3">{{ item.icon }}</v-icon>
                    <h5 class="font-weight-bold mb-2">{{ item.title }}</h5>
                    <p class="text-caption muted-text">{{ item.desc }}</p>
                  </div>
                </div>
              </div>
            </v-container>
          </section>

          <section id="arquitetura" class="section-padding bg-alternate position-relative overflow-hidden">
            <div class="ambient-clouds"></div>
            <v-container class="position-relative z-1">
              <div class="section-header reveal-up">
                <h2 class="tracking-tight">{{ t.architecture.title }}</h2>
                <p>{{ t.architecture.desc }}</p>
              </div>

              <div class="neural-network-layout mt-16 reveal-up">
                <svg class="neural-lines" viewBox="0 0 1000 400" preserveAspectRatio="xMidYMid meet">
                  <path d="M 200 100 Q 350 100 500 200 T 800 100" class="data-flow-line" />
                  <path d="M 200 300 Q 350 300 500 200 T 800 300" class="data-flow-line delay-1" />
                  <circle cx="500" cy="200" r="4" class="data-particle" />
                  <circle cx="200" cy="100" r="4" class="data-particle delay-1" />
                  <circle cx="800" cy="300" r="4" class="data-particle delay-2" />
                </svg>

                <div class="neural-nodes-container">
                  <div class="neural-side">
                    <div class="neural-node mj-card">
                      <v-icon color="info" size="32" class="mb-2">mdi-cloud-lock-outline</v-icon>
                      <h4 class="font-weight-bold mb-1">{{ t.architecture.nodes[0].title }}</h4>
                      <p class="text-caption muted-text">{{ t.architecture.nodes[0].desc }}</p>
                    </div>
                    <div class="neural-node mj-card">
                      <v-icon color="warning" size="32" class="mb-2">mdi-lightning-bolt</v-icon>
                      <h4 class="font-weight-bold mb-1">{{ t.architecture.nodes[1].title }}</h4>
                      <p class="text-caption muted-text">{{ t.architecture.nodes[1].desc }}</p>
                    </div>
                  </div>

                  <div class="neural-core">
                    <div class="core-orb">
                      <div class="orb-glow"></div>
                      <v-icon size="56" color="white" class="mb-2 position-relative z-1">mdi-database-outline</v-icon>
                      <span class="font-weight-black tracking-widest text-white position-relative z-1 text-caption">POSTGRESQL</span>
                    </div>
                  </div>

                  <div class="neural-side">
                    <div class="neural-node mj-card">
                      <v-icon color="success" size="32" class="mb-2">mdi-shield-check</v-icon>
                      <h4 class="font-weight-bold mb-1">{{ t.architecture.nodes[2].title }}</h4>
                      <p class="text-caption muted-text">{{ t.architecture.nodes[2].desc }}</p>
                    </div>
                    <div class="neural-node mj-card">
                      <v-icon color="secondary" size="32" class="mb-2">mdi-api</v-icon>
                      <h4 class="font-weight-bold mb-1">{{ t.architecture.nodes[3].title }}</h4>
                      <p class="text-caption muted-text">{{ t.architecture.nodes[3].desc }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </v-container>
          </section>

          <section id="modulos" class="modules-section">
            <div class="sticky-title border-b">
              <h2 class="gradient-text colossal-title-center">{{ t.ecosystem.title }}</h2>
            </div>

            <v-container class="modules-container">
              <v-row class="module-row align-center" v-for="(mod, idx) in modulesList" :key="mod.id" :class="{ 'flex-md-row-reverse': idx % 2 !== 0, 'mt-32': idx > 0 }">
                <v-col cols="12" md="5" :class="idx % 2 !== 0 ? 'reveal-right pl-md-12' : 'reveal-left'">
                  <v-avatar :color="mod.color" variant="tonal" size="64" class="mb-6"><v-icon size="32">{{ mod.icon }}</v-icon></v-avatar>
                  <h3 class="text-h3 font-weight-black mb-6 tracking-tight">{{ mod.title }}</h3>
                  <p class="text-h6 muted-text mb-6 line-height-tight">{{ mod.description }}</p>
                  <ul class="feature-list module-features">
                    <li v-for="(feat, i) in mod.features.slice(0, 2)" :key="i">
                      <v-icon :color="mod.color">mdi-check-circle</v-icon> <span>{{ feat }}</span>
                    </li>
                  </ul>
                </v-col>
                <v-col cols="12" md="7" class="perspective-wrapper" :class="idx % 2 !== 0 ? 'reveal-left' : 'reveal-right'">
                  <div :class="['tilted-mockup', idx % 2 !== 0 ? 'right-tilt' : 'left-tilt', 'mj-card pa-1 h-100 module-visual overflow-hidden interactive-mockup']" @click="openModal(mod.id)">
                     <div class="expand-hint"><v-icon size="24" class="mr-2">mdi-magnify-plus-outline</v-icon> {{ t.ecosystem.inspectBtn }}</div>
                     <img v-if="!mod.isHtml" :src="isDark ? mod.darkImg : mod.lightImg" class="w-100 rounded-lg mockup-image object-cover" />

                     <div v-else class="mockup-image d-flex flex-column h-100 w-100 pointer-events-none">
                       <div class="chat-header d-flex align-center justify-space-between bg-surface pa-3 border-b">
                         <div class="d-flex align-center gap-3">
                           <v-avatar color="secondary" size="36" class="text-white font-weight-bold">DS</v-avatar>
                           <div>
                             <div class="font-weight-bold text-body-1 line-height-tight">{{ t.chatMockup.team }}</div>
                             <div class="text-caption text-success d-flex align-center gap-1"><span class="dot-online"></span> {{ t.chatMockup.online }}</div>
                           </div>
                         </div>
                         <v-icon color="grey">mdi-dots-vertical</v-icon>
                       </div>
                       <div class="chat-body pa-4 flex-grow-1 d-flex flex-column gap-3 bg-alternate">
                          <div class="bubble left">{{ t.chatMockup.msg1 }}</div>
                          <div class="bubble right">{{ t.chatMockup.msg2 }}</div>
                          <div class="bubble right bg-transparent pa-0"><img src="https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=300&auto=format&fit=crop" class="rounded-lg border" style="max-width: 200px;"/></div>
                          <div class="bubble left typing"><span class="dot"></span><span class="dot"></span><span class="dot"></span></div>
                       </div>
                       <div class="chat-input-area pa-3 bg-surface border-t d-flex align-center gap-2">
                          <v-icon color="grey">mdi-paperclip</v-icon>
                          <div class="flex-grow-1 bg-alternate border rounded-pill px-4 py-2 text-caption muted-text">{{ t.chatMockup.placeholder }}</div>
                          <v-btn icon="mdi-send" color="secondary" size="small" variant="flat"></v-btn>
                       </div>
                     </div>
                  </div>
                </v-col>
              </v-row>
            </v-container>
          </section>

          <section id="planos" class="section-padding bg-alternate">
            <v-container>
              <div class="section-header reveal-up">
                <h2 class="tracking-tight">{{ t.pricing.title }}</h2>
                <p>{{ t.pricing.desc }}</p>
              </div>

              <v-row class="mb-16 justify-center">
                <v-col cols="12" md="6" xl="3" v-for="(plan, idx) in t.pricing.plans" :key="idx">
                  <div :class="['mj-card pricing-card h-100 reveal-up', plan.highlight ? 'highlighted' : '', plan.dark ? 'dark-force' : '']" :style="{ 'transition-delay': (idx * 100) + 'ms' }">
                    <div v-if="plan.highlight" class="popular-badge">{{ t.pricing.popularBadge }}</div>
                    <span :class="['plan-name', plan.highlight ? 'text-primary' : (plan.dark ? 'text-grey-lighten-1' : '')]">{{ plan.tier }}</span>
                    <h3 :class="['text-h3 font-weight-black mb-2 mt-2', plan.highlight ? 'text-primary' : (plan.dark ? 'text-white' : '')]">{{ plan.name }}</h3>
                    <div :class="['price', plan.highlight ? 'text-primary' : (plan.dark ? 'text-white' : '')]">{{ plan.price }}<span v-if="plan.period">{{ plan.period }}</span></div>
                    <p :class="['plan-desc mb-6 pb-6', plan.highlight ? 'border-b-primary' : (plan.dark ? 'border-b-grey' : 'border-b')]">{{ plan.desc }}</p>
                    <ul :class="['plan-features mb-8', plan.dark ? 'text-white' : '']">
                      <li><v-icon :color="plan.dark ? 'white' : 'primary'">{{ plan.userLimitIcon }}</v-icon> <strong>{{ plan.userLimit }}</strong></li>
                      <li :class="['text-caption ml-8 mt-n2 pb-4 w-100 opacity-50', plan.highlight ? 'border-b-primary' : (plan.dark ? 'border-b-grey' : 'border-b')]">{{ plan.extraUser }}</li>
                      <li v-for="(feat, fIdx) in plan.features" :key="fIdx"><v-icon :color="plan.dark ? 'white' : (plan.highlight ? 'primary' : 'success')">mdi-check</v-icon> {{ feat }}</li>
                    </ul>
                    <v-btn :color="plan.btnColor" :variant="plan.btnVariant" block size="x-large" class="mt-auto rounded-lg font-weight-bold elevation-4" @click="scrollToElement('#trial-form')">{{ plan.btnText }}</v-btn>
                  </div>
                </v-col>
              </v-row>

              <div class="comparison-grid-wrapper mt-16 reveal-up">
                <h3 class="text-h4 font-weight-black text-center mb-10">{{ t.pricing.compareTitle }}</h3>
                <div class="mj-card pa-0 overflow-hidden custom-table-wrapper">
                  <table class="w-100 text-left comparison-table">
                    <thead>
                      <tr>
                        <th class="pa-6 text-h6 font-weight-bold w-25 border-b sticky-col bg-alternate">{{ t.pricing.table.col1 }}</th>
                        <th class="pa-6 text-center font-weight-bold border-b text-h6 bg-alternate">{{ t.pricing.plans[0].name }}</th>
                        <th class="pa-6 text-center font-weight-bold text-primary bg-primary-lighten border-b text-h6">{{ t.pricing.plans[1].name }} <v-chip color="primary" size="x-small" class="ml-2">HOT</v-chip></th>
                        <th class="pa-6 text-center font-weight-bold border-b text-h6 bg-alternate">{{ t.pricing.plans[2].name }}</th>
                        <th class="pa-6 text-center font-weight-bold border-b bg-black-force text-white text-h6">{{ t.pricing.plans[3].name }}</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr class="table-row" v-for="(row, idx) in t.pricing.table.rows" :key="idx">
                        <td class="pa-5 border-b font-weight-medium sticky-col bg-surface">{{ row.feat }}</td>
                        <td class="pa-5 border-b text-center text-body-2 muted-text" v-html="row.b"></td>
                        <td class="pa-5 border-b text-center bg-primary-lighten text-primary font-weight-bold" v-html="row.p"></td>
                        <td class="pa-5 border-b text-center font-weight-bold" v-html="row.bu"></td>
                        <td class="pa-5 border-b text-center bg-black-force text-white font-weight-bold" v-html="row.e"></td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </v-container>
          </section>

          <section id="trial-form" class="section-padding">
            <v-container class="reveal-up max-w-1200">
              <div class="mj-card cta-card pa-0 overflow-hidden d-flex flex-column flex-lg-row">
                <div class="cta-left bg-alternate pa-10 pa-lg-16 d-flex flex-column justify-center flex-grow-1 border-r position-relative overflow-hidden w-100 w-lg-50">
                  <div class="cta-glow-bg"></div>
                  <div class="position-relative z-1">
                    <v-icon size="48" color="primary" class="mb-6">mdi-rocket-launch-outline</v-icon>
                    <h2 class="text-h3 font-weight-black mb-6 tracking-tight line-height-tight" v-html="t.form.title"></h2>
                    <p class="text-h6 muted-text mb-8">{{ t.form.desc }}</p>

                    <div class="d-flex flex-column gap-5">
                      <div class="d-flex align-center gap-4" v-for="(bullet, idx) in t.form.bullets" :key="idx">
                        <v-avatar color="success-lighten" size="40"><v-icon color="success" size="20">{{ bullet.icon }}</v-icon></v-avatar>
                        <span class="font-weight-medium text-body-1">{{ bullet.text }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="cta-right pa-10 pa-lg-16 bg-surface flex-grow-1 w-100 w-lg-50">
                  <h3 class="text-h4 font-weight-bold mb-3">{{ t.form.formTitle }}</h3>
                  <p class="text-body-1 muted-text mb-8">{{ t.form.formDesc }}</p>

                  <form class="premium-custom-form d-flex flex-column gap-4" @submit.prevent="submitContactForm">
                    <div class="input-group">
                      <label class="form-label">{{ t.form.fields.name.label }}</label>
                      <input type="text" class="mj-premium-input" :placeholder="t.form.fields.name.placeholder" required />
                    </div>

                    <div class="input-group">
                      <label class="form-label">{{ t.form.fields.email.label }}</label>
                      <input type="email" class="mj-premium-input" :placeholder="t.form.fields.email.placeholder" required />
                    </div>

                    <div class="d-flex flex-column flex-sm-row gap-4">
                      <div class="input-group flex-grow-1">
                        <label class="form-label">{{ t.form.fields.phone.label }}</label>
                        <input type="tel" class="mj-premium-input" :placeholder="t.form.fields.phone.placeholder" required />
                      </div>
                      <div class="input-group flex-grow-1">
                        <label class="form-label">{{ t.form.fields.role.label }}</label>
                        <input type="text" class="mj-premium-input" :placeholder="t.form.fields.role.placeholder" required />
                      </div>
                    </div>

                    <div class="input-group mb-4">
                      <label class="form-label">{{ t.form.fields.size.label }}</label>
                      <select class="mj-premium-input select-icon" required>
                        <option value="" disabled selected>{{ t.form.fields.size.options[0] }}</option>
                        <option>{{ t.form.fields.size.options[1] }}</option>
                        <option>{{ t.form.fields.size.options[2] }}</option>
                        <option>{{ t.form.fields.size.options[3] }}</option>
                        <option>{{ t.form.fields.size.options[4] }}</option>
                      </select>
                    </div>

                    <button type="submit" class="submit-btn-glow mj-btn-primary font-weight-bold text-h6 py-4 rounded-lg d-flex align-center justify-center gap-2">
                      {{ t.form.submitBtn }} <v-icon>mdi-arrow-right</v-icon>
                    </button>

                    <p class="text-caption text-center muted-text mt-4">
                      {{ t.form.privacyText1 }} <a href="/privacidade" class="text-primary text-decoration-none font-weight-bold">{{ t.form.privacyText2 }}</a>.
                    </p>
                  </form>
                </div>
              </div>
            </v-container>
          </section>
        </main>

        <footer class="mj-footer pt-16 pb-8 border-t">
          <v-container>
            <v-row class="mb-12">
              <v-col cols="12" md="3" class="pr-md-8">
                <img :src="currentLogo" alt="MJ Process" class="logo mb-6" style="height: 36px;" />
                <p class="text-body-2 muted-text mb-6 line-height-relaxed">
                  {{ t.footer.desc }}
                </p>
                <div class="d-flex gap-4">
                  <v-btn icon="mdi-linkedin" variant="tonal" size="small"></v-btn>
                  <v-btn icon="mdi-instagram" variant="tonal" size="small"></v-btn>
                  <v-btn icon="mdi-github" variant="tonal" size="small"></v-btn>
                </div>
              </v-col>
              <v-col cols="6" md="3">
                <h4 class="font-weight-bold mb-4 text-h6">{{ t.footer.col1.title }}</h4>
                <div class="d-flex flex-column gap-3">
                  <a href="/producao" class="footer-link">{{ t.footer.col1.links[0] }}</a>
                  <a href="/open-finance" class="footer-link">{{ t.footer.col1.links[1] }}</a>
                  <a href="/assinaturas" class="footer-link font-weight-bold text-primary">{{ t.footer.col1.links[2] }}</a>
                  <a href="/sla" class="footer-link">{{ t.footer.col1.links[3] }}</a>
                </div>
              </v-col>
              <v-col cols="6" md="3">
                <h4 class="font-weight-bold mb-4 text-h6">{{ t.footer.col2.title }}</h4>
                <div class="d-flex flex-column gap-3">
                  <a href="/design-studio" class="footer-link">{{ t.footer.col2.links[0] }}</a>
                  <a href="/printing" class="footer-link">{{ t.footer.col2.links[1] }}</a>
                  <a href="/cotacoes" class="footer-link">{{ t.footer.col2.links[2] }}</a>
                  <a href="/api" class="footer-link">{{ t.footer.col2.links[3] }}</a>
                </div>
              </v-col>
              <v-col cols="12" md="3">
                <h4 class="font-weight-bold mb-4 text-h6">{{ t.footer.col3.title }}</h4>
                <div class="d-flex flex-column gap-3">
                  <a href="/compliance" class="footer-link">{{ t.footer.col3.links[0] }}</a>
                  <a href="/auditoria" class="footer-link">{{ t.footer.col3.links[1] }}</a>
                  <a href="/rls" class="footer-link">{{ t.footer.col3.links[2] }}</a>
                  <a href="/cloud" class="footer-link">{{ t.footer.col3.links[3] }}</a>
                  <a href="/termos" class="footer-link mt-2 pt-2 border-t text-primary font-weight-bold">{{ t.footer.col3.links[4] }}</a>
                  <a href="/privacidade" class="footer-link">{{ t.footer.col3.links[5] }}</a>
                </div>
              </v-col>
            </v-row>
            <v-divider class="mb-6 opacity-20"></v-divider>
            <div class="text-center text-caption muted-text d-flex align-center justify-center gap-2 flex-wrap">
              <v-icon size="16">mdi-shield-check-outline</v-icon>
              &copy; {{ new Date().getFullYear() }} MJ Process Technologies. {{ t.footer.copyright }}
            </div>
          </v-container>
        </footer>
      </div>

      <v-dialog v-model="isModalOpen" max-width="1200" transition="dialog-bottom-transition" class="interactive-module-modal" scrim="black">
        <div :class="['mj-landing-wrapper modal-inner-wrapper', isDark ? 'theme-dark' : 'theme-light']">
          <div class="mj-card premium-modal pa-0 overflow-hidden d-flex flex-column flex-md-row position-relative">
            <v-btn icon="mdi-close" variant="tonal" size="small" class="modal-close-btn bg-surface elevation-4" @click="isModalOpen = false"></v-btn>
            <div class="modal-image-panel w-100 w-md-60 bg-alternate position-relative overflow-hidden d-flex align-center justify-center border-r"
                 @mousemove="handleZoom" @mouseleave="resetZoom" @mouseenter="startZoom">
              <div class="zoom-hint text-caption font-weight-bold bg-black text-white px-3 py-1 rounded-pill position-absolute" style="top: 24px; left: 24px; z-index: 10;">
                <v-icon size="16" class="mr-1">mdi-cursor-move</v-icon> {{ t.modal.inspect }}
              </div>
              <div class="zoom-container w-100 h-100" ref="zoomContainer">
                <img v-if="!activeModuleData?.isHtml"
                     :src="isDark ? activeModuleData?.darkImg : activeModuleData?.lightImg"
                     class="zoomable-image w-100 h-100 object-fit-contain" />
              </div>
            </div>
            <div class="modal-content-panel w-100 w-md-40 pa-10 d-flex flex-column bg-surface overflow-y-auto" style="max-height: 80vh;">
              <v-avatar :color="activeModuleData?.color" variant="tonal" size="56" class="mb-6 modal-anim-item" style="--anim-delay: 0.1s;">
                <v-icon size="28">{{ activeModuleData?.icon }}</v-icon>
              </v-avatar>
              <h3 class="text-h3 font-weight-black mb-4 tracking-tight line-height-tight modal-anim-item" style="--anim-delay: 0.2s;">
                {{ activeModuleData?.title }}
              </h3>
              <p class="text-body-1 muted-text mb-8 modal-anim-item" style="--anim-delay: 0.3s;">
                {{ activeModuleData?.description }}
              </p>
              <v-divider class="mb-8 opacity-20 modal-anim-item" style="--anim-delay: 0.4s;"></v-divider>
              <h4 class="text-overline font-weight-bold mb-4 modal-anim-item" style="--anim-delay: 0.5s;">{{ t.modal.capabilities }}</h4>
              <ul class="feature-list modal-anim-item" style="--anim-delay: 0.6s;">
                <li v-for="(feat, index) in activeModuleData?.features" :key="index" class="d-flex gap-3 align-start mb-4">
                  <v-icon :color="activeModuleData?.color" size="24" class="mt-n1">mdi-check-decagram</v-icon>
                  <span class="text-body-2 font-weight-medium">{{ feat }}</span>
                </li>
              </ul>
              <div class="mt-auto pt-8 modal-anim-item" style="--anim-delay: 0.8s;">
                <v-btn :color="activeModuleData?.color" variant="flat" block size="large" class="font-weight-bold rounded-lg elevation-4" @click="isModalOpen = false; scrollToElement('#trial-form')">
                  {{ t.modal.scheduleBtn }}
                </v-btn>
              </div>
            </div>
          </div>
        </div>
      </v-dialog>

      <div class="mj-assistant-widget" :class="{ 'open': isAssistantOpen }">
        <div class="assistant-trigger" @click="toggleAssistant" v-if="!isAssistantOpen">
          <div class="trigger-glow"></div>
          <v-icon size="28" color="white">mdi-robot-outline</v-icon>
        </div>

        <div class="assistant-window mj-card pa-0 overflow-hidden d-flex flex-column shadow-2xl border" v-if="isAssistantOpen">
          <div class="assistant-header bg-primary pa-4 text-white d-flex align-center justify-space-between">
            <div class="d-flex align-center gap-3">
              <v-avatar color="white" size="40"><v-icon color="primary" size="24">mdi-brain</v-icon></v-avatar>
              <div>
                <div class="font-weight-bold text-body-1 line-height-tight">MJ Concierge</div>
                <div class="text-caption opacity-80 d-flex align-center gap-1"><span class="dot-online bg-white"></span> {{ t.chatBot.online }}</div>
              </div>
            </div>
            <v-btn icon="mdi-close" variant="text" color="white" size="small" @click="toggleAssistant"></v-btn>
          </div>

          <div class="assistant-body pa-4 bg-alternate flex-grow-1 overflow-y-auto" style="height: 450px;">
            <transition name="slide-fade" mode="out-in">
              <div v-if="!activeAssistantFaq" key="list" class="d-flex flex-column gap-3">
                <div class="assistant-bubble bot-bubble pa-3 rounded-lg bg-surface border text-body-2 mb-4 shadow-sm font-weight-medium">
                  {{ t.chatBot.greeting }}
                </div>
                <div v-for="(faq, index) in faqList" :key="index"
                  class="faq-option-chip border rounded-lg px-4 py-3 bg-surface text-body-2 font-weight-medium cursor-pointer hover-lift d-flex justify-space-between align-center"
                  @click="openAssistantFaq(faq)">
                  {{ faq.question }}
                  <v-icon color="primary" size="18">mdi-chevron-right</v-icon>
                </div>
              </div>

              <div v-else key="answer" class="d-flex flex-column h-100">
                <v-btn variant="text" prepend-icon="mdi-arrow-left" size="small" class="align-self-start text-none mb-4 px-0 muted-text" @click="activeAssistantFaq = null">
                  {{ t.chatBot.backBtn }}
                </v-btn>
                <div class="assistant-bubble user-bubble pa-3 rounded-lg bg-primary text-white text-body-2 align-self-end mb-4 w-80 shadow-sm">
                  {{ activeAssistantFaq.question }}
                </div>
                <div class="assistant-bubble bot-bubble pa-4 rounded-lg bg-surface border text-body-2 mb-4 w-90 shadow-sm font-weight-medium" v-html="activeAssistantFaq.answer"></div>

                <div class="mt-auto pt-4 text-center">
                  <v-btn color="primary" variant="outlined" block size="small" class="text-none font-weight-bold" @click="scrollToElement('#trial-form'); toggleAssistant()">
                    {{ t.chatBot.ctaBtn }}
                  </v-btn>
                </div>
              </div>
            </transition>
          </div>
          <div class="assistant-footer pa-3 border-t bg-surface text-center text-caption muted-text">
            {{ t.chatBot.footer }}
          </div>
        </div>
      </div>

    </div>
  </v-app>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue';
import { useTheme } from 'vuetify';

// Assets
import LogoDark from '@/assets/logo.png';
import LogoLight from '@/assets/logomjlm.png';
import DashboardDark from '@/assets/landing-dashboard-dark.png';
import DashboardLight from '@/assets/landing-dashboard-light.png';
import ProducaoDark from '@/assets/landing-producao-kanban-dark.png';
import ProducaoLight from '@/assets/landing-producao-kanban-light.png';
import DesignDark from '@/assets/landing-design-dark.png';
import DesignLight from '@/assets/landing-design-light.png';
import PCPDark from '@/assets/landing-pcp-dark.png';
import PCPLight from '@/assets/landing-pcp-light.png';
import PrintingDark from '@/assets/landing-printing-dark.png';
import PrintingLight from '@/assets/landing-printing-light.png';
import FiscalDark from '@/assets/landing-fiscal-emissao-dark.png';
import FiscalLight from '@/assets/landing-fiscal-emissao-light.png';
import DREDark from '@/assets/landing-dre-dark.png';
import DRELight from '@/assets/landing-dre-light.png';
import QuotationDark from '@/assets/landing-quotation-dark.png';
import QuotationLight from '@/assets/landing-quotation-light.png';
import ReceivablesDark from '@/assets/landing-receivables-dark.png';
import ReceivablesLight from '@/assets/landing-receivables-light.png';

// Theme & Scroll
const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const isScrolled = ref(false);
const currentLogo = computed(() => isDark.value ? LogoDark : LogoLight);
const currentDashboard = computed(() => isDark.value ? DashboardDark : DashboardLight);
const toggleTheme = () => { theme.global.name.value = isDark.value ? 'light' : 'dark'; };
const handleScroll = () => { isScrolled.value = window.scrollY > 50; };
const scrollToElement = (selector: string) => { const el = document.querySelector(selector); if (el) el.scrollIntoView({ behavior: 'smooth' }); };

// Boot Sequence
const isBooting = ref(false);
const bootProgress = ref(0);

const initiateBootSequence = () => {
  isBooting.value = true;
  bootProgress.value = 0;
  setTimeout(() => { bootProgress.value = 30; }, 500);
  setTimeout(() => { bootProgress.value = 75; }, 1200);
  setTimeout(() => {
    bootProgress.value = 100;
    setTimeout(() => { window.location.href = '/login'; }, 400);
  }, 1800);
};

// ==========================================
// i18n TRANSLATION SYSTEM COM ANIMAÇÃO
// ==========================================
const currentLang = ref('pt');
const isAnimatingLang = ref(false);

const setLang = (lang: string) => {
  if (lang === currentLang.value) return;
  isAnimatingLang.value = true;
  setTimeout(() => {
    currentLang.value = lang;
    setTimeout(() => { isAnimatingLang.value = false; }, 50);
  }, 350); // Duração igual à da transição CSS
};

const currentFlag = computed(() => {
  if (currentLang.value === 'pt') return '🇧🇷';
  if (currentLang.value === 'en') return '🇺🇸';
  return '🇪🇸';
});

const i18n: Record<string, any> = {
  pt: {
    bootingText: 'Iniciando handshake seguro...',
    nav: { pillars: 'Os Pilares', architecture: 'Arquitetura', ecosystem: 'Ecossistema', plans: 'Planos', login: 'Acessar ERP' },
    hero: { badge: 'Software de Gestão Proprietário.', title: 'O fim da <br><span class="gradient-text">fragmentação.</span>', subtitle: 'A central de comando definitiva para operações industriais, confecções e distribuidoras. Abandone sistemas genéricos e assuma o controle absoluto do seu ecossistema corporativo.', ctaPrimary: 'Solicitar Demonstração', ctaSecondary: 'Explorar Arquitetura' },
    pillars: {
      sectionTitle: 'Governança Operacional Elevada', sectionDesc: 'Projetado para empresas que ultrapassaram a capacidade das planilhas e dos ERPs de prateleira.',
      items: [
        { icon: 'mdi-vector-combine', bgClass: 'bg-primary-lighten', textClass: 'text-primary', title: 'Centralização Absoluta', desc: 'Uma única fonte de verdade. A venda no PDV atualiza o DRE, consome insumos no MRP, agenda a produção no Kanban e dispara a esteira de separação. Sem integrações frágeis, sem retrabalho.' },
        { icon: 'mdi-chart-timeline-variant-shimmer', bgClass: 'bg-success-lighten', textClass: 'text-success', title: 'Inteligência em Tempo Real', desc: 'Decisões baseadas em dados vivos. Dashboards C-Level que refletem a pulsação da fábrica, o fluxo de caixa diário e a eficiência dos vendedores instantaneamente. O fim dos relatórios de "fechamento de mês".' },
        { icon: 'mdi-shield-check-outline', bgClass: 'bg-warning-lighten', textClass: 'text-warning', title: 'Governança Fiscal & Financeira', desc: 'Compliance blindado. Motor tributário embarcado para emissões Sefaz (NFe/CTe/NFCe) com cálculo autônomo de ST e IPI. Conciliação Open Finance automática com contas a pagar vinculadas a compras.' },
        { icon: 'mdi-forum-outline', bgClass: 'bg-secondary-lighten', textClass: 'text-secondary', title: 'Comunicação Inviolável', desc: 'Erradique o WhatsApp corporativo. Todo o diálogo sobre pedidos, layouts de design e aprovações de crédito ocorre dentro da plataforma, vinculado à Ordem de Serviço, com trilha de auditoria inviolável.' }
      ]
    },
    carousel: {
      title: 'Aceleração Tática',
      items: [
        { icon: 'mdi-factory', color: 'teal', title: 'Multi-Loja & Filiais', desc: 'Gerencie o estoque e o faturamento de toda a rede de lojas e galpões através de um único Tenant consolidado.' },
        { icon: 'mdi-account-key', color: 'indigo', title: 'Granularidade RLS', desc: 'Permissões rigorosas a nível de banco de dados. O vendedor A jamais enxergará a carteira de clientes do vendedor B.' },
        { icon: 'mdi-cloud-sync', color: 'purple', title: 'API & Webhooks', desc: 'Arquitetura Headless preparada para integrar com e-commerces, CRMs externos, PowerBI e robôs de automação.' },
        { icon: 'mdi-alarm-light-outline', color: 'error', title: 'Alertas Proativos', desc: 'O sistema te avisa antes do problema ocorrer: estoque mínimo atingido, atraso na linha de produção ou título vencido.' },
        { icon: 'mdi-file-document-multiple-outline', color: 'success', title: 'Gestão Documental', desc: 'GED integrado. Armazene PDFs, XMLs de notas e comprovantes de pagamento atrelados diretamente aos lançamentos.' }
      ]
    },
    architecture: {
      title: 'O Sistema Nervoso Central', desc: 'Uma malha tecnológica viva. Construído sobre PostgreSQL e Edge Functions para suportar a volumetria agressiva da sua empresa sem gargalos de processamento.',
      nodes: [
        { title: 'Cloud Nativa 100%', desc: 'Clusters distribuídos garantindo 99.9% de uptime e espelhamento de dados (Backups PITR).' },
        { title: 'Processamento Edge', desc: 'Lógica e cálculos pesados executados próximos ao usuário para latência quase zero.' },
        { title: 'Criptografia RLS', desc: 'Isolamento absoluto. Políticas de segurança a nível de linha no banco de dados.' },
        { title: 'API & Integrações', desc: 'Sua operação conectada ao mundo através de endpoints REST e Webhooks seguros.' }
      ]
    },
    ecosystem: { title: 'O ECOSSISTEMA', inspectBtn: 'Explorar Módulo' },
    chatMockup: { team: 'Equipe de Design', online: '3 online', msg1: 'Layout da OP #4023 precisa de revisão urgente na sangria.', msg2: 'Certo, o arquivo já está aberto. Ajustando a margem de corte!', placeholder: 'Digite sua mensagem...' },
    pricing: {
      title: 'Transparência em Escala Corporativa', desc: 'Escolha o poder computacional e a infraestrutura que o seu momento operacional exige. Sem taxas ocultas.', popularBadge: 'Mais Escolhido', compareTitle: 'Comparativo Definitivo de Funcionalidades',
      plans: [
        { tier: 'Iniciante', name: 'Básico', price: 'R$ 299', period: '/mês', desc: 'O primeiro passo definitivo. Ideal para micro-operações abandonando as planilhas e buscando padronização.', userLimitIcon: 'mdi-check-decagram', userLimit: '3 Usuários Ativos Inclusos', extraUser: '+ R$ 50 por usuário adicional', features: ['PDV Ágil e Gestão de Vendas', 'Financeiro Simplificado', 'Controle de Estoque Base', 'Suporte em Horário Comercial'], btnText: 'Inicie a Jornada', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Avançado', name: 'Pro', price: 'R$ 799', period: '/mês', desc: 'O ponto de virada para PMEs que exigem controle absoluto sobre a produção e o caixa.', userLimitIcon: 'mdi-check-decagram', userLimit: '10 Usuários Ativos Inclusos', extraUser: '+ R$ 40 por usuário adicional', features: ['Produção & Kanban Interativo', 'Motor Fiscal Sefaz Lote', 'DRE Gerencial Completo', 'Chat Interno Integrado'], btnText: 'Testar Grátis (14 dias)', btnColor: 'primary', btnVariant: 'flat', highlight: true, dark: false },
        { tier: 'Expansão', name: 'Business', price: 'R$ 1.699', period: '/mês', desc: 'Para empresas com múltiplas filiais, distribuidores robustos e alta volumetria transacional.', userLimitIcon: 'mdi-check-decagram', userLimit: '30 Usuários Ativos Inclusos', extraUser: '+ R$ 30 por usuário adicional', features: ['Multi-Loja / Multi-CNPJ nativo', 'PCP Avançado & Máquinas', 'Design Studio Web', 'API Pública p/ Integrações'], btnText: 'Falar com Consultor', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Corporativo Privado', name: 'Enterprise', price: 'Consulte', period: '', desc: 'Infraestrutura dedicada. Solução White-label com desenvolvimento e parametrização sob medida.', userLimitIcon: 'mdi-infinity', userLimit: 'Usuários Ilimitados', extraUser: 'Sem custos por assento', features: ['Banco de Dados Isolado (Tenant)', 'SLA de 99.9% em Contrato', 'Suporte 24/7 Engenharia', 'Customização Core'], btnText: 'Agendar Reunião C-Level', btnColor: 'white', btnVariant: 'flat', highlight: false, dark: true }
      ],
      table: { col1: 'Módulos & Recursos', rows: [
        { feat: 'CRM, Vendas e PDV', b: '<i class="mdi mdi-check text-success text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check text-success text-h5"></i>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Gestão Financeira & DRE', b: 'Simplificado', p: 'Gerencial Completo', bu: 'Gerencial Completo', e: 'Customizado (BI)' },
        { feat: 'Controle de Produção Kanban', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check-all text-success text-h5"></i><br><span class="text-caption">PCP Avançado</span>', e: '<i class="mdi mdi-check-all text-success text-h5"></i>' },
        { feat: 'Emissão Sefaz Lote', b: 'Add-on Cobrado', p: 'Ilimitado', bu: 'Ilimitado', e: 'Ilimitado API Privada' },
        { feat: 'Chat Corporativo Interno', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: 'Até 3 Canais', bu: '<i class="mdi mdi-check text-success text-h5"></i><br><span class="text-caption">Ilimitado</span>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Módulos Extras (Frota, Design)', b: 'Não suportado', p: 'R$ 150 / Módulo Extra', bu: '<span class="text-success">Todos Inclusos Livre</span>', e: '<span class="text-success">Todos Inclusos Livre</span>' }
      ]}
    },
    form: {
      title: 'Não mude de sistema.<br>Mude de patamar.', desc: 'Agende uma demonstração estratégica focada no gargalo exato da sua operação. Nossos engenheiros mostrarão como o MJ Process substitui sua stack atual inteira.',
      bullets: [{ icon: 'mdi-check-all', text: 'Onboarding Assistido e Migração de Dados' }, { icon: 'mdi-account-tie', text: 'Treinamento exclusivo para lideranças' }, { icon: 'mdi-lock-open-check', text: 'Sem fidelidade abusiva. Retorno provado.' }],
      formTitle: 'Solicitar Acesso Elite', formDesc: 'Preencha os dados reais. Nossa triagem de engenharia entrará em contato em até 10 minutos.',
      fields: {
        name: { label: 'Nome e Sobrenome', placeholder: 'Ex: Carlos Silva' }, email: { label: 'E-mail Corporativo', placeholder: 'carlos@suaempresa.com.br' },
        phone: { label: 'WhatsApp Direto', placeholder: '(11) 99999-9999' }, role: { label: 'Cargo / Função', placeholder: 'Ex: Diretor de Produção' },
        size: { label: 'Tamanho da operação', options: ['Selecione o número de colaboradores...', 'Até 10 funcionários (Crescimento)', '11 a 50 funcionários (PME)', '51 a 200 funcionários (Escala)', 'Mais de 200 funcionários (Enterprise)'] }
      },
      submitBtn: 'Acessar Plataforma Agora', privacyText1: 'Informação protegida sob nossa rígida', privacyText2: 'Política de Privacidade (LGPD)'
    },
    footer: {
      desc: 'O software de gestão proprietário projetado por engenheiros para empresas que exigem excelência técnica, compliance governamental e controle operacional absoluto no Brasil.',
      col1: { title: 'Soluções Corporativas', links: ['Produção & Kanban', 'Gestão Open Finance', 'Assinaturas SaaS', 'SLA & Disponibilidade'] },
      col2: { title: 'Ecossistema Tático', links: ['Design Studio & Workflow', 'Impressão & Printing Station', 'Suprimentos & Cotações', 'Documentação API REST'] },
      col3: { title: 'Governança & Core', links: ['Compliance Fiscal Sefaz', 'Auditoria de Dados (Audit)', 'Isolamento Multi-Tenant (RLS)', 'Infraestrutura em Nuvem', 'Termos de Serviço de Licença', 'Política de Privacidade (LGPD)'] },
      copyright: 'Construído com arquitetura de ponta no Brasil.'
    },
    modal: { inspect: 'Inspecionar Interface', capabilities: 'Capabilities Estratégicos', scheduleBtn: 'Agendar Setup Deste Módulo' },
    chatBot: { online: 'Online e pronto', greeting: 'Olá! Identifiquei que você está avaliando o sistema. Abaixo estão as principais dúvidas arquitetônicas dos nossos clientes enterprise. O que deseja saber?', backBtn: 'Voltar às opções', ctaBtn: 'Agendar Demonstração', footer: 'Assistente Comercial MJ Process' },
    modules: [
      { id: 'producao', title: 'Chão de Fábrica e Kanban', description: 'Acompanhe cada milímetro do seu processo produtivo em tempo real. Identifique ociosidade e prazos de entrega rigorosamente.', features: ['Apontamento de horas via código de barras.', 'Engenharia de Produto (BOM) detalhada.', 'Rastreabilidade total de Lotes.', 'Visão Kanban customizável por células.'] },
      { id: 'design', title: 'Design Studio & Aprovações', description: 'Elimine as indas e vindas no WhatsApp. O pedido cai na fila do designer. A arte é aprovada digitalmente pelo cliente via link.', features: ['Versioning e histórico de alterações.', 'Painel integrado ao status do Kanban.', 'Link externo White-label para o cliente.', 'Marcação de correções direto no preview.'] },
      { id: 'pcp', title: 'PCP: Orquestração Fina', description: 'Planejamento e Controle da Produção avançado. Alocação de máquinas, Gantt para gargalos e cálculo reverso de tempo de entrega.', features: ['Gantt de ocupação de máquinas.', 'Explosão de materiais MRP.', 'Cálculo de prazo de entrega dinâmico.', 'Alertas de manutenção de maquinário.'] },
      { id: 'printing', title: 'Printing Station', description: 'A ponte entre o ERP e a sua plotter. Fila de ripagem organizada e contagem cirúrgica de consumo de tinta e papel por OP.', features: ['Fila de impressão priorizada pelo PCP.', 'Integração de status "Impresso".', 'Baixa automática de metros lineares.', 'Verificação visual pré-impressão.'] },
      { id: 'fiscal', title: 'Compliance Fiscal Sefaz', description: 'O motor tributário autônomo. Esqueça a digitação manual: emita dezenas de NF-es, NFC-es e CT-es em lote com 1 clique e monitore tudo.', features: ['Emissão e cancelamento em lote Sefaz.', 'Cálculo automático ST e IPI.', 'Manifestação Eletrônica do Destinatário.', 'Exportação contábil Sped/XML.'] },
      { id: 'financeiro', title: 'Tesouraria e DRE Analítico', description: 'A saúde financeira desenhada em tela. Conciliação bancária via Open Finance e DRE Gerencial em tempo real.', features: ['DRE estruturado atualizado instantaneamente.', 'Conciliação Open Finance (Cora, Inter).', 'Controle de sangrias multi-loja.', 'Emissão de Boletos e Pix via API.'] },
      { id: 'cotacoes', title: 'Compras e Cotações', description: 'Transforme compras num gerador de lucro. Solicite cotações, compare matrizes de preços lado a lado e aprove a melhor oferta.', features: ['Mapa comparativo visual.', 'Gestão de fornecedores com rating.', 'Geração automática de Contas a Pagar.', 'Histórico de flutuação de preço do insumo.'] },
      { id: 'receivables', title: 'Contas a Receber & Inadimplência', description: 'Painel dedicado para acompanhamento de títulos, baixas parciais via PIX e réguas de cobrança pré-configuradas.', features: ['Painel de Aging (Vencidos).', 'Baixa via retorno bancário CNAB.', 'Lembretes de cobrança via WhatsApp.', 'Limites de crédito e bloqueio de vendas.'] },
      { id: 'chat', title: 'Chat Corporativo Contextual', description: 'A prova para auditorias. Pare de usar ferramentas externas. Comunique-se com a equipe dentro do contexto da OP, com anexos e histórico blindado.', features: ['Canais estruturados por departamentos.', 'Anexos atrelados ao pedido.', 'Indicadores de leitura em tempo real.', 'Fim absoluto do WhatsApp na operação.'] }
    ],
    faqs: [
      { question: '1. O sistema atende quais tipos de empresa?', answer: 'Nossa arquitetura foi desenhada primariamente para <strong>Indústrias, Confecções, Estamparias e Distribuidoras robustas</strong>. Substituímos stacks complexos por uma plataforma única.' },
      { question: '2. O sistema possui emissão fiscal Sefaz?', answer: 'Sim, completa. O motor fiscal <strong>emite e cancela NF-e, NFC-e, CT-e e MDF-e em lote</strong>. Ele consulta regras tributárias (NCM/CEST), calcula ST e IPI automaticamente.' },
      { question: '3. Tem controle de produção no chão de fábrica?', answer: 'Sim. Possuímos um <strong>PCP avançado com Kanban interativo, apontamento via tablet, explosão de materiais (BOM) e roteamento de máquinas</strong>.' },
      { question: '4. O módulo financeiro é integrado?', answer: 'Absolutamente. Todas as faturas nascem de OPs ou Compras automaticamente. Temos <strong>DRE gerencial, fluxo de caixa, contas a pagar/receber e conciliação Open Finance</strong> (integração direta com bancos como Cora, Inter, Itaú).' },
      { question: '5. Possui estrutura para Multi-Loja/Filiais?', answer: 'Sim. O sistema foi feito sob uma infraestrutura de Tenant isolado, permitindo o controle centralizado de <strong>Múltiplos CNPJs, galpões de estoque (multi-almoxarifado) e Caixas (PDV) separados</strong>.' },
      { question: '6. A equipe comercial (vendedores) pode usar?', answer: 'Sim. O módulo de CRM e Vendas possui <strong>PDV Ágil, catálogo digital, comissionamento automático, tabela de preços dinâmica e visualização do andamento da produção pelo próprio vendedor</strong>.' },
      { question: '7. Como funciona o Chat Interno?', answer: 'É um <strong>substituto corporativo para o WhatsApp</strong>. Canais dedicados vinculados às Ordens de Produção onde a equipe discute layouts, aprova solicitações e envia arquivos. Tudo fica salvo e auditável na linha do tempo do pedido.' },
      { question: '8. Como é feito o controle de permissões?', answer: 'Utilizamos <strong>RLS (Row Level Security) nativo no banco de dados PostgreSQL</strong>. Um vendedor, por exemplo, é incapaz de acessar ou sequer consultar dados e carteiras que não pertencem a ele. Alta segurança corporativa.' },
      { question: '9. O sistema opera em nuvem (SaaS)?', answer: 'Sim. Somos <strong>100% Cloud Native</strong> (Edge Computing), hospedados em servidores de altíssima redundância (AWS via Supabase), garantindo SLA de 99.9% de uptime e backups PITR (Point-in-Time Recovery).' },
      { question: '10. A plataforma tem suporte e implantação?', answer: 'Sim. Todo contrato Pro ou Enterprise inclui um <strong>Onboarding assistido com migração de dados e acompanhamento de sucesso do cliente</strong>.' },
      { question: '11. Tem módulo para Design e Aprovação de Arte?', answer: 'Sim, o exclusivo <strong>Design Studio</strong>. O vendedor solicita a criação, o designer desenvolve, envia para o módulo e o vendedor aprova digitalmente ou gera um link externo para aprovação direto com o cliente.' },
      { question: '12. Como acompanho a lucratividade?', answer: 'O painel C-Level exibe <strong>Dashboards interativos com DRE formatado, custos fixos, variáveis, margem de contribuição (CPV) e EBITDA em tempo real</strong>, permitindo tomada de decisão imediata.' },
      { question: '13. Tem integração via API?', answer: 'Sim. Possuímos uma <strong>API RESTful aberta e robusta, além de Webhooks configuráveis</strong> para que você acople seu e-commerce, ERPs legados, PowerBI ou robôs no Make/Zapier.' },
      { question: '14. Como agendar uma demonstração?', answer: 'Basta rolar a página até o formulário <strong>"Solicitar Acesso Elite"</strong>, preencher seus dados corporativos e nosso time de engenharia agendará uma call técnica.' }
    ]
  },
  en: {
    bootingText: 'Initiating secure handshake...',
    nav: { pillars: 'Core Pillars', architecture: 'Architecture', ecosystem: 'Ecosystem', plans: 'Plans', login: 'Access ERP' },
    hero: { badge: 'Proprietary Management Software.', title: 'The end of <br><span class="gradient-text">fragmentation.</span>', subtitle: 'The ultimate command center for industrial operations, apparel, and distributors. Abandon generic systems and take absolute control of your corporate ecosystem.', ctaPrimary: 'Request Demo', ctaSecondary: 'Explore Architecture' },
    pillars: {
      sectionTitle: 'Elevated Operational Governance', sectionDesc: 'Designed for companies that have outgrown spreadsheets and off-the-shelf ERPs.',
      items: [
        { icon: 'mdi-vector-combine', bgClass: 'bg-primary-lighten', textClass: 'text-primary', title: 'Absolute Centralization', desc: 'A single source of truth. A POS sale updates the P&L, consumes MRP inputs, schedules Kanban production, and triggers picking. No fragile integrations.' },
        { icon: 'mdi-chart-timeline-variant-shimmer', bgClass: 'bg-success-lighten', textClass: 'text-success', title: 'Real-Time Intelligence', desc: 'Data-driven decisions. C-Level dashboards reflecting factory pulse, daily cash flow, and sales efficiency instantly. The end of month-end reporting.' },
        { icon: 'mdi-shield-check-outline', bgClass: 'bg-warning-lighten', textClass: 'text-warning', title: 'Fiscal & Financial Governance', desc: 'Bulletproof compliance. Embedded tax engine for government invoicing with autonomous tax calculation. Open Finance reconciliation linked to purchasing.' },
        { icon: 'mdi-forum-outline', bgClass: 'bg-secondary-lighten', textClass: 'text-secondary', title: 'Inviolable Communication', desc: 'Eradicate corporate WhatsApp. All dialogue regarding orders, design layouts, and credit approvals happens inside the platform, with a bulletproof audit trail.' }
      ]
    },
    carousel: {
      title: 'Tactical Acceleration',
      items: [
        { icon: 'mdi-factory', color: 'teal', title: 'Multi-Store & Branches', desc: 'Manage inventory and billing across your entire network of stores and warehouses via a single consolidated Tenant.' },
        { icon: 'mdi-account-key', color: 'indigo', title: 'RLS Granularity', desc: 'Strict database-level permissions. Salesrep A will never see Salesrep B\'s client portfolio.' },
        { icon: 'mdi-cloud-sync', color: 'purple', title: 'API & Webhooks', desc: 'Headless architecture ready to integrate with e-commerce, external CRMs, PowerBI, and automation bots.' },
        { icon: 'mdi-alarm-light-outline', color: 'error', title: 'Proactive Alerts', desc: 'The system warns you before issues occur: minimum stock reached, production line delay, or overdue invoice.' },
        { icon: 'mdi-file-document-multiple-outline', color: 'success', title: 'Document Management', desc: 'Integrated ECM. Store PDFs, invoice XMLs, and payment receipts directly linked to entries.' }
      ]
    },
    architecture: {
      title: 'The Central Nervous System', desc: 'A living technological mesh. Built on PostgreSQL and Edge Functions to support massive company volume without processing bottlenecks.',
      nodes: [
        { title: '100% Cloud Native', desc: 'Distributed clusters ensuring 99.9% uptime and data mirroring (PITR Backups).' },
        { title: 'Edge Processing', desc: 'Heavy logic and calculations executed close to the user for near-zero latency.' },
        { title: 'RLS Encryption', desc: 'Absolute isolation. Row-level security policies enforced at the database level.' },
        { title: 'API & Integrations', desc: 'Your operation connected to the world via REST endpoints and secure Webhooks.' }
      ]
    },
    ecosystem: { title: 'THE ECOSYSTEM', inspectBtn: 'Explore Module' },
    chatMockup: { team: 'Design Team', online: '3 online', msg1: 'Order #4023 layout needs an urgent bleed review.', msg2: 'Right, file is open. Adjusting the cutting margin!', placeholder: 'Type your message...' },
    pricing: {
      title: 'Corporate Scale Transparency', desc: 'Choose the computing power and infrastructure your operational stage requires. No hidden fees.', popularBadge: 'Most Chosen', compareTitle: 'Definitive Feature Comparison',
      plans: [
        { tier: 'Starter', name: 'Basic', price: '$ 60', period: '/mo', desc: 'The definitive first step. Ideal for micro-operations abandoning spreadsheets.', userLimitIcon: 'mdi-check-decagram', userLimit: '3 Active Users Included', extraUser: '+ $ 10 per additional user', features: ['Agile POS & Sales', 'Simplified Financials', 'Base Inventory Control', 'Business Hours Support'], btnText: 'Start the Journey', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Advanced', name: 'Pro', price: '$ 150', period: '/mo', desc: 'The turning point for SMBs demanding absolute control over production and cash.', userLimitIcon: 'mdi-check-decagram', userLimit: '10 Active Users Included', extraUser: '+ $ 8 per additional user', features: ['Interactive Kanban', 'Batch Tax Engine', 'Complete P&L', 'Integrated Internal Chat'], btnText: 'Free Trial (14 days)', btnColor: 'primary', btnVariant: 'flat', highlight: true, dark: false },
        { tier: 'Expansion', name: 'Business', price: '$ 300', period: '/mo', desc: 'For companies with multiple branches, robust distributors, and high transaction volume.', userLimitIcon: 'mdi-check-decagram', userLimit: '30 Active Users Included', extraUser: '+ $ 6 per additional user', features: ['Multi-Store / Multi-Tax ID', 'Advanced MRP & Machines', 'Web Design Studio', 'Public API for Integrations'], btnText: 'Talk to a Consultant', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Private Corporate', name: 'Enterprise', price: 'Custom', period: '', desc: 'Dedicated infrastructure. White-label solution with custom development.', userLimitIcon: 'mdi-infinity', userLimit: 'Unlimited Users', extraUser: 'No per-seat costs', features: ['Isolated Database (Tenant)', '99.9% Contractual SLA', '24/7 Engineering Support', 'Core Rule Customization'], btnText: 'Schedule C-Level Meeting', btnColor: 'white', btnVariant: 'flat', highlight: false, dark: true }
      ],
      table: { col1: 'Modules & Features', rows: [
        { feat: 'CRM, Sales and POS', b: '<i class="mdi mdi-check text-success text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check text-success text-h5"></i>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Financial Management & P&L', b: 'Simplified', p: 'Complete Managerial', bu: 'Complete Managerial', e: 'Custom (BI)' },
        { feat: 'Kanban Production Control', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check-all text-success text-h5"></i><br><span class="text-caption">Advanced MRP</span>', e: '<i class="mdi mdi-check-all text-success text-h5"></i>' },
        { feat: 'Batch Tax Issuance', b: 'Paid Add-on', p: 'Unlimited', bu: 'Unlimited', e: 'Unlimited Private API' },
        { feat: 'Internal Corporate Chat', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: 'Up to 3 Channels', bu: '<i class="mdi mdi-check text-success text-h5"></i><br><span class="text-caption">Unlimited</span>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Extra Modules (Fleet, Design)', b: 'Not supported', p: '$ 30 / Extra Module', bu: '<span class="text-success">All Included Free</span>', e: '<span class="text-success">All Included Free</span>' }
      ]}
    },
    form: {
      title: 'Don\'t change systems.<br>Change levels.', desc: 'Schedule a strategic demo focused on your operation\'s exact bottleneck. Our engineers will show how MJ Process replaces your entire current stack.',
      bullets: [{ icon: 'mdi-check-all', text: 'Assisted Onboarding and Secure Data Migration' }, { icon: 'mdi-account-tie', text: 'Exclusive training for leadership' }, { icon: 'mdi-lock-open-check', text: 'No abusive lock-ins. Proven ROI.' }],
      formTitle: 'Request Elite Access', formDesc: 'Fill in real details. Our engineering triage will contact you within 10 minutes.',
      fields: {
        name: { label: 'Full Name', placeholder: 'Ex: John Smith' }, email: { label: 'Professional Corporate Email', placeholder: 'john@yourcompany.com' },
        phone: { label: 'Direct Phone / WhatsApp', placeholder: '+1 (555) 000-0000' }, role: { label: 'Your Role / Function', placeholder: 'Ex: Production Director' },
        size: { label: 'What is the size of the operation?', options: ['Select number of employees...', 'Up to 10 employees (Growing)', '11 to 50 employees (SMB)', '51 to 200 employees (Scaling)', 'Over 200 employees (Enterprise)'] }
      },
      submitBtn: 'Access Platform Now', privacyText1: 'All information provided is protected under our strict', privacyText2: 'Privacy Policy (GDPR/LGPD)'
    },
    footer: {
      desc: 'The proprietary management software designed by engineers for companies demanding technical excellence, government compliance, and absolute operational control.',
      col1: { title: 'Corporate Solutions', links: ['Production & Kanban', 'Open Finance Management', 'SaaS Subscriptions', 'SLA & Availability'] },
      col2: { title: 'Tactical Ecosystem', links: ['Design Studio & Workflow', 'Printing Station', 'Purchasing & Quotes', 'REST API Documentation'] },
      col3: { title: 'Governance & Core', links: ['Fiscal Compliance', 'Data Auditing (Audit)', 'Multi-Tenant Isolation (RLS)', 'Cloud Infrastructure', 'Terms of Service', 'Privacy Policy (LGPD)'] },
      copyright: 'Built with cutting-edge architecture.'
    },
    modal: { inspect: 'Inspect Interface', capabilities: 'Strategic Capabilities', scheduleBtn: 'Schedule Setup for this Module' },
    chatBot: { online: 'Online and ready', greeting: 'Hello! I noticed you are evaluating the system. Below are the main architectural questions from our enterprise clients. What would you like to know?', backBtn: 'Back to options', ctaBtn: 'Schedule Demo', footer: 'MJ Process Sales Assistant' },
    modules: [
      { id: 'producao', title: 'Shop Floor & Kanban', description: 'Track every millimeter of your production process in real time. Identify idleness and delivery deadlines strictly.', features: ['Barcode time tracking.', 'Detailed Bill of Materials (BOM).', 'Full Batch traceability.', 'Customizable Kanban view by cells.'] },
      { id: 'design', title: 'Design Studio & Approvals', description: 'Eliminate WhatsApp back-and-forth. The order drops into the designer\'s queue. Art is approved digitally by the client via link.', features: ['Versioning and change history.', 'Panel integrated with Kanban status.', 'White-label external link for clients.', 'Direct markup corrections on preview.'] },
      { id: 'pcp', title: 'MRP: Fine Orchestration', description: 'Advanced Manufacturing Resource Planning. Machine allocation, Gantt view for bottlenecks, and reverse delivery time calculation.', features: ['Machine occupancy Gantt.', 'Predictive MRP explosion.', 'Dynamic delivery time calculation.', 'Machinery maintenance alerts.'] },
      { id: 'printing', title: 'Printing Station', description: 'The bridge between the ERP and your plotter. Organized RIP queue and surgical counting of ink/paper consumption per Order.', features: ['Print queue prioritized by MRP.', '"Printed" status integration.', 'Automatic linear meter deduction.', 'Pre-print visual verification.'] },
      { id: 'fiscal', title: 'Fiscal Compliance', description: 'The autonomous tax engine. Forget manual typing: issue dozens of invoices in batch with 1 click and monitor everything.', features: ['Batch issuance and cancellation.', 'Automatic tax calculations.', 'Electronic Recipient Manifestation.', 'Accounting export (XML).'] },
      { id: 'financeiro', title: 'Treasury & Analytical P&L', description: 'Financial health drawn on screen. Open Finance bank reconciliation and real-time Managerial P&L.', features: ['Structured P&L updated instantly.', 'Open Finance Reconciliation.', 'Multi-store cash drawer control.', 'Invoice and Pix issuance via API.'] },
      { id: 'cotacoes', title: 'Purchasing & Quotes', description: 'Turn purchasing into a profit generator. Request quotes, compare price matrices side-by-side, and approve the best offer.', features: ['Visual comparative map.', 'Supplier management with rating.', 'Automatic Accounts Payable generation.', 'Input price fluctuation history.'] },
      { id: 'receivables', title: 'Accounts Receivable & Default', description: 'Dedicated panel for tracking invoices, partial API payments, and pre-configured billing rules to reduce defaults.', features: ['Aging Panel (Overdue).', 'Bank return file clearing.', 'WhatsApp billing reminders.', 'Credit limits and sales blocking.'] },
      { id: 'chat', title: 'Contextual Corporate Chat', description: 'The proof for audits. Stop using external tools. Communicate with the team within the Order context, with attachments and blind history.', features: ['Channels structured by departments.', 'Attachments linked to the order.', 'Real-time read receipts.', 'Absolute end of WhatsApp in operations.'] }
    ],
    faqs: [
      { question: '1. What types of companies does the system serve?', answer: 'Primarily designed for <strong>Industries, Apparel, Printing, and robust Distributors</strong>. We replace complex stacks with a single platform.' },
      { question: '2. Does the system have fiscal invoicing?', answer: 'Yes, fully. The fiscal engine <strong>issues and cancels invoices in batch</strong>. It queries tax rules and calculates taxes automatically.' },
      { question: '3. Is there production control on the shop floor?', answer: 'Yes. We have an <strong>advanced MRP with interactive Kanban, tablet tracking, BOM explosion, and machine routing</strong>.' },
      { question: '4. Is the financial module integrated?', answer: 'Absolutely. All invoices are born from POs or Sales automatically. We have <strong>managerial P&L, cash flow, and Open Finance reconciliation</strong>.' },
      { question: '5. Does it support Multi-Store/Branches?', answer: 'Yes. The system is built on an isolated Tenant infrastructure, allowing control of <strong>Multiple Tax IDs, warehouses, and POS separately</strong>.' },
      { question: '6. Can the sales team use it?', answer: 'Yes. The CRM and Sales module has an <strong>Agile POS, digital catalog, automatic commissions, and production tracking by the salesrep</strong>.' },
      { question: '7. How does the Internal Chat work?', answer: 'It is a <strong>corporate substitute for WhatsApp</strong>. Dedicated channels linked to Production Orders where the team discusses layouts and sends files safely.' },
      { question: '8. How are permissions controlled?', answer: 'We use <strong>native RLS (Row Level Security) in PostgreSQL</strong>. A salesrep, for example, is unable to access data that does not belong to them.' },
      { question: '9. Does the system operate in the cloud (SaaS)?', answer: 'Yes. We are <strong>100% Cloud Native</strong> (AWS via Supabase), guaranteeing 99.9% uptime SLA and PITR backups.' },
      { question: '10. Does the platform have support and deployment?', answer: 'Yes. Every Pro or Enterprise contract includes <strong>assisted onboarding with data migration and customer success tracking</strong>.' },
      { question: '11. Is there a module for Design and Art Approval?', answer: 'Yes, the exclusive <strong>Design Studio</strong>. The salesrep requests creation, the designer develops, and the client approves via an external link.' },
      { question: '12. How do I track profitability?', answer: 'The C-Level panel displays <strong>interactive Dashboards with formatted P&L, fixed/variable costs, contribution margin, and EBITDA in real time</strong>.' },
      { question: '13. Does it have API integration?', answer: 'Yes. We have a robust <strong>open RESTful API and configurable Webhooks</strong> for you to connect e-commerce, legacy ERPs, or Make/Zapier bots.' },
      { question: '14. How to schedule a demo?', answer: 'Just scroll down to the <strong>"Request Elite Access"</strong> form, fill in your corporate details, and our engineering team will schedule a technical call.' }
    ]
  },
  es: {
    bootingText: 'Iniciando protocolo seguro...',
    nav: { pillars: 'Los Pilares', architecture: 'Arquitectura', ecosystem: 'Ecosistema', plans: 'Planes', login: 'Acceder ERP' },
    hero: { badge: 'Software de Gestión Propietario.', title: 'El fin de la <br><span class="gradient-text">fragmentación.</span>', subtitle: 'El centro de mando definitivo para operaciones industriales, confecciones y distribuidoras. Abandone sistemas genéricos y asuma el control absoluto de su ecosistema corporativo.', ctaPrimary: 'Solicitar Demostración', ctaSecondary: 'Explorar Arquitectura' },
    pillars: {
      sectionTitle: 'Gobernanza Operativa Elevada', sectionDesc: 'Diseñado para empresas que superaron la capacidad de las hojas de cálculo y los ERP genéricos.',
      items: [
        { icon: 'mdi-vector-combine', bgClass: 'bg-primary-lighten', textClass: 'text-primary', title: 'Centralización Absoluta', desc: 'Una única fuente de verdad. La venta en el TPV actualiza el estado de resultados, consume insumos en el MRP, agenda la producción y dispara la separación.' },
        { icon: 'mdi-chart-timeline-variant-shimmer', bgClass: 'bg-success-lighten', textClass: 'text-success', title: 'Inteligencia en Tiempo Real', desc: 'Decisiones basadas en datos vivos. Dashboards C-Level que reflejan el pulso de la fábrica, el flujo de caja y la eficiencia de ventas instantáneamente.' },
        { icon: 'mdi-shield-check-outline', bgClass: 'bg-warning-lighten', textClass: 'text-warning', title: 'Gobernanza Fiscal y Financiera', desc: 'Cumplimiento blindado. Motor tributario integrado para facturación gubernamental con cálculo autónomo. Conciliación Open Finance automática.' },
        { icon: 'mdi-forum-outline', bgClass: 'bg-secondary-lighten', textClass: 'text-secondary', title: 'Comunicación Inviolable', desc: 'Erradique el WhatsApp corporativo. Todo el diálogo sobre pedidos, diseños y aprobaciones ocurre dentro de la plataforma, con pista de auditoría.' }
      ]
    },
    carousel: {
      title: 'Aceleración Táctica',
      items: [
        { icon: 'mdi-factory', color: 'teal', title: 'Multitienda y Sucursales', desc: 'Gestione el inventario y la facturación de toda su red de tiendas y almacenes a través de un Tenant consolidado.' },
        { icon: 'mdi-account-key', color: 'indigo', title: 'Granularidad RLS', desc: 'Permisos estrictos a nivel de base de datos. El vendedor A jamás verá la cartera de clientes del vendedor B.' },
        { icon: 'mdi-cloud-sync', color: 'purple', title: 'API y Webhooks', desc: 'Arquitectura Headless lista para integrar con e-commerce, CRMs externos, PowerBI y bots de automatización.' },
        { icon: 'mdi-alarm-light-outline', color: 'error', title: 'Alertas Proactivas', desc: 'El sistema le avisa antes de que ocurra el problema: stock mínimo alcanzado, retraso en producción o factura vencida.' },
        { icon: 'mdi-file-document-multiple-outline', color: 'success', title: 'Gestión Documental', desc: 'GED integrado. Almacene PDFs, XMLs de facturas y comprobantes de pago vinculados directamente a los registros.' }
      ]
    },
    architecture: {
      title: 'El Sistema Nervioso Central', desc: 'Una malla tecnológica viva. Construido sobre PostgreSQL y Edge Functions para soportar volumen masivo sin cuellos de botella.',
      nodes: [
        { title: 'Cloud Nativa 100%', desc: 'Clústeres distribuidos garantizando 99.9% de uptime y espejado de datos (Backups PITR).' },
        { title: 'Procesamiento Edge', desc: 'Lógica pesada ejecutada cerca del usuario para latencia casi nula.' },
        { title: 'Criptografía RLS', desc: 'Aislamiento absoluto. Políticas de seguridad a nivel de fila en la base de datos.' },
        { title: 'API e Integraciones', desc: 'Su operación conectada al mundo a través de endpoints REST y Webhooks seguros.' }
      ]
    },
    ecosystem: { title: 'EL ECOSISTEMA', inspectBtn: 'Explorar Módulo' },
    chatMockup: { team: 'Equipo de Diseño', online: '3 en línea', msg1: 'El diseño del Pedido #4023 necesita revisión urgente.', msg2: 'Correcto, archivo abierto. ¡Ajustando el margen de corte!', placeholder: 'Escriba su mensaje...' },
    pricing: {
      title: 'Transparencia a Escala Corporativa', desc: 'Elija el poder computacional y la infraestructura que su etapa operativa requiere. Sin tarifas ocultas.', popularBadge: 'Más Elegido', compareTitle: 'Comparativa Definitiva de Funciones',
      plans: [
        { tier: 'Iniciante', name: 'Básico', price: '$ 60', period: '/mes', desc: 'El primer paso definitivo. Ideal para microoperaciones abandonando hojas de cálculo.', userLimitIcon: 'mdi-check-decagram', userLimit: '3 Usuarios Activos Incluidos', extraUser: '+ $ 10 por usuario adicional', features: ['TPV Ágil y Ventas', 'Financiero Simplificado', 'Control de Stock Base', 'Soporte Horario Comercial'], btnText: 'Inicie el Viaje', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Avanzado', name: 'Pro', price: '$ 150', period: '/mes', desc: 'El punto de inflexión para pymes que exigen control absoluto sobre producción y caja.', userLimitIcon: 'mdi-check-decagram', userLimit: '10 Usuarios Activos Incluidos', extraUser: '+ $ 8 por usuario adicional', features: ['Kanban Interactivo', 'Motor Fiscal en Lote', 'Estado de Resultados Completo', 'Chat Interno Integrado'], btnText: 'Prueba Gratis (14 días)', btnColor: 'primary', btnVariant: 'flat', highlight: true, dark: false },
        { tier: 'Expansión', name: 'Business', price: '$ 300', period: '/mes', desc: 'Para empresas con múltiples sucursales, distribuidores robustos y alto volumen.', userLimitIcon: 'mdi-check-decagram', userLimit: '30 Usuarios Activos Incluidos', extraUser: '+ $ 6 por usuario adicional', features: ['Multitienda / Multi-Empresa', 'MRP Avanzado y Máquinas', 'Design Studio Web', 'API Pública para Integrar'], btnText: 'Hablar con Consultor', btnColor: '', btnVariant: 'outlined', highlight: false, dark: false },
        { tier: 'Corporativo Privado', name: 'Enterprise', price: 'Consulte', period: '', desc: 'Infraestructura dedicada. Solución marca blanca con desarrollo a medida.', userLimitIcon: 'mdi-infinity', userLimit: 'Usuarios Ilimitados', extraUser: 'Sin costos por asiento', features: ['Base de Datos Aislada', 'SLA de 99.9% Contractual', 'Soporte 24/7 Ingeniería', 'Personalización Core'], btnText: 'Agendar Reunión C-Level', btnColor: 'white', btnVariant: 'flat', highlight: false, dark: true }
      ],
      table: { col1: 'Módulos y Recursos', rows: [
        { feat: 'CRM, Ventas y TPV', b: '<i class="mdi mdi-check text-success text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check text-success text-h5"></i>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Gestión Financiera', b: 'Simplificado', p: 'Gerencial Completo', bu: 'Gerencial Completo', e: 'Personalizado (BI)' },
        { feat: 'Control de Producción', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: '<i class="mdi mdi-check text-primary text-h5"></i>', bu: '<i class="mdi mdi-check-all text-success text-h5"></i><br><span class="text-caption">MRP Avanzado</span>', e: '<i class="mdi mdi-check-all text-success text-h5"></i>' },
        { feat: 'Facturación en Lote', b: 'Add-on Pagado', p: 'Ilimitado', bu: 'Ilimitado', e: 'Ilimitado API Privada' },
        { feat: 'Chat Corporativo', b: '<i class="mdi mdi-minus text-error text-h5"></i>', p: 'Hasta 3 Canales', bu: '<i class="mdi mdi-check text-success text-h5"></i><br><span class="text-caption">Ilimitado</span>', e: '<i class="mdi mdi-check text-success text-h5"></i>' },
        { feat: 'Módulos Extra (Flota, Diseño)', b: 'No soportado', p: '$ 30 / Módulo Extra', bu: '<span class="text-success">Todos Incluidos</span>', e: '<span class="text-success">Todos Incluidos</span>' }
      ]}
    },
    form: {
      title: 'No cambie de sistema.<br>Cambie de nivel.', desc: 'Agende una demostración estratégica enfocada en el cuello de botella exacto de su operación. Mostraremos cómo MJ Process reemplaza su stack actual.',
      bullets: [{ icon: 'mdi-check-all', text: 'Onboarding Asistido y Migración Segura' }, { icon: 'mdi-account-tie', text: 'Entrenamiento exclusivo para líderes' }, { icon: 'mdi-lock-open-check', text: 'Sin permanencia abusiva. ROI comprobado.' }],
      formTitle: 'Solicitar Acceso Élite', formDesc: 'Complete con datos reales. Nuestra ingeniería lo contactará en 10 minutos.',
      fields: {
        name: { label: 'Nombre Completo', placeholder: 'Ej: Carlos Silva' }, email: { label: 'Correo Corporativo', placeholder: 'carlos@suempresa.com' },
        phone: { label: 'Teléfono / WhatsApp', placeholder: '+55 11 99999-9999' }, role: { label: 'Cargo / Función', placeholder: 'Ej: Director de Producción' },
        size: { label: 'Tamaño de la operación', options: ['Seleccione el número de empleados...', 'Hasta 10 empleados (Crecimiento)', '11 a 50 empleados (Pyme)', '51 a 200 empleados (Escala)', 'Más de 200 empleados (Enterprise)'] }
      },
      submitBtn: 'Acceder a la Plataforma', privacyText1: 'Toda información está protegida bajo nuestra estricta', privacyText2: 'Política de Privacidad'
    },
    footer: {
      desc: 'El software de gestión propietario diseñado por ingenieros para empresas que exigen excelencia técnica, cumplimiento y control operativo absoluto.',
      col1: { title: 'Soluciones Corporativas', links: ['Producción y Kanban', 'Gestión Open Finance', 'Suscripciones SaaS', 'SLA y Disponibilidad'] },
      col2: { title: 'Ecosistema Táctico', links: ['Design Studio y Flujo', 'Impresión y Plotters', 'Compras y Cotizaciones', 'Documentación API REST'] },
      col3: { title: 'Gobernanza y Core', links: ['Cumplimiento Fiscal', 'Auditoría de Datos (Audit)', 'Aislamiento Multi-Tenant (RLS)', 'Infraestructura Cloud', 'Términos de Servicio', 'Política de Privacidad'] },
      copyright: 'Construido con arquitectura de punta.'
    },
    modal: { inspect: 'Inspeccionar Interfaz', capabilities: 'Capacidades Estratégicas', scheduleBtn: 'Agendar Configuración del Módulo' },
    chatBot: { online: 'En línea y listo', greeting: '¡Hola! Noté que está evaluando el sistema. A continuación, las principales dudas de nuestros clientes enterprise. ¿Qué desea saber?', backBtn: 'Volver a opciones', ctaBtn: 'Agendar Demostración', footer: 'Asistente Comercial MJ Process' },
    modules: [
      { id: 'producao', title: 'Planta de Producción y Kanban', description: 'Rastree cada milímetro de su proceso productivo en tiempo real. Identifique ociosidad y plazos de entrega.', features: ['Fichaje de horas por código de barras.', 'Lista de Materiales (BOM) detallada.', 'Trazabilidad total de Lotes.', 'Vista Kanban personalizable.'] },
      { id: 'design', title: 'Design Studio y Aprobaciones', description: 'Elimine idas y venidas en WhatsApp. El pedido llega al diseñador. El arte se aprueba digitalmente vía enlace.', features: ['Control de versiones e historial.', 'Panel integrado al Kanban.', 'Enlace externo marca blanca para cliente.', 'Marcas de corrección directas.'] },
      { id: 'pcp', title: 'MRP: Orquestación Fina', description: 'Planificación avanzada de producción. Asignación de máquinas, Gantt para cuellos de botella y cálculo inverso de entrega.', features: ['Gantt de ocupación de máquinas.', 'Explosión de materiales predictiva.', 'Cálculo dinámico de plazo de entrega.', 'Alertas de mantenimiento.'] },
      { id: 'printing', title: 'Estación de Impresión', description: 'El puente entre el ERP y su plotter. Cola organizada y conteo quirúrgico de consumo de tinta/papel por OP.', features: ['Cola priorizada por el MRP.', 'Integración de estado "Impreso".', 'Deducción automática de metros.', 'Verificación visual pre-impresión.'] },
      { id: 'fiscal', title: 'Cumplimiento Fiscal', description: 'El motor tributario autónomo. Olvide la digitación manual: emita decenas de facturas en lote con 1 clic.', features: ['Emisión y cancelación en lote.', 'Cálculo automático de impuestos.', 'Manifestación electrónica.', 'Exportación contable (XML).'] },
      { id: 'financeiro', title: 'Tesorería y Resultados', description: 'Salud financiera dibujada en pantalla. Conciliación bancaria Open Finance y Estado de Resultados en tiempo real.', features: ['P&L actualizado instantáneamente.', 'Conciliación bancaria automatizada.', 'Control de múltiples cajas.', 'Emisión de Facturas y links vía API.'] },
      { id: 'cotacoes', title: 'Compras y Cotizaciones', description: 'Convierta las compras en un generador de ganancias. Compare matrices de precios lado a lado y apruebe la mejor oferta.', features: ['Mapa comparativo visual.', 'Gestión de proveedores con rating.', 'Generación automática de Cuentas por Pagar.', 'Historial de precios de insumos.'] },
      { id: 'receivables', title: 'Cuentas por Cobrar y Morosidad', description: 'Panel dedicado para seguimiento de facturas, pagos parciales y reglas de cobro preconfiguradas.', features: ['Panel de Vencimientos.', 'Liquidación vía archivo bancario.', 'Recordatorios vía WhatsApp.', 'Límites de crédito y bloqueo.'] },
      { id: 'chat', title: 'Chat Corporativo Contextual', description: 'La prueba para auditorías. Comuníquese con el equipo dentro del contexto del Pedido, con archivos adjuntos e historial.', features: ['Canales por departamentos.', 'Archivos vinculados al pedido.', 'Confirmaciones de lectura en tiempo real.', 'Fin absoluto de WhatsApp.'] }
    ],
    faqs: [
      { question: '1. ¿A qué tipos de empresas atiende el sistema?', answer: 'Principalmente <strong>Industrias, Confecciones, Impresión y Distribuidoras robustas</strong>. Reemplazamos stacks complejos por una plataforma única.' },
      { question: '2. ¿Tiene facturación electrónica?', answer: 'Sí, completa. El motor fiscal <strong>emite y cancela facturas en lote</strong>. Consulta reglas tributarias y calcula impuestos automáticamente.' },
      { question: '3. ¿Hay control de producción en planta?', answer: 'Sí. Tenemos un <strong>MRP avanzado con Kanban interactivo, seguimiento en tablet, explosión de materiales (BOM) y asignación de máquinas</strong>.' },
      { question: '4. ¿El módulo financiero está integrado?', answer: 'Absolutamente. Todas las facturas nacen de OP o Compras. Tenemos <strong>Estado de Resultados, flujo de caja y conciliación Open Finance</strong>.' },
      { question: '5. ¿Soporta Multitienda/Sucursales?', answer: 'Sí. Infraestructura de Tenant aislada, permitiendo control de <strong>Múltiples RFC/RUT, almacenes y cajas por separado</strong>.' },
      { question: '6. ¿El equipo de ventas puede usarlo?', answer: 'Sí. El CRM tiene <strong>TPV Ágil, catálogo digital, comisiones automáticas y seguimiento de producción por el vendedor</strong>.' },
      { question: '7. ¿Cómo funciona el Chat Interno?', answer: 'Es un <strong>sustituto corporativo para WhatsApp</strong>. Canales dedicados vinculados a Pedidos donde el equipo discute y envía archivos de forma segura.' },
      { question: '8. ¿Cómo se controlan los permisos?', answer: 'Usamos <strong>RLS (Row Level Security) en PostgreSQL</strong>. Un vendedor es incapaz de acceder a datos que no le pertenecen. Alta seguridad.' },
      { question: '9. ¿El sistema opera en la nube (SaaS)?', answer: 'Sí. Somos <strong>100% Cloud Native</strong> (AWS vía Supabase), garantizando 99.9% de uptime y backups PITR.' },
      { question: '10. ¿La plataforma tiene soporte e implementación?', answer: 'Sí. Todo contrato Pro o Enterprise incluye un <strong>Onboarding asistido con migración de datos y seguimiento de éxito</strong>.' },
      { question: '11. ¿Hay módulo de Diseño y Aprobación?', answer: 'Sí, el exclusivo <strong>Design Studio</strong>. El vendedor solicita, el diseñador desarrolla y el cliente aprueba vía enlace externo.' },
      { question: '12. ¿Cómo sigo la rentabilidad?', answer: 'El panel C-Level muestra <strong>Dashboards interactivos con P&L, costos, margen de contribución y EBITDA en tiempo real</strong>.' },
      { question: '13. ¿Tiene integración vía API?', answer: 'Sí. Poseemos una robusta <strong>API RESTful abierta y Webhooks configurables</strong> para conectar e-commerce o ERPs heredados.' },
      { question: '14. ¿Cómo agendar una demostración?', answer: 'Solo deslícese al formulario <strong>"Solicitar Acceso Élite"</strong>, complete sus datos y nuestra ingeniería agendará una llamada.' }
    ]
  }
};

const t = computed(() => i18n[currentLang.value]);

// ==========================================
// CHATBOT ENTERPRISE
// ==========================================
const isAssistantOpen = ref(false);
const toggleAssistant = () => isAssistantOpen.value = !isAssistantOpen.value;
const activeAssistantFaq = ref<any>(null);
const openAssistantFaq = (faq: any) => { activeAssistantFaq.value = faq; };
const faqList = computed(() => t.value.faqs);

// ==========================================
// DADOS DOS MÓDULOS
// ==========================================
const modulesList = computed(() => {
  return t.value.modules.map((mod: any) => {
    let images = {};
    if (mod.id === 'producao') images = { darkImg: ProducaoDark, lightImg: ProducaoLight, icon: 'mdi-factory', color: 'info' };
    else if (mod.id === 'design') images = { darkImg: DesignDark, lightImg: DesignLight, icon: 'mdi-palette-swatch', color: 'purple' };
    else if (mod.id === 'pcp') images = { darkImg: PCPDark, lightImg: PCPLight, icon: 'mdi-chart-gantt', color: 'indigo' };
    else if (mod.id === 'printing') images = { darkImg: PrintingDark, lightImg: PrintingLight, icon: 'mdi-printer-3d', color: 'cyan' };
    else if (mod.id === 'fiscal') images = { darkImg: FiscalDark, lightImg: FiscalLight, icon: 'mdi-script-text', color: 'warning' };
    else if (mod.id === 'financeiro') images = { darkImg: DREDark, lightImg: DRELight, icon: 'mdi-cash-multiple', color: 'success' };
    else if (mod.id === 'cotacoes') images = { darkImg: QuotationDark, lightImg: QuotationLight, icon: 'mdi-store-search', color: 'teal' };
    else if (mod.id === 'receivables') images = { darkImg: ReceivablesDark, lightImg: ReceivablesLight, icon: 'mdi-account-cash', color: 'indigo-accent-2' };
    else if (mod.id === 'chat') images = { isHtml: true, icon: 'mdi-forum', color: 'secondary' };
    return { ...mod, ...images };
  });
});

// ==========================================
// LÓGICA DO CARROSSEL
// ==========================================
const benefitsCarousel = ref<HTMLElement | null>(null);
const scrollCarousel = (direction: number) => {
  if (benefitsCarousel.value) {
    const scrollAmount = 350 * direction;
    benefitsCarousel.value.scrollBy({ left: scrollAmount, behavior: 'smooth' });
  }
};

// ==========================================
// LÓGICA DO MODAL & ZOOM
// ==========================================
const isModalOpen = ref(false);
const activeModuleId = ref<string>('');
const zoomContainer = ref<HTMLElement | null>(null);

const activeModuleData = computed(() => {
  return activeModuleId.value ? modulesList.value.find((m: any) => m.id === activeModuleId.value) : null;
});

const openModal = (id: string) => {
  activeModuleId.value = id;
  isModalOpen.value = true;
  nextTick(() => {
    const items = document.querySelectorAll('.modal-anim-item');
    items.forEach(el => {
      el.classList.remove('animate');
      void (el as HTMLElement).offsetWidth;
      el.classList.add('animate');
    });
  });
};

const isZooming = ref(false);
const startZoom = () => { isZooming.value = true; };
const handleZoom = (e: MouseEvent) => {
  if (!zoomContainer.value) return;
  const rect = zoomContainer.value.getBoundingClientRect();
  const x = ((e.clientX - rect.left) / rect.width) * 100;
  const y = ((e.clientY - rect.top) / rect.height) * 100;
  const target = zoomContainer.value.firstElementChild as HTMLElement;
  if (target) { target.style.transformOrigin = `${x}% ${y}%`; target.classList.add('zoomed'); }
};
const resetZoom = () => {
  isZooming.value = false;
  if (!zoomContainer.value) return;
  const target = zoomContainer.value.firstElementChild as HTMLElement;
  if (target) {
    target.classList.remove('zoomed');
    setTimeout(() => { if (!isZooming.value) target.style.transformOrigin = 'center center'; }, 300);
  }
};

const submitContactForm = () => {
  alert(currentLang.value === 'pt' ? 'Recebemos sua solicitação! Em breve um engenheiro fará contato.' : (currentLang.value === 'en' ? 'Request received! An engineer will contact you shortly.' : '¡Solicitud recibida! Un ingeniero lo contactará en breve.'));
};

// ==========================================
// INTERSECTION OBSERVER
// ==========================================
let observer: IntersectionObserver;

onMounted(() => {
  window.addEventListener('scroll', handleScroll);
  observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => { if (entry.isIntersecting) entry.target.classList.add('active'); });
  }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });
  document.querySelectorAll('.reveal-up, .reveal-left, .reveal-right').forEach((el) => { observer.observe(el); });
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
  if (observer) observer.disconnect();
});
</script>

<style scoped>
/* =========================================================
   1. ROOT VARIABLES & THEMES
========================================================= */
.mj-landing-wrapper {
  --transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  font-family: system-ui, -apple-system, sans-serif;
  background-color: var(--bg-main);
  color: var(--text-main);
  min-height: 100vh;
  transition: background-color 0.4s ease, color 0.4s ease;
  scroll-behavior: smooth;
}

.theme-dark {
  --bg-main: #09090b; --bg-alternate: #0f0f13; --bg-header: rgba(9, 9, 11, 0.85);
  --bg-card: rgba(255, 255, 255, 0.03); --bg-surface: #18181b; --border-card: rgba(255, 255, 255, 0.08);
  --text-main: #ffffff; --text-muted: #a1a1aa; --border-light: rgba(255,255,255,0.1);
  --bg-primary-lighten: rgba(var(--v-theme-primary), 0.1); --bg-success-lighten: rgba(var(--v-theme-success), 0.1);
  --bg-warning-lighten: rgba(var(--v-theme-warning), 0.1); --bg-secondary-lighten: rgba(var(--v-theme-secondary), 0.1);
  --glow-hero: radial-gradient(circle at 50% -20%, rgba(139, 92, 246, 0.15), transparent 60%);
  --gradient-text: linear-gradient(135deg, #a855f7 0%, #3b82f6 100%);
  --shadow-card: 0 8px 32px 0 rgba(0, 0, 0, 0.4); --backdrop-blur: blur(24px);
}

.theme-light {
  --bg-main: #f8fafc; --bg-alternate: #ffffff; --bg-header: rgba(255, 255, 255, 0.9);
  --bg-card: #ffffff; --bg-surface: #ffffff; --border-card: #e2e8f0;
  --text-main: #0f172a; --text-muted: #64748b; --border-light: rgba(0,0,0,0.1);
  --bg-primary-lighten: rgba(var(--v-theme-primary), 0.05); --bg-success-lighten: rgba(var(--v-theme-success), 0.08);
  --bg-warning-lighten: rgba(var(--v-theme-warning), 0.08); --bg-secondary-lighten: rgba(var(--v-theme-secondary), 0.08);
  --glow-hero: radial-gradient(circle at 50% 0%, rgba(226, 232, 240, 0.8), transparent 70%);
  --gradient-text: linear-gradient(135deg, #2563eb 0%, #0f172a 100%);
  --shadow-card: 0 10px 30px -5px rgba(0, 0, 0, 0.05); --backdrop-blur: blur(12px);
}

a { text-decoration: none; color: inherit; }
.gradient-text { background: var(--gradient-text); -webkit-background-clip: text; color: transparent; }
.muted-text { color: var(--text-muted) !important; }
.bg-alternate { background-color: var(--bg-alternate); }
.bg-surface { background-color: var(--bg-surface); }
.bg-primary-lighten { background-color: var(--bg-primary-lighten); }
.bg-success-lighten { background-color: var(--bg-success-lighten); }
.bg-warning-lighten { background-color: var(--bg-warning-lighten); }
.bg-secondary-lighten { background-color: var(--bg-secondary-lighten); }
.border-b { border-bottom: 1px solid var(--border-light); }
.border-b-primary { border-bottom: 1px solid rgba(var(--v-theme-primary), 0.3); }
.border-b-grey { border-bottom: 1px solid rgba(255,255,255,0.2); }
.border-t { border-top: 1px solid var(--border-light); }
.border-r { border-right: 1px solid var(--border-light); }
.border { border: 1px solid var(--border-card); }
.opacity-20 { opacity: 0.2; } .opacity-50 { opacity: 0.5; } .opacity-80 { opacity: 0.8; }
.max-w-800 { max-width: 800px; margin: 0 auto; } .max-w-1200 { max-width: 1200px; margin: 0 auto; }
.w-80 { width: 80%; } .w-90 { width: 90%; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; } .gap-5 { gap: 20px; }
.line-height-tight { line-height: 1.1 !important; } .tracking-tight { letter-spacing: -0.03em; }
.cursor-pointer { cursor: pointer; } .object-fit-contain { object-fit: contain; } .object-cover { object-fit: cover; }
.pointer-events-none { pointer-events: none; }
.shadow-sm { box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
.shadow-2xl { box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); }

/* BOOT SEQUENCE */
.enterprise-boot-screen { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: var(--bg-main); z-index: 9999; display: flex; align-items: center; justify-content: center; }
.boot-content { display: flex; flex-direction: column; align-items: center; gap: 24px; width: 300px; }
.boot-logo { height: 48px; filter: drop-shadow(0 0 10px rgba(var(--v-theme-primary), 0.5)); }
.pulse-anim { animation: smoothPulse 2s infinite ease-in-out; }
.boot-loader-container { width: 100%; height: 4px; background: rgba(var(--v-theme-primary), 0.1); border-radius: 4px; overflow: hidden; }
.boot-loader-bar { height: 100%; background: rgb(var(--v-theme-primary)); transition: width 0.4s; }
.boot-text { font-size: 0.85rem; color: var(--text-muted); letter-spacing: 0.05em; text-transform: uppercase; }
@keyframes smoothPulse { 0%, 100% { opacity: 0.7; transform: scale(0.98); } 50% { opacity: 1; transform: scale(1); } }
.fade-boot-enter-active, .fade-boot-leave-active { transition: opacity 0.6s ease; }
.fade-boot-enter-from, .fade-boot-leave-to { opacity: 0; }

/* LANG TRANSITION */
.lang-transition-wrapper { transition: opacity 0.3s ease, filter 0.3s ease, transform 0.3s ease; }
.lang-transition-wrapper.is-animating { opacity: 0; filter: blur(8px); transform: scale(0.99); pointer-events: none; }

/* TYPOGRAPHY */
.colossal-title { font-size: clamp(3rem, 8vw, 5.5rem); font-weight: 900; line-height: 1.05; letter-spacing: -0.04em; margin-bottom: 12px; text-align: center; }
.colossal-title-center { font-size: clamp(2.5rem, 10vw, 6rem); font-weight: 900; line-height: 1; letter-spacing: -0.05em; text-align: center; margin: 40px 0; }
.hero-subtitle { font-size: 1.25rem; color: var(--text-muted); max-width: 800px; text-align: center; line-height: 1.6; }
.section-padding { padding: 120px 0; }
.section-header { text-align: center; margin-bottom: 80px; }
.section-header h2 { font-size: clamp(2.2rem, 4vw, 3.5rem); font-weight: 900; margin-bottom: 16px; }
.section-header p { font-size: 1.2rem; color: var(--text-muted); max-width: 700px; margin: 0 auto; }

/* CARDS & BUTTONS */
.mj-card { background: var(--bg-card); border: 1px solid var(--border-card); border-radius: 24px; padding: 32px; box-shadow: var(--shadow-card); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur); position: relative; transition: var(--transition); }
.mj-btn-outline { border: 1px solid var(--border-card) !important; color: var(--text-main) !important; }
.mj-btn-outline:hover { border-color: rgb(var(--v-theme-primary)) !important; color: rgb(var(--v-theme-primary)) !important; background: transparent !important; }
.hero-btn-glow { box-shadow: 0 10px 30px -10px rgba(var(--v-theme-primary), 0.7) !important; }
.submit-btn-glow { box-shadow: 0 0 20px rgba(var(--v-theme-primary), 0.5) !important; transition: all 0.3s ease; }
.submit-btn-glow:hover { transform: translateY(-3px); box-shadow: 0 0 30px rgba(var(--v-theme-primary), 0.8) !important; }
.hover-lift { transition: transform 0.3s ease, box-shadow 0.3s ease; }
.hover-lift:hover { transform: translateY(-4px); box-shadow: var(--shadow-card); border-color: rgba(var(--v-theme-primary), 0.4); }
.dark-force { background: #000 !important; border-color: #222 !important; color: #fff !important; }

/* HEADER */
.glass-header { position: fixed; top: 0; left: 0; width: 100%; height: 80px; z-index: 100; display: flex; align-items: center; transition: var(--transition); border-bottom: 1px solid transparent; }
.glass-header.scrolled { background: var(--bg-header); backdrop-filter: var(--backdrop-blur); border-bottom: 1px solid var(--border-card); }
.header-content { display: flex; align-items: center; justify-content: space-between; width: 100%; max-width: 1200px; margin: 0 auto; padding: 0 24px; }
.logo { cursor: pointer; height: 36px; }
.desktop-nav { display: none; gap: 32px; font-weight: 600; font-size: 0.95rem; }
.desktop-nav a { color: var(--text-muted); transition: var(--transition); }
.desktop-nav a:hover { color: rgb(var(--v-theme-primary)); }
.header-actions { display: flex; align-items: center; gap: 16px; }
.lang-btn { text-transform: none; letter-spacing: 0.5px; }
.webmail-link { font-weight: 700; display: none; }
@media(min-width: 960px) { .desktop-nav { display: flex; } .webmail-link { display: block; } }

/* HERO & 3D */
.hero-section { position: relative; padding-top: 160px; overflow: hidden; }
.hero-glow { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: var(--glow-hero); z-index: 0; pointer-events: none; }
.badge-premium { display: inline-block; padding: 6px 16px; border-radius: 20px; background: rgba(var(--v-theme-primary), 0.1); color: rgb(var(--v-theme-primary)); font-weight: 800; font-size: 0.85rem; letter-spacing: 0.1em; text-transform: uppercase; border: 1px solid rgba(var(--v-theme-primary), 0.2); }

.dashboard-3d-container { perspective: 1500px; margin-top: 60px; padding-bottom: 80px; }
.dashboard-wrapper { max-width: 900px; margin: 0 auto; transform: rotateX(12deg) rotateY(-5deg) rotateZ(1deg); transform-style: preserve-3d; transition: transform 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); }
.dashboard-wrapper:hover { transform: rotateX(2deg) rotateY(0deg) rotateZ(0deg) scale(1.02); }
.dashboard-img { width: 100%; border-radius: 20px; border: 1px solid var(--border-card); box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5); display: block; }

/* BENEFITS & NEURAL NET */
.pillar-card { padding: 48px 40px; overflow: hidden; position: relative; border: 1px solid var(--border-card); }
.pillar-icon { width: 64px; height: 64px; border-radius: 16px; display: flex; align-items: center; justify-content: center; }
.pillar-glow { position: absolute; bottom: -50px; right: -50px; width: 150px; height: 150px; background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.2), transparent 70%); filter: blur(20px); pointer-events: none; opacity: 0; transition: opacity 0.4s ease; }
.pillar-card:hover .pillar-glow { opacity: 1; }

.benefits-carousel-wrapper { position: relative; margin-top: 40px; }
.benefits-carousel { display: flex; gap: 24px; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 20px; -webkit-overflow-scrolling: touch; scrollbar-width: none; }
.benefits-carousel::-webkit-scrollbar { display: none; }
.carousel-item { min-width: 300px; max-width: 320px; flex: 0 0 auto; scroll-snap-align: start; cursor: grab; }

.ambient-clouds { position: absolute; top: -20%; left: -20%; width: 140%; height: 140%; background: radial-gradient(circle at 30% 50%, rgba(var(--v-theme-primary), 0.05), transparent 40%), radial-gradient(circle at 70% 60%, rgba(var(--v-theme-info), 0.05), transparent 40%); filter: blur(60px); z-index: 0; pointer-events: none; }
.neural-network-layout { position: relative; width: 100%; max-width: 1000px; margin: 0 auto; padding: 60px 0; }
.neural-lines { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; pointer-events: none; }
.data-flow-line { fill: none; stroke: var(--border-card); stroke-width: 2; stroke-dasharray: 10, 10; animation: dashMove 30s linear infinite; }
.data-particle { fill: rgb(var(--v-theme-primary)); filter: drop-shadow(0 0 5px rgb(var(--v-theme-primary))); animation: pulseParticle 2s infinite; }
.delay-1 { animation-delay: -1s; } .delay-2 { animation-delay: -2s; }
@keyframes dashMove { to { stroke-dashoffset: -1000; } }
@keyframes pulseParticle { 0%, 100% { opacity: 0.5; transform: scale(1); } 50% { opacity: 1; transform: scale(1.5); } }
.neural-nodes-container { display: flex; flex-direction: column; align-items: center; gap: 40px; position: relative; z-index: 2; }
@media(min-width: 960px) { .neural-nodes-container { flex-direction: row; justify-content: space-between; } }
.neural-side { display: flex; flex-direction: column; gap: 24px; flex: 1; justify-content: center; }
.neural-node { padding: 24px; text-align: left; background: var(--bg-card); backdrop-filter: var(--backdrop-blur); border: 1px solid var(--border-light); }
.neural-core { display: flex; align-items: center; justify-content: center; flex: 1; min-height: 250px; }
.core-orb { position: relative; width: 140px; height: 140px; border-radius: 50%; background: rgb(var(--v-theme-primary)); display: flex; flex-direction: column; align-items: center; justify-content: center; box-shadow: 0 0 40px rgba(var(--v-theme-primary), 0.6); }
.orb-glow { position: absolute; top: -50%; left: -50%; width: 200%; height: 200%; background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.4), transparent 60%); animation: spinGlow 10s linear infinite; }
@keyframes spinGlow { 100% { transform: rotate(360deg); } }

/* ECOSYSTEM TILT & MODULOS */
.sticky-title { position: sticky; top: 80px; background: var(--bg-main); z-index: 5; overflow: hidden; }
.modules-container { padding-top: 80px; padding-bottom: 120px; }
.module-row { min-height: 50vh; }
.feature-list { list-style: none; padding: 0; display: flex; flex-direction: column; gap: 16px; font-size: 1.05rem; }
.feature-list li { display: flex; gap: 12px; align-items: flex-start; }

.perspective-wrapper { perspective: 1500px; padding: 20px; }
.tilted-mockup { transform-style: preserve-3d; transition: transform 0.6s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.6s ease; cursor: pointer; position: relative; }
/* Invertido para abraçar o texto */
.tilted-mockup.left-tilt { transform: rotateX(10deg) rotateY(-15deg) rotateZ(2deg); box-shadow: -20px 30px 50px rgba(0, 0, 0, 0.25); }
.tilted-mockup.right-tilt { transform: rotateX(10deg) rotateY(15deg) rotateZ(-2deg); box-shadow: 20px 30px 50px rgba(0, 0, 0, 0.25); }
.tilted-mockup:hover { transform: rotateX(2deg) rotateY(0deg) rotateZ(0deg) scale(1.05); box-shadow: 0 40px 80px rgba(0, 0, 0, 0.4); border-color: rgba(var(--v-theme-primary), 0.6); }

.expand-hint { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) scale(0.9); background: rgba(var(--v-theme-primary), 0.9); color: white; padding: 12px 24px; border-radius: 30px; font-weight: bold; font-size: 1rem; display: flex; align-items: center; opacity: 0; transition: all 0.3s ease; z-index: 10; pointer-events: none; backdrop-filter: blur(4px); box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
.interactive-mockup::after { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0); transition: background 0.3s ease; z-index: 5; pointer-events: none; }
.interactive-mockup:hover::after { background: rgba(0,0,0,0.4); }
.interactive-mockup:hover .expand-hint { opacity: 1; transform: translate(-50%, -50%) scale(1); }
.mockup-image { transition: transform 0.5s ease; }

.chat-mockup { display: flex; flex-direction: column; min-height: 400px; }
.bubble { padding: 14px 18px; border-radius: 16px; max-width: 85%; font-size: 0.95rem; }
.bubble.left { background: var(--bg-main); border: 1px solid var(--border-card); align-self: flex-start; border-bottom-left-radius: 4px; }
.bubble.right { background: rgb(var(--v-theme-secondary)); color: white; align-self: flex-end; border-bottom-right-radius: 4px; }
.typing .dot { display: inline-block; width: 6px; height: 6px; background: var(--text-muted); border-radius: 50%; margin-right: 4px; animation: blink 1.4s infinite; }
.typing .dot:nth-child(2) { animation-delay: 0.2s; } .typing .dot:nth-child(3) { animation-delay: 0.4s; }

/* PRICING & TABLE */
.pricing-card { display: flex; flex-direction: column; padding: 48px 32px; border: 1px solid var(--border-card); }
.pricing-card.highlighted { border-color: rgb(var(--v-theme-primary)); transform: scale(1.02); box-shadow: 0 20px 40px rgba(var(--v-theme-primary), 0.15); z-index: 2; }
.popular-badge { position: absolute; top: 0; right: 0; background: rgb(var(--v-theme-primary)); color: white; padding: 6px 20px; border-bottom-left-radius: 16px; font-weight: bold; font-size: 0.8rem; text-transform: uppercase; }
.plan-name { font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.9rem; color: var(--text-muted); }
.price { font-size: 3rem; font-weight: 900; margin-bottom: 8px; }
.price span { font-size: 1.1rem; font-weight: 500; color: var(--text-muted); }
.plan-desc { font-size: 1rem; color: var(--text-muted); line-height: 1.5; }
.plan-features { list-style: none; padding: 0; display: flex; flex-direction: column; gap: 16px; font-size: 1rem; flex-grow: 1; }
.plan-features li { display: flex; align-items: flex-start; gap: 12px; }

.custom-table-wrapper { overflow-x: auto; border: 1px solid var(--border-card); border-radius: 16px; }
.comparison-table { border-collapse: collapse; width: 100%; min-width: 900px; }
.comparison-table th, .comparison-table td { transition: background-color 0.2s; }
.comparison-table th { font-size: 1.1rem; }
.comparison-table .table-row:hover td { background-color: var(--bg-alternate); }
.comparison-table .table-row:hover td.bg-primary-lighten { background-color: rgba(var(--v-theme-primary), 0.15); }
.comparison-table .table-row:hover td.bg-black-force { background-color: #111 !important; }
.sticky-col { position: sticky; left: 0; z-index: 2; border-right: 1px solid var(--border-light); }

/* FORMULÁRIO */
.cta-card { border: 1px solid var(--border-card); border-radius: 24px; box-shadow: var(--shadow-card); }
.cta-glow-bg { position: absolute; top: -50%; left: -50%; width: 200%; height: 200%; background: radial-gradient(circle, rgba(var(--v-theme-primary), 0.15), transparent 60%); pointer-events: none; z-index: 0; }
.premium-custom-form { width: 100%; }
.input-group { display: flex; flex-direction: column; gap: 8px; width: 100%; }
.form-label { font-size: 0.9rem; font-weight: 600; color: var(--text-muted); margin-left: 4px; }
.mj-premium-input { width: 100%; padding: 16px 20px; border-radius: 12px; border: 1px solid var(--border-card); background: var(--bg-main); color: var(--text-main); font-size: 1rem; font-family: inherit; transition: all 0.3s ease; outline: none; box-shadow: inset 0 2px 4px rgba(0,0,0,0.02); }
.mj-premium-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.2); }
.mj-premium-input::placeholder { color: var(--text-muted); opacity: 0.6; }
select.mj-premium-input { appearance: none; cursor: pointer; }
.select-icon { background-image: url('data:image/svg+xml;charset=US-ASCII,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%23a1a1aa"><path d="M7 10l5 5 5-5z"/></svg>'); background-repeat: no-repeat; background-position: right 16px center; background-size: 24px; }
.mj-btn-primary { background-color: rgb(var(--v-theme-primary)); color: white; border: none; cursor: pointer; }

/* ASSISTENTE */
.mj-assistant-widget { position: fixed; bottom: 24px; right: 24px; z-index: 999; display: flex; flex-direction: column; align-items: flex-end; gap: 16px; }
.assistant-trigger { width: 60px; height: 60px; border-radius: 50%; background: rgb(var(--v-theme-primary)); display: flex; align-items: center; justify-content: center; cursor: pointer; box-shadow: 0 10px 25px rgba(var(--v-theme-primary), 0.4); position: relative; transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.assistant-trigger:hover { transform: scale(1.1); }
.trigger-glow { position: absolute; width: 100%; height: 100%; border-radius: 50%; background: rgb(var(--v-theme-primary)); z-index: -1; animation: ping 2s infinite ease-in-out; opacity: 0.5; }
@keyframes ping { 0% { transform: scale(1); opacity: 0.8; } 100% { transform: scale(1.5); opacity: 0; } }
.assistant-window { width: 400px; background: var(--bg-main); border-radius: 20px; transform-origin: bottom right; animation: scaleUp 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; }
@keyframes scaleUp { from { opacity: 0; transform: scale(0.5); } to { opacity: 1; transform: scale(1); } }
.assistant-bubble { position: relative; line-height: 1.4; } .bot-bubble { border-bottom-left-radius: 4px; } .user-bubble { border-bottom-right-radius: 4px; }
.faq-option-chip { transition: background 0.2s, border-color 0.2s; } .faq-option-chip:hover { background: var(--bg-alternate); border-color: rgb(var(--v-theme-primary)) !important; }
.slide-fade-enter-active { transition: all 0.3s ease-out; } .slide-fade-leave-active { transition: all 0.2s cubic-bezier(1, 0.5, 0.8, 1); }
.slide-fade-enter-from { transform: translateX(20px); opacity: 0; } .slide-fade-leave-to { transform: translateX(-20px); opacity: 0; }

/* MODAL INTERATIVO */
.modal-inner-wrapper { min-height: auto; background: transparent; }
.premium-modal { background: var(--bg-surface) !important; border-radius: 24px; box-shadow: 0 40px 100px rgba(0,0,0,0.5) !important; border: 1px solid var(--border-card); }
.modal-close-btn { position: absolute; top: 16px; right: 16px; z-index: 50; color: var(--text-main); transition: var(--transition); }
.modal-close-btn:hover { background: rgba(var(--v-theme-error), 0.1) !important; color: rgb(var(--v-theme-error)); transform: rotate(90deg); }
.modal-image-panel { min-height: 400px; }
.zoomable-image, .zoomable-html { transition: transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1); transform-origin: center center; will-change: transform; }
.zoomable-image.zoomed, .zoomable-html.zoomed { transform: scale(2.2); cursor: crosshair; }
.modal-anim-item { opacity: 0; transform: translateY(20px); }
.modal-anim-item.animate { animation: slideUpFade 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; animation-delay: var(--anim-delay); }

/* ANIMATIONS & OBSERVER */
.reveal-up { opacity: 0; transform: translateY(40px); transition: opacity 0.8s ease-out, transform 0.8s ease-out; }
.reveal-up.active { opacity: 1; transform: translateY(0); }
.reveal-left { opacity: 0; transform: translateX(-40px); transition: opacity 0.8s ease-out, transform 0.8s ease-out; }
.reveal-left.active { opacity: 1; transform: translateX(0); }
.reveal-right { opacity: 0; transform: translateX(40px); transition: opacity 0.8s ease-out, transform 0.8s ease-out; }
.reveal-right.active { opacity: 1; transform: translateX(0); }
@keyframes slideUpFade { to { opacity: 1; transform: translateY(0); } }
.footer-link { font-weight: 500; color: var(--text-muted); transition: color 0.2s; font-size: 0.95rem; }
.footer-link:hover { color: rgb(var(--v-theme-primary)); }
</style>
