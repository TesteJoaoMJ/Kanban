<template>
  <v-app class="catalog-app font-sans no-select" :class="[{ 'is-mobile': isMobile }, themeStore.currentMode === 'dark' ? 'theme-dark bg-grey-darken-4' : 'theme-light bg-white']">

    <v-app-bar :color="themeStore.currentMode === 'light' ? 'rgba(255, 255, 255, 0.8)' : 'rgba(18, 18, 18, 0.8)'" flat height="60" class="border-b px-md-10 sticky-header" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-4' : 'border-white-10'" style="backdrop-filter: blur(20px); z-index: 1000;">
      <v-container class="d-flex align-center pa-0 max-w-1600 mx-auto">
        <div class="d-flex align-center mr-6 cursor-pointer" @click="isLeadCaptured ? window.scrollTo({ top: 0, behavior: 'smooth' }) : null">
          <img v-if="isHeaderDark && themeConfig.logoDarkUrl" :src="themeConfig.logoDarkUrl" alt="Logo" height="28" class="mr-3" />
          <img v-else-if="!isHeaderDark && themeConfig.logoLightUrl" :src="themeConfig.logoLightUrl" alt="Logo" height="28" class="mr-3" />
          <img v-else src="@/assets/logo.png" alt="Logo" height="28" class="mr-3" :style="isHeaderDark ? 'filter: brightness(0) invert(1);' : ''" />

          <v-app-bar-title class="font-weight-black text-body-1 tracking-tighter hidden-xs" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
            Studio <span class="text-primary font-weight-light">MJ</span>
          </v-app-bar-title>
        </div>
        <v-spacer></v-spacer>
        <div class="d-flex align-center gap-2">
          <template v-if="isLeadCaptured">
            <v-btn icon variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'" class="relative moodboard-btn" density="comfortable" @click="isCartOpen = !isCartOpen">
              <v-badge :content="cart.length" :model-value="cart.length > 0" color="error" floating><v-icon size="24">mdi-hanger</v-icon></v-badge>
            </v-btn>
          </template>
          <v-btn variant="flat" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'" :class="themeStore.currentMode === 'light' ? 'text-white' : 'text-black'" size="small" class="font-weight-bold rounded-pill px-5 text-none action-btn" @click="$router.push('/')">
            {{ isLeadCaptured && !isMobile ? 'Área Restrita' : 'Login' }}
          </v-btn>
        </div>
      </v-container>
    </v-app-bar>

    <v-overlay v-model="isUnlocking" class="align-center justify-center" z-index="9999" :scrim="themeStore.currentMode === 'light' ? '#ffffff' : '#121212'" opacity="1">
      <div class="d-flex flex-column align-center justify-center text-center fade-in">
        <img v-if="themeStore.currentMode === 'dark' && themeConfig.logoDarkUrl" :src="themeConfig.logoDarkUrl" height="60" class="mb-8 pulse-logo" />
        <img v-else-if="themeStore.currentMode === 'light' && themeConfig.logoLightUrl" :src="themeConfig.logoLightUrl" height="60" class="mb-8 pulse-logo" />
        <img v-else src="@/assets/logo.png" height="60" class="mb-8 pulse-logo" :style="themeStore.currentMode === 'dark' ? 'filter: brightness(0) invert(1);' : ''" />
        <h2 class="text-h5 font-weight-black mb-2 tracking-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Preparando o seu estúdio...</h2>
        <p class="text-body-2 mb-8 opacity-70" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-2' : 'text-grey-lighten-2'">Carregando estampas e texturas 3D</p>
        <v-progress-linear indeterminate color="primary" height="6" rounded class="w-100" style="max-width: 250px;"></v-progress-linear>
      </div>
    </v-overlay>

    <v-navigation-drawer v-model="isCartOpen" location="right" temporary :width="isMobile ? '100%' : '420'" elevation="20" class="cart-drawer" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'" style="z-index: 2000;">
      <div class="d-flex flex-column h-100">
        <div class="pa-5 border-b d-flex align-center justify-space-between sticky-cart-header" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-4' : 'bg-grey-darken-4 border-white-10'">
          <h3 class="text-h6 font-weight-black d-flex align-center gap-2 tracking-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'"><v-icon color="primary" size="24">mdi-hanger</v-icon> Moodboard</h3>
          <v-btn icon="mdi-close" variant="text" color="grey" density="comfortable" @click="isCartOpen = false"></v-btn>
        </div>
        <div class="flex-grow-1 overflow-y-auto pa-4 custom-scroll cart-content">
          <div v-if="cart.length === 0" class="h-100 d-flex flex-column align-center justify-center text-center opacity-70 px-6">
            <v-icon size="80" color="grey-lighten-2" class="mb-5">mdi-layers-outline</v-icon>
            <p class="text-h6 font-weight-bold mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1'">Seu estúdio está vazio.</p>
          </div>
          <v-slide-y-transition group>
            <div v-for="item in cart" :key="item.id" class="cart-item d-flex align-center gap-4 mb-4 pa-3 border rounded-xl" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-3' : 'bg-grey-darken-3 border-white-10'">
              <div class="image-container relative rounded-lg overflow-hidden bg-grey-lighten-4" style="width: 70px; height: 70px;">
                <v-img :src="item.image_url" cover w-100 h-100></v-img>
              </div>
              <div class="flex-grow-1 overflow-hidden">
                <div class="text-subtitle-2 font-weight-black text-truncate mb-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ item.title }}</div>
                <div class="d-flex align-center gap-2">
                  <v-chip size="x-small" color="primary" variant="flat" class="font-weight-bold px-2">{{ getCategoryName(item.category_id) }}</v-chip>
                  <div class="text-caption text-grey font-mono">{{ item.ref_code }}</div>
                </div>
              </div>
              <v-btn icon="mdi-delete-outline" variant="text" color="error" size="small" density="comfortable" @click="removeFromCart(item.id)"></v-btn>
            </div>
          </v-slide-y-transition>
        </div>
        <div class="pa-5 border-t sticky-cart-footer" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-4' : 'bg-black border-white-10'">
          <v-btn block :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'" :class="themeStore.currentMode === 'light' ? 'text-white' : 'text-black'" size="x-large" class="font-weight-black text-none rounded-xl btn-3d" height="60" :disabled="cart.length === 0" @click="requestQuote">Solicitar Orçamento <v-icon end size="20">mdi-whatsapp</v-icon></v-btn>
        </div>
      </div>
    </v-navigation-drawer>

    <v-dialog v-model="studio.isOpen" fullscreen transition="dialog-bottom-transition" scrim="black">
      <div class="fill-height d-flex flex-column" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-black'">

        <div class="px-4 py-3 d-flex align-center justify-space-between border-b flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-3' : 'bg-grey-darken-4 border-white-10'">
          <v-btn variant="text" prepend-icon="mdi-arrow-left" class="font-weight-bold text-none" @click="closeStudio" :color="themeStore.currentMode === 'light' ? 'grey-darken-4' : 'white'">Voltar</v-btn>
          <div class="text-center">
            <h3 class="text-subtitle-1 font-weight-black leading-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ studio.print?.title }}</h3>
            <p class="text-caption text-grey font-mono mb-0">REF: {{ studio.print?.ref_code }}</p>
          </div>
          <v-btn icon variant="text" color="primary" @click="toggleCart(studio.print)">
            <v-icon>{{ isInCart(studio.print?.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
          </v-btn>
        </div>

        <div class="flex-grow-1 d-flex flex-column flex-md-row overflow-hidden">

          <div class="flex-grow-1 d-flex align-center justify-center relative overflow-hidden viewer-area" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-3' : 'bg-grey-darken-4'" ref="viewerContainer">
             <div class="absolute-fill d-flex align-center justify-center opacity-05 pointer-events-none rotate-minus-15 z-50" style="font-size: 8vw; font-weight: 900; white-space: nowrap;">MJ STUDIO</div>

             <div class="mockup-composition relative shadow-2xl bg-white" :style="mockupContainerStyle">

                <div class="print-layer absolute-fill d-flex align-center justify-center overflow-hidden"
                     @mousedown.prevent="startDrag" @touchstart.prevent="startDrag"
                     @mousemove="onDrag" @touchmove="onDrag"
                     @mouseup="stopDrag" @touchend="stopDrag" @mouseleave="stopDrag">
                   <img :src="studio.print?.image_url" class="print-image" :style="printTransformStyle" draggable="false" />
                </div>

                <img v-if="studio.activeMockup" :src="studio.activeMockup.image_url" class="mockup-layer absolute-fill pointer-events-none" draggable="false" />
             </div>
          </div>

          <div class="studio-controls d-flex flex-column border-l flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-3' : 'bg-grey-darken-3 border-white-10'" :style="{ width: isMobile ? '100%' : '350px', height: isMobile ? '40vh' : '100%' }">

             <div class="pa-4 border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-3' : 'border-white-10'">
               <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-2 text-grey">Selecione o Modelo (Mockup)</h4>
               <div class="d-flex gap-3 overflow-x-auto custom-scroll pb-2">
                  <div v-for="mock in mockups" :key="mock.id" class="mockup-thumb cursor-pointer rounded-lg border overflow-hidden flex-shrink-0" :class="studio.activeMockup?.id === mock.id ? 'border-primary shadow-sm' : 'border-grey-lighten-3 opacity-70'" style="width: 60px; height: 60px;" @click="setMockup(mock)">
                    <v-img :src="mock.image_url" cover class="fill-height bg-grey-lighten-4"></v-img>
                  </div>
                  <div v-if="mockups.length === 0" class="text-caption text-grey">Nenhum mockup disponível.</div>
               </div>
             </div>

             <div class="pa-5 flex-grow-1 overflow-y-auto">
                <h4 class="text-subtitle-2 font-weight-black text-uppercase mb-4 text-grey">Ajustes da Estampa</h4>

                <div class="bg-blue-lighten-5 border border-blue-lighten-3 rounded-lg pa-3 mb-6 d-flex align-center">
                  <v-icon color="primary" class="mr-3">mdi-gesture-swipe-horizontal</v-icon>
                  <span class="text-caption text-blue-darken-4 font-weight-medium">Toque e arraste a imagem no modelo ao lado para reposicionar.</span>
                </div>

                <div class="mb-5">
                  <div class="d-flex justify-space-between mb-1"><span class="text-caption font-weight-bold">Escala (Zoom)</span><span class="text-caption text-primary font-weight-bold">{{ Math.round(studio.scale * 100) }}%</span></div>
                  <v-slider v-model="studio.scale" min="0.2" max="3" step="0.1" color="primary" hide-details density="compact" thumb-label></v-slider>
                </div>

                <div class="mb-5">
                  <div class="d-flex justify-space-between mb-1"><span class="text-caption font-weight-bold">Rotação</span><span class="text-caption text-primary font-weight-bold">{{ studio.rotation }}°</span></div>
                  <v-slider v-model="studio.rotation" min="-180" max="180" step="1" color="primary" hide-details density="compact" thumb-label></v-slider>
                </div>

                <div class="d-flex gap-2">
                   <v-btn block variant="tonal" color="grey" class="text-none font-weight-bold flex-grow-1" @click="resetStudio">Resetar Ajustes</v-btn>
                </div>
             </div>

             <div class="pa-4 border-t mt-auto" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-3' : 'bg-grey-darken-4 border-white-10'">
                <button class="btn-3d w-100 py-3 rounded-xl font-weight-black text-body-2" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }" @click="toggleCart(studio.print)">
                  <v-icon start size="18">{{ isInCart(studio.print?.id) ? 'mdi-check' : 'mdi-cart-plus' }}</v-icon>
                  {{ isInCart(studio.print?.id) ? 'Adicionado ao Moodboard' : 'Adicionar Estampa' }}
                </button>
             </div>
          </div>

        </div>
      </div>
    </v-dialog>

    <v-main :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'" :style="dynamicThemeStyles">

      <div v-if="!isLeadCaptured" class="fill-height relative overflow-hidden login-gate fade-in">
        <div class="absolute-fill z-0 background-carousel" :style="{ backgroundColor: themeConfig.backgroundColor, backgroundImage: themeConfig.bgTextureUrl ? `url(${themeConfig.bgTextureUrl})` : 'none', backgroundSize: 'cover', backgroundPosition: 'center' }">
          <v-carousel v-if="!themeConfig.bgTextureUrl" cycle height="100%" hide-delimiters :show-arrows="false" interval="5000" class="carousel-fade">
            <v-carousel-item v-for="(print, i) in loginBackgroundPrints" :key="i">
              <v-img :src="print.image_url" cover class="fill-height transform-scale-slow">
                <div class="absolute-fill bg-black-overlay opacity-80"></div>
                <div class="absolute-fill d-flex align-center justify-center opacity-05 pointer-events-none rotate-minus-15" style="font-size: 15vw; font-weight: 900; color: white; white-space: nowrap; letter-spacing: -1vw;">PROPRIEDADE MJ STUDIO</div>
              </v-img>
            </v-carousel-item>
          </v-carousel>
        </div>

        <v-container class="fill-height d-flex align-center justify-center relative z-10 pa-6">
          <v-fade-transition appear>
            <v-card class="access-card rounded-2xl overflow-hidden elevation-24 border opacity-95 w-100" :class="themeStore.currentMode === 'light' ? 'border-white bg-white-translucent' : 'border-white-20 bg-dark-translucent'" max-width="480" style="backdrop-filter: blur(12px);">
              <div class="pa-8 pa-md-10">
                <div class="text-center mb-8">
                   <img v-if="themeConfig.logoLightUrl && themeStore.currentMode === 'light'" :src="themeConfig.logoLightUrl" height="36" class="mb-4" />
                   <img v-else-if="themeConfig.logoDarkUrl && themeStore.currentMode === 'dark'" :src="themeConfig.logoDarkUrl" height="36" class="mb-4" />
                   <img v-else src="@/assets/logo.png" height="36" class="mb-4" :style="themeStore.currentMode === 'dark' ? 'filter: brightness(0) invert(1);' : ''" />

                   <h1 class="text-h4 font-weight-black mb-2 tracking-tighter leading-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">{{ themeConfig.loginTitle }}</h1>
                   <p class="text-body-1" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-1' : 'text-grey-lighten-1'">{{ themeConfig.loginSubtitle }}</p>
                </div>
                <v-form ref="leadForm" @submit.prevent="submitLead" v-model="isFormValid">
                  <v-text-field v-model="form.name" label="Seu Nome ou Empresa" variant="outlined" color="primary" class="mb-3 custom-field" rounded="lg" :rules="[v => !!v || 'Obrigatório']" hide-details="auto"></v-text-field>
                  <v-row dense class="mb-3">
                    <v-col cols="12" sm="6"><v-text-field v-model="form.document" label="CPF ou CNPJ" variant="outlined" color="primary" class="custom-field" rounded="lg" :rules="[v => !!v || 'Obrigatório']" hide-details="auto" v-mask="['###.###.###-##', '##.###.###/####-##']"></v-text-field></v-col>
                    <v-col cols="12" sm="6"><v-text-field v-model="form.phone" label="WhatsApp" variant="outlined" color="primary" class="custom-field" rounded="lg" :rules="[v => !!v || 'Obrigatório']" hide-details="auto" v-mask="['(##) ####-####', '(##) #####-####']"></v-text-field></v-col>
                  </v-row>
                  <v-text-field v-model="form.location" label="Cidade e Estado" variant="outlined" color="primary" class="mb-6 custom-field" rounded="lg" :rules="[v => !!v || 'Obrigatório']" hide-details="auto"></v-text-field>
                  <button type="submit" class="btn-3d w-100 py-4 rounded-xl font-weight-black text-body-1" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }">
                    Acessar Catálogo <v-icon end size="18">mdi-arrow-right</v-icon>
                  </button>
                </v-form>
              </div>
            </v-card>
          </v-fade-transition>
        </v-container>
      </div>

      <div v-else class="pb-16 fade-in main-catalog-content relative">

        <div v-if="themeConfig.popupEnabled" class="px-4 py-2 text-center text-[12px] font-weight-bold w-100" :style="{ backgroundColor: themeConfig.popupBgColor, color: themeConfig.popupTextColor, zIndex: 90 }">
           {{ themeConfig.popupText }}
        </div>

        <section id="colecoes" class="hero-section border-b" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-4' : 'border-white-10'">
          <v-carousel v-if="banners.length > 0" cycle :height="isMobile ? 400 : 650" hide-delimiter-background show-arrows="hover" class="hero-carousel" interval="8000">
            <v-carousel-item v-for="banner in banners" :key="banner.id">
              <v-img :src="banner.image_url" cover class="fill-height relative">
                <div class="absolute-fill d-flex align-center justify-center opacity-02 pointer-events-none rotate-minus-15" style="font-size: 8vw; font-weight: 900; color: black; white-space: nowrap;">MJ STUDIO • CÓPIA PROIBIDA</div>
                <div class="fill-height d-flex align-end bg-gradient-hero-mobile pa-6 pa-md-16">
                  <div class="max-w-1600 mx-auto w-100 slide-up-content">
                    <v-row>
                      <v-col cols="12" sm="10" md="7" lg="6">
                        <v-chip :style="{ backgroundColor: themeConfig.primaryColor, color: '#fff' }" variant="flat" size="small" class="font-weight-black text-uppercase tracking-widest mb-3 mb-md-4 px-4 py-3 chip-3d border-0">{{ banner.tag }}</v-chip>
                        <h2 class="text-h4 text-md-h2 font-weight-black text-white mb-2 mb-md-4 leading-tight text-shadow-lg tracking-tighter">{{ banner.title }}</h2>
                        <p class="text-body-2 text-md-h6 font-weight-medium text-grey-lighten-3 mb-6 mb-md-10 text-shadow-sm opacity-90 line-clamp-3">{{ banner.subtitle }}</p>
                        <button class="btn-3d px-8 py-3 rounded-pill font-weight-black text-body-1" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }" @click="scrollTo('vitrine')">{{ banner.cta_text || 'Explorar' }}</button>
                      </v-col>
                    </v-row>
                  </div>
                </div>
              </v-img>
            </v-carousel-item>
          </v-carousel>
        </section>

        <section id="vitrine" class="sticky-filter-bar border-b" :class="themeStore.currentMode === 'light' ? 'bg-white-translucent border-grey-lighten-4' : 'bg-dark-translucent border-white-10'">
          <v-container class="max-w-1600 px-4 px-md-10 py-3 py-md-4">
            <v-row dense align="center">
              <v-col cols="12" md="4" class="mb-2 mb-md-0">
                <h3 class="text-h5 font-weight-black tracking-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">Nosso Catálogo</h3>
                <span class="text-caption font-weight-medium text-grey opacity-80">{{ filteredPrints.length }} estampas disponíveis</span>
              </v-col>
              <v-col cols="12" md="8">
                <div class="d-flex align-center gap-2 justify-md-end overflow-x-auto pb-1 custom-scroll-horizontal">
                  <button :style="{ backgroundColor: !selectedCategory ? themeConfig.primaryColor : (themeStore.currentMode === 'light' ? '#f5f5f5' : '#333'), color: !selectedCategory ? '#fff' : (themeStore.currentMode === 'light' ? '#424242' : '#fff') }" class="chip-3d px-5 py-2 font-weight-bold text-caption rounded-pill border-0 no-wrap" @click="selectedCategory = null">Todas</button>
                  <button v-for="cat in categories" :key="cat.id" :style="{ backgroundColor: selectedCategory === cat.id ? themeConfig.primaryColor : (themeStore.currentMode === 'light' ? '#f5f5f5' : '#333'), color: selectedCategory === cat.id ? '#fff' : (themeStore.currentMode === 'light' ? '#424242' : '#fff') }" class="chip-3d px-5 py-2 font-weight-bold text-caption rounded-pill border-0 no-wrap" @click="selectedCategory = cat.id">{{ cat.name }}</button>
                </div>
              </v-col>
            </v-row>
          </v-container>
        </section>

        <section class="py-6 py-md-12">
          <v-container class="max-w-1600 px-3 px-md-10">
            <v-fade-transition hide-on-leave>
              <v-row v-if="loadingData" justify="center" class="py-12"><v-progress-circular indeterminate color="primary" size="48"></v-progress-circular></v-row>
              <v-row v-else-if="filteredPrints.length > 0">
                <v-col cols="6" sm="6" md="4" lg="3" xl="2" v-for="print in filteredPrints" :key="print.id" class="pa-2 pa-md-3">
                  <v-card class="product-card rounded-2xl elevation-0 border overflow-hidden h-100 d-flex flex-column group relative" :class="themeStore.currentMode === 'light' ? 'bg-white border-grey-lighten-4' : 'bg-grey-darken-3 border-white-10'">

                    <div class="image-wrapper relative overflow-hidden prevent-select bg-grey-lighten-4" style="aspect-ratio: 1/1;">
                      <v-img :src="print.image_url" cover w-100 h-100 class="transition-transform duration-700 group-hover-scale-lg"></v-img>
                      <div class="absolute-fill transparent-blocker prevent-context" @contextmenu.prevent="showPiracyWarning"></div>

                      <div class="absolute top-0 left-0 w-100 pa-2 pa-md-3 d-flex justify-space-between align-start pointer-events-none" style="z-index: 5;">
                        <v-chip v-if="print.is_new" color="rgba(255,255,255,0.9)" size="x-small" class="font-weight-black text-grey-darken-4 shadow-sm border border-grey-lighten-3 px-2 py-2 text-uppercase tracking-wider pointer-events-auto">Novo</v-chip>
                        <v-spacer v-else></v-spacer>
                        <button class="btn-3d bg-white rounded-circle d-flex align-center justify-center shadow-sm pointer-events-auto" style="width: 32px; height: 32px;" @click.stop="toggleCart(print)">
                          <v-icon :color="isInCart(print.id) ? 'error' : 'grey-darken-2'" size="16">{{ isInCart(print.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
                        </button>
                      </div>

                      <div :class="['absolute bottom-0 left-0 w-100 pa-3 pa-md-4 overlay-actions d-flex gap-2 transition-all duration-300', isMobile ? 'opacity-90' : 'opacity-0 transform-translate-y group-hover-opacity-100 group-hover-translate-y-0']" style="z-index: 5;">
                        <button class="btn-3d w-100 py-2 rounded-pill font-weight-black text-caption" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }" @click="openStudio(print)">
                          <v-icon start size="14">mdi-tshirt-crew-outline</v-icon> Testar no Mockup
                        </button>
                      </div>
                    </div>

                    <div class="pa-3 pa-md-4 d-flex flex-column flex-grow-1 border-t" :class="themeStore.currentMode === 'light' ? 'border-grey-lighten-4' : 'border-white-10'">
                      <div class="text-[10px] font-weight-bold text-uppercase mb-1 tracking-wider" :style="{ color: themeConfig.primaryColor }">{{ getCategoryName(print.category_id) }}</div>
                      <h4 class="text-body-2 font-weight-black mb-1 leading-snug text-truncate-2 flex-grow-1">{{ print.title }}</h4>
                      <div class="d-flex align-center justify-space-between pt-2 mt-auto">
                        <span class="text-[10px] font-weight-bold text-grey font-mono px-2 py-1 rounded" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-4' : 'bg-grey-darken-4'">REF: {{ print.ref_code }}</span>
                      </div>
                    </div>
                  </v-card>
                </v-col>
              </v-row>
            </v-fade-transition>

            <v-fade-transition hide-on-leave>
              <div v-if="!loadingData && filteredPrints.length === 0" class="py-16 text-center rounded-2xl border my-6 mx-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 border-grey-lighten-4' : 'bg-grey-darken-3 border-white-10'">
                 <v-icon size="72" color="grey-lighten-2" class="mb-5">mdi-magnify-remove-outline</v-icon>
                 <h3 class="text-h5 font-weight-black tracking-tight" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-3' : 'text-white'">Nenhuma estampa encontrada</h3>
                 <button class="btn-3d px-6 py-2 mt-4 rounded-pill font-weight-bold text-caption" :style="{ backgroundColor: themeConfig.primaryColor, color: '#fff' }" @click="selectedCategory = null">Ver Todas</button>
              </div>
            </v-fade-transition>
          </v-container>
        </section>

        <div v-if="themeConfig.maintenanceMode" class="absolute-fill d-flex flex-column align-center justify-center p-6 text-center" style="background: rgba(0,0,0,0.85); backdrop-filter: blur(10px); z-index: 9999; position: fixed;">
           <v-icon size="64" color="error" class="mb-4">mdi-lock</v-icon>
           <h2 class="text-h4 font-weight-black text-white mb-2 tracking-tighter">Site Privado</h2>
           <p class="text-body-1 text-grey-lighten-1">O modo manutenção está ativado. Volte mais tarde.</p>
        </div>

      </div>
    </v-main>
  </v-app>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onBeforeUnmount } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/themeStore';
import { useDisplay } from 'vuetify';

const appStore = useAppStore();
const themeStore = useThemeStore();
const { mobile: isMobile } = useDisplay();

// ==========================================
// ESTADOS PRINCIPAIS
// ==========================================
const isLeadCaptured = ref(false);
const isFormValid = ref(false);
const loading = ref(false);
const loadingData = ref(true);
const isUnlocking = ref(false);
const form = reactive({ name: '', document: '', phone: '', location: '' });

const categories = ref<any[]>([]);
const banners = ref<any[]>([]);
const prints = ref<any[]>([]);
const mockups = ref<any[]>([]); // NOVA TABELA DO BANCO!

const selectedCategory = ref(null);

const loginBackgroundPrints = computed(() => {
  if (prints.value.length > 0) return prints.value.slice(0, 4);
  return [
    { image_url: 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?q=80&w=1920' },
    { image_url: 'https://images.unsplash.com/photo-1580255971485-618776632422?q=80&w=1920' }
  ];
});

// ==========================================
// TEMA DINÂMICO
// ==========================================
const themeConfig = reactive({
  logoLightUrl: '', logoDarkUrl: '', primaryColor: '#000000', backgroundColor: '#ffffff', textColor: '#333333', headerColor: '#ffffff', buttonColor: '#000000', buttonTextColor: '#ffffff', fontSize: '14px', bgTextureUrl: '', maintenanceMode: false, popupEnabled: true, popupText: 'Catálogo de Estampas MJ', popupBgColor: '#000000', popupTextColor: '#ffffff', loginTitle: 'Estúdio Interativo', loginSubtitle: 'Preencha seus dados para acessar.',
});

const dynamicThemeStyles = computed(() => ({
  fontSize: themeConfig.fontSize, backgroundColor: themeConfig.backgroundColor, backgroundImage: themeConfig.bgTextureUrl ? `url(${themeConfig.bgTextureUrl})` : 'none', backgroundSize: 'cover', backgroundPosition: 'center', backgroundAttachment: 'fixed', color: themeConfig.textColor, fontFamily: "'Inter', sans-serif"
}));

const isHeaderDark = computed(() => {
  if (!themeConfig.headerColor) return false;
  const hex = themeConfig.headerColor.replace('#', '');
  const r = parseInt(hex.substr(0, 2), 16); const g = parseInt(hex.substr(2, 2), 16); const b = parseInt(hex.substr(4, 2), 16);
  return (((r * 299) + (g * 587) + (b * 114)) / 1000) < 128;
});

// ==========================================
// MOCKUP STUDIO (A MÁGICA 3D/CSS ACONTECE AQUI)
// ==========================================
const studio = reactive({
  isOpen: false,
  print: null as any,
  activeMockup: null as any,
  scale: 1,
  rotation: 0,
  panX: 0,
  panY: 0,
  isDragging: false,
  startX: 0,
  startY: 0
});

const viewerContainer = ref<HTMLElement | null>(null);

const mockupContainerStyle = computed(() => {
  // Define o tamanho base da área útil do mockup (ex: 500x500 no desktop)
  const size = isMobile.value ? '320px' : '500px';
  return { width: size, height: size };
});

const printTransformStyle = computed(() => {
  return {
    transform: `translate(${studio.panX}px, ${studio.panY}px) rotate(${studio.rotation}deg) scale(${studio.scale})`,
    width: '100%', // A estampa tenta preencher a área inicialmente
    height: '100%',
    objectFit: 'cover',
    transition: studio.isDragging ? 'none' : 'transform 0.1s ease-out'
  };
});

const openStudio = (print: any) => {
  studio.print = print;
  studio.isOpen = true;
  resetStudio();
  if (mockups.value.length > 0) {
    studio.activeMockup = mockups.value[0]; // Seleciona o primeiro mockup automaticamente
  }
};

const closeStudio = () => { studio.isOpen = false; };
const setMockup = (mock: any) => { studio.activeMockup = mock; };
const resetStudio = () => { studio.scale = 1; studio.rotation = 0; studio.panX = 0; studio.panY = 0; };

// Lógica de Arrasto (Drag) direta na estampa
const startDrag = (e: MouseEvent | TouchEvent) => {
  studio.isDragging = true;
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
  const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
  studio.startX = clientX - studio.panX;
  studio.startY = clientY - studio.panY;
};

const onDrag = (e: MouseEvent | TouchEvent) => {
  if (!studio.isDragging) return;
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
  const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
  studio.panX = clientX - studio.startX;
  studio.panY = clientY - studio.startY;
};

const stopDrag = () => { studio.isDragging = false; };

// ==========================================
// BUSCA REAL NO SUPABASE
// ==========================================
const fetchData = async () => {
  loadingData.value = true;
  try {
    // Busca configs visuais
    const { data: set } = await supabase.from('catalog_settings').select('theme_config').eq('id', 1).single();
    if (set?.theme_config) Object.assign(themeConfig, set.theme_config);

    // Busca dados ativos das tabelas que criamos
    const [catRes, banRes, prtRes, mockRes] = await Promise.all([
      supabase.from('catalog_categories').select('*').order('name'),
      supabase.from('catalog_banners').select('*').eq('active', true).order('created_at', { ascending: false }),
      supabase.from('catalog_prints').select('*').eq('active', true).order('created_at', { ascending: false }),
      supabase.from('catalog_mockups').select('*').eq('active', true).order('name') // NOVA BUSCA!
    ]);

    categories.value = catRes.data || [];
    banners.value = banRes.data || [];
    prints.value = prtRes.data || [];
    mockups.value = mockRes.data || [];

  } catch (error) {
    console.error("Erro ao carregar dados", error);
  } finally {
    loadingData.value = false;
  }
};

const filteredPrints = computed(() => {
  if (!selectedCategory.value) return prints.value;
  return prints.value.filter(p => p.category_id === selectedCategory.value);
});

const getCategoryName = (id: number) => categories.value.find(c => c.id === id)?.name || '';

// ==========================================
// CARRINHO (MOODBOARD) E SEGURANÇA
// ==========================================
const isCartOpen = ref(false);
const cart = ref<any[]>([]);

const isInCart = (id: number) => cart.value.some(item => item.id === id);

const toggleCart = (print: any) => {
  if (isInCart(print.id)) { cart.value = cart.value.filter(item => item.id !== print.id); }
  else { cart.value.push(print); appStore.showSnackbar('Adicionado ao Moodboard!', 'success'); }
};

const removeFromCart = (id: number) => { cart.value = cart.value.filter(item => item.id !== id); };

const requestQuote = () => {
  const leadData = localStorage.getItem('mj_lead_session');
  const leadName = leadData ? JSON.parse(leadData).name : 'Cliente';
  let msg = `Olá MJ Studio, solicitar orçamento (Moodboard de ${leadName}):\n\n`;
  cart.value.forEach((i, idx) => { msg += `${idx + 1}. REF: ${i.ref_code} - ${i.title}\n`; });
  window.open(`https://api.whatsapp.com/send?phone=5511999999999&text=${encodeURIComponent(msg)}`, '_blank');
};

const submitLead = async () => {
  if (!isFormValid.value) return appStore.showSnackbar('Preencha os campos obrigatórios.', 'warning');
  loading.value = true;
  try {
    const { error } = await supabase.from('public_leads').insert([{ ...form }]);
    if (error) throw error;
    localStorage.setItem('mj_lead_session', JSON.stringify({ name: form.name, timestamp: new Date().toISOString() }));
    isUnlocking.value = true;
    setTimeout(() => { isLeadCaptured.value = true; isUnlocking.value = false; window.scrollTo({ top: 0 }); }, 2000);
  } catch (error) { appStore.showSnackbar('Erro ao liberar acesso.', 'error'); }
  finally { loading.value = false; }
};

const showPiracyWarning = () => { appStore.showSnackbar('Conteúdo protegido.', 'warning', { timeout: 3000, icon: 'mdi-security' }); };
const blockRightClick = (e: MouseEvent) => { e.preventDefault(); showPiracyWarning(); };
const blockKeyCommands = (e: KeyboardEvent) => { if ((e.ctrlKey && ['c', 's', 'u', 'i', 'I', 'p'].includes(e.key)) || e.key === 'F12') { e.preventDefault(); showPiracyWarning(); } };

onMounted(() => {
  const session = localStorage.getItem('mj_lead_session');
  if (session) { try { if (JSON.parse(session).name) isLeadCaptured.value = true; } catch (e) {} }
  document.addEventListener('contextmenu', blockRightClick); document.addEventListener('keydown', blockKeyCommands);
  fetchData(); // BUSCA DADOS REAIS!
});

onBeforeUnmount(() => { document.removeEventListener('contextmenu', blockRightClick); document.removeEventListener('keydown', blockKeyCommands); });
const scrollTo = (id: string) => { const el = document.getElementById(id); if (el) window.scrollTo({ top: el.getBoundingClientRect().top + window.scrollY - 60, behavior: 'smooth' }); };
</script>

<style scoped>
/* GLOBAIS E SEGURANÇA */
.absolute-fill { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
.prevent-select { -webkit-user-select: none; user-select: none; }
.prevent-context { pointer-events: auto; z-index: 3; }
.transparent-blocker { background-color: transparent; }
.tracking-tight { letter-spacing: -0.015em; }
.tracking-tighter { letter-spacing: -0.035em; }
.tracking-widest { letter-spacing: 0.12em; }
.text-truncate-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.font-mono { font-family: 'Roboto Mono', monospace; font-size: 0.9em; }

/* BOTOES E CHIPS 3D */
.btn-3d { border-radius: 8px; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2); transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; border: none; cursor: pointer; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.1); }
.chip-3d { border-radius: 20px; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.5); }

/* ESTÚDIO DE MOCKUPS (A MÁGICA 3D) */
.viewer-area { background-image: radial-gradient(rgba(0,0,0,0.06) 1px, transparent 1px); background-size: 20px 20px; }
.theme-dark .viewer-area { background-image: radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px); }
.mockup-composition { border-radius: 12px; overflow: hidden; }
.print-layer { cursor: grab; z-index: 1; }
.print-layer:active { cursor: grabbing; }
.mockup-layer { z-index: 2; object-fit: contain; } /* O Mockup fica SEMPRE por cima da estampa com transparência */

/* SCROLLBARS */
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 10px; }
.custom-scroll-horizontal::-webkit-scrollbar { height: 3px; }
.custom-scroll-horizontal::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }

/* TELA DE ACESSO (Login) */
.bg-black-overlay { background: radial-gradient(circle, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.8) 100%); }
.bg-white-translucent { background: rgba(255, 255, 255, 0.7); }
.bg-dark-translucent { background: rgba(18, 18, 18, 0.7); }
.custom-field :deep(.v-field__outline) { --v-field-border-opacity: 0.2; }

/* Animações e Effects */
@keyframes pulseLogo { 0% { transform: scale(1); opacity: 0.8; } 50% { transform: scale(1.15); opacity: 1; filter: drop-shadow(0 0 10px rgba(0,0,0,0.2)); } 100% { transform: scale(1); opacity: 0.8; } }
.pulse-logo { animation: pulseLogo 2s infinite ease-in-out; }
.fade-in { animation: fadeIn 0.6s ease forwards; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.slide-up-content { animation: slideUpFade 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
@keyframes slideUpFade { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }

/* VITRINE E CARDS */
.bg-gradient-hero-mobile { background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.2) 60%, transparent 100%); }
.sticky-header { position: sticky; top: 0; backdrop-filter: blur(15px); }
.sticky-filter-bar { position: sticky; top: 60px; z-index: 40; backdrop-filter: blur(15px); }
.product-card { transition: transform 0.3s, box-shadow 0.3s; }
.product-card:hover { transform: translateY(-4px); box-shadow: 0 15px 30px -10px rgba(0,0,0,0.1) !important; }
.group-hover-scale { transition: transform 0.8s cubic-bezier(0.165, 0.84, 0.44, 1); }
.group:hover .group-hover-scale { transform: scale(1.08); }
.overlay-actions { background: linear-gradient(to top, rgba(0,0,0,0.5) 0%, transparent 100%); z-index: 4; }
.group-hover-opacity-100 { opacity: 1 !important; }
.group-hover-translate-y-0 { transform: translateY(0) !important; }

@media (max-width: 600px) {
  .v-app-bar { padding: 0 !important; }
  .sticky-filter-bar { top: 60px !important; padding: 0 !important; }
  .product-card { border-radius: 12px !important; }
  .overlay-actions { padding: 8px !important; opacity: 1 !important; transform: translateY(0) !important; background: none; }
  .overlay-actions button { height: 34px !important; font-size: 11px !important; border-radius: 8px !important; box-shadow: 0 2px 8px rgba(0,0,0,0.2) !important; }
  .product-card :deep(.v-img__img) { transform: scale(1) !important; }
}
</style>
