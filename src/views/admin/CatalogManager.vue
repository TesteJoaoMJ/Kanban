<template>
  <div class="theme-builder h-100 d-flex flex-column font-sans bg-grey-lighten-4">

    <header class="builder-topbar px-6 py-2 flex-shrink-0 d-flex align-center justify-space-between bg-white border-b shadow-sm" style="z-index: 200;">
      <div class="d-flex align-center gap-4">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" color="grey-darken-3" @click="$router.push('/admin')"></v-btn>
        <div>
          <div class="text-[10px] font-weight-black text-primary text-uppercase tracking-wider">Theme Editor</div>
          <h1 class="text-subtitle-1 font-weight-black text-grey-darken-4 leading-tight">Catálogo Público</h1>
        </div>
      </div>

      <div class="d-flex align-center gap-4">
        <div class="d-flex align-center bg-grey-lighten-4 rounded-lg p-1 border">
          <button class="preview-tab-btn" :class="{ 'active': previewScreen === 'login' }" @click="previewScreen = 'login'">Tela de Acesso</button>
          <button class="preview-tab-btn" :class="{ 'active': previewScreen === 'catalog' }" @click="previewScreen = 'catalog'">Vitrine Principal</button>
        </div>

        <v-divider vertical class="mx-2"></v-divider>

        <div class="d-flex align-center bg-grey-lighten-4 rounded-lg p-1 border">
          <button class="device-btn" :class="{ 'active': previewDevice === 'desktop' }" @click="previewDevice = 'desktop'"><v-icon size="18">mdi-monitor</v-icon></button>
          <button class="device-btn" :class="{ 'active': previewDevice === 'mobile' }" @click="previewDevice = 'mobile'"><v-icon size="18">mdi-cellphone</v-icon></button>
        </div>

        <v-btn variant="outlined" color="grey-darken-2" class="btn-3d px-4 text-caption font-weight-bold" height="36" @click="openLiveSite" prepend-icon="mdi-open-in-new">Site Real</v-btn>
        <v-btn color="success" class="btn-3d px-6 text-caption font-weight-black" height="36" prepend-icon="mdi-content-save" :loading="isSaving" @click="saveSettings">Publicar Alterações</v-btn>
      </div>
    </header>

    <div class="flex-grow-1 d-flex overflow-hidden relative">

      <aside class="builder-sidebar d-flex flex-column flex-shrink-0 bg-white border-r custom-scroll overflow-y-auto" style="z-index: 100;">

        <v-expansion-panels variant="accordion" multiple v-model="activePanels" class="flat-panels">

          <v-expansion-panel value="branding" class="border-b">
            <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider text-grey-darken-3">
              <v-icon start size="16" class="mr-3 opacity-70">mdi-shield-star</v-icon> Logos e Branding
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <div class="d-flex flex-column gap-4 pt-2">
                <div class="border rounded-lg pa-3 bg-grey-lighten-5">
                  <div class="text-caption font-weight-bold mb-2">Logo Principal (Fundos Claros)</div>
                  <v-img v-if="themeConfig.logoLightUrl" :src="themeConfig.logoLightUrl" height="40" class="mb-2 bg-white border rounded" contain></v-img>
                  <v-file-input v-model="uploadLogoLight" accept="image/png, image/svg+xml" variant="outlined" density="compact" prepend-icon="" prepend-inner-icon="mdi-upload" label="Upload Logo Light" hide-details class="builder-input" @update:modelValue="handleLogoLightPreview"></v-file-input>
                </div>

                <div class="border rounded-lg pa-3 bg-grey-darken-4">
                  <div class="text-caption font-weight-bold mb-2 text-white">Logo Invertida (Fundos Escuros)</div>
                  <v-img v-if="themeConfig.logoDarkUrl" :src="themeConfig.logoDarkUrl" height="40" class="mb-2 bg-grey-darken-3 border border-white-10 rounded" contain></v-img>
                  <v-file-input v-model="uploadLogoDark" accept="image/png, image/svg+xml" variant="outlined" density="compact" prepend-icon="" prepend-inner-icon="mdi-upload" label="Upload Logo Dark" hide-details class="builder-input dark-input" @update:modelValue="handleLogoDarkPreview"></v-file-input>
                </div>
              </div>
            </v-expansion-panel-text>
          </v-expansion-panel>

          <v-expansion-panel value="colors" class="border-b">
            <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider text-grey-darken-3">
              <v-icon start size="16" class="mr-3 opacity-70">mdi-palette</v-icon> Cores Globais
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <div class="d-flex flex-column gap-3 pt-2">
                <div class="pro-color-picker"><span class="text-caption font-weight-bold">Cor Primária</span><div class="color-control border"><input type="color" v-model="themeConfig.primaryColor" /><span class="font-mono text-[10px]">{{ themeConfig.primaryColor }}</span></div></div>
                <div class="pro-color-picker"><span class="text-caption">Fundo do Site</span><div class="color-control border"><input type="color" v-model="themeConfig.backgroundColor" /><span class="font-mono text-[10px]">{{ themeConfig.backgroundColor }}</span></div></div>
                <div class="pro-color-picker"><span class="text-caption">Cor dos Textos</span><div class="color-control border"><input type="color" v-model="themeConfig.textColor" /><span class="font-mono text-[10px]">{{ themeConfig.textColor }}</span></div></div>
                <div class="pro-color-picker"><span class="text-caption">Fundo do Cabeçalho</span><div class="color-control border"><input type="color" v-model="themeConfig.headerColor" /><span class="font-mono text-[10px]">{{ themeConfig.headerColor }}</span></div></div>
                <div class="pro-color-picker"><span class="text-caption">Fundo dos Botões</span><div class="color-control border"><input type="color" v-model="themeConfig.buttonColor" /><span class="font-mono text-[10px]">{{ themeConfig.buttonColor }}</span></div></div>
                <div class="pro-color-picker"><span class="text-caption">Texto dos Botões</span><div class="color-control border"><input type="color" v-model="themeConfig.buttonTextColor" /><span class="font-mono text-[10px]">{{ themeConfig.buttonTextColor }}</span></div></div>
              </div>
            </v-expansion-panel-text>
          </v-expansion-panel>

          <v-expansion-panel value="login" class="border-b">
            <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider text-grey-darken-3">
              <v-icon start size="16" class="mr-3 opacity-70">mdi-door-open</v-icon> Tela de Acesso
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <div class="d-flex flex-column gap-3 pt-2">
                <v-text-field v-model="themeConfig.loginTitle" label="Título Principal" variant="outlined" density="compact" hide-details class="builder-input"></v-text-field>
                <v-textarea v-model="themeConfig.loginSubtitle" label="Descrição" variant="outlined" density="compact" rows="2" hide-details class="builder-input"></v-textarea>
                <div class="text-caption font-weight-bold mt-2">Textura/Imagem de Fundo</div>
                <v-file-input v-model="uploadBgTexture" accept="image/*" variant="outlined" density="compact" prepend-icon="" prepend-inner-icon="mdi-wallpaper" label="Upload Fundo Login" hide-details class="builder-input" @update:modelValue="handleTexturePreview"></v-file-input>
                <v-btn v-if="themeConfig.bgTextureUrl" variant="text" color="error" size="small" @click="themeConfig.bgTextureUrl = ''; uploadBgTexture = null" class="align-self-start">Remover Fundo</v-btn>
              </div>
            </v-expansion-panel-text>
          </v-expansion-panel>

          <v-expansion-panel value="announcement" class="border-b">
            <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider text-grey-darken-3">
              <v-icon start size="16" class="mr-3 opacity-70">mdi-bullhorn</v-icon> Barra de Avisos
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <div class="d-flex flex-column gap-3 pt-2">
                <v-switch v-model="themeConfig.popupEnabled" color="success" density="compact" hide-details><template v-slot:label><span class="text-caption font-weight-bold">Exibir no Topo</span></template></v-switch>
                <v-text-field v-if="themeConfig.popupEnabled" v-model="themeConfig.popupText" label="Mensagem do Aviso" variant="outlined" density="compact" hide-details class="builder-input"></v-text-field>
                <div v-if="themeConfig.popupEnabled" class="pro-color-picker"><span class="text-caption">Fundo</span><div class="color-control border"><input type="color" v-model="themeConfig.popupBgColor" /><span class="font-mono text-[10px]">{{ themeConfig.popupBgColor }}</span></div></div>
                <div v-if="themeConfig.popupEnabled" class="pro-color-picker"><span class="text-caption">Texto</span><div class="color-control border"><input type="color" v-model="themeConfig.popupTextColor" /><span class="font-mono text-[10px]">{{ themeConfig.popupTextColor }}</span></div></div>
              </div>
            </v-expansion-panel-text>
          </v-expansion-panel>

          <v-expansion-panel value="maintenance" class="border-b">
            <v-expansion-panel-title class="font-weight-black text-caption text-uppercase tracking-wider text-grey-darken-3">
              <v-icon start size="16" class="mr-3 opacity-70 text-error">mdi-security</v-icon> Segurança
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <div class="bg-red-lighten-5 border border-red-lighten-3 pa-3 rounded-lg mt-2">
                <v-switch v-model="themeConfig.maintenanceMode" color="error" density="compact" hide-details><template v-slot:label><span class="text-caption font-weight-bold text-error">Modo Manutenção</span></template></v-switch>
                <p class="text-[10px] text-error mt-1 mb-0 leading-tight">Bloqueia o acesso público ao catálogo exibindo uma tela de manutenção.</p>
              </div>
            </v-expansion-panel-text>
          </v-expansion-panel>

        </v-expansion-panels>

        <div class="pa-4 bg-grey-lighten-5 flex-grow-1 border-t">
          <div class="text-caption font-weight-black text-uppercase tracking-wider mb-3 text-grey-darken-2">Base de Dados Real</div>
          <v-btn block variant="tonal" color="primary" class="font-weight-bold justify-start mb-2 btn-3d" prepend-icon="mdi-view-carousel" @click="openListModal('banners')">Banners Hero ({{ realData.banners.length }})</v-btn>
          <v-btn block variant="tonal" color="success" class="font-weight-bold justify-start mb-2 btn-3d" prepend-icon="mdi-palette-swatch" @click="openListModal('prints')">Estampas ({{ realData.prints.length }})</v-btn>
          <v-btn block variant="tonal" color="info" class="font-weight-bold justify-start mb-2 btn-3d" prepend-icon="mdi-shape-outline" @click="openListModal('categories')">Categorias ({{ realData.categories.length }})</v-btn>
          </div>
      </aside>

      <main class="preview-area flex-grow-1 d-flex align-center justify-center p-4 p-md-8 relative overflow-hidden bg-grey-lighten-3" style="z-index: 10;">

        <div class="device-frame transition-all duration-300 relative bg-white d-flex flex-column"
             :class="previewDevice === 'mobile' ? 'is-mobile-frame' : 'is-desktop-frame shadow-2xl'"
             :style="dynamicThemeStyles">

          <div class="site-mock-container flex-grow-1 overflow-y-auto custom-scroll relative no-select w-100 h-100" :class="{ 'pointer-events-none': themeConfig.maintenanceMode }">

            <div v-if="themeConfig.popupEnabled" class="px-4 py-2 text-center text-[12px] font-weight-bold" :style="{ backgroundColor: themeConfig.popupBgColor, color: themeConfig.popupTextColor }">
              {{ themeConfig.popupText }}
            </div>

            <header class="px-4 py-3 d-flex align-center justify-space-between border-b sticky-header z-50" :style="{ backgroundColor: themeConfig.headerColor, borderColor: 'rgba(0,0,0,0.05)' }">
              <div class="d-flex align-center gap-2 cursor-pointer">
                <img v-if="isHeaderDark && themeConfig.logoDarkUrl" :src="themeConfig.logoDarkUrl" alt="Logo" height="24" />
                <img v-else-if="!isHeaderDark && themeConfig.logoLightUrl" :src="themeConfig.logoLightUrl" alt="Logo" height="24" />
                <img v-else src="@/assets/logo.png" alt="Logo" height="24" :style="{ filter: isHeaderDark ? 'brightness(0) invert(1)' : 'none' }" />
                <span v-if="previewDevice === 'desktop'" class="font-weight-black tracking-tight text-body-1 ml-2" :style="{ color: isHeaderDark ? '#fff' : '#000' }">Studio <span :style="{ color: themeConfig.primaryColor }">MJ</span></span>
              </div>

              <div class="d-flex align-center gap-3">
                <v-btn v-if="previewScreen === 'catalog'" icon variant="text" :color="isHeaderDark ? 'white' : 'grey-darken-4'" density="comfortable" @click="internalState.cartOpen = !internalState.cartOpen">
                  <v-badge :content="internalState.cart.length" :model-value="internalState.cart.length > 0" color="error" floating><v-icon size="24">mdi-hanger</v-icon></v-badge>
                </v-btn>
                <button class="btn-3d px-5 py-2 rounded-pill text-caption font-weight-bold" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }">
                  {{ previewScreen === 'login' ? 'Acessar' : 'Sair' }}
                </button>
              </div>
            </header>

            <div v-if="previewScreen === 'login'" class="relative" style="min-height: calc(100vh - 100px);">
              <div class="absolute-fill z-0" :style="{ backgroundColor: themeConfig.backgroundColor, backgroundImage: themeConfig.bgTextureUrl ? `url(${themeConfig.bgTextureUrl})` : 'none', backgroundSize: 'cover', backgroundPosition: 'center' }">
                 <div class="absolute-fill bg-black-overlay opacity-80"></div>
              </div>

              <div class="d-flex align-center justify-center relative z-10 pa-4 pa-md-6" style="min-height: calc(100vh - 100px);">
                <v-card class="rounded-2xl overflow-hidden elevation-12 border border-white opacity-95 w-100" max-width="450" style="backdrop-filter: blur(10px); background: rgba(255,255,255,0.9);">
                  <div class="pa-8 text-center">
                    <img v-if="themeConfig.logoLightUrl" :src="themeConfig.logoLightUrl" height="36" class="mb-4" />
                    <img v-else src="@/assets/logo.png" height="36" class="mb-4" />

                    <h1 class="text-h4 font-weight-black text-grey-darken-4 mb-2 tracking-tighter">{{ themeConfig.loginTitle || 'Estúdio Interativo' }}</h1>
                    <p class="text-body-2 text-grey-darken-1 mb-6">{{ themeConfig.loginSubtitle || 'Preencha seus dados para liberar acesso.' }}</p>

                    <v-text-field label="Seu Nome" variant="outlined" density="comfortable" class="mb-2 rounded-lg custom-field" hide-details></v-text-field>
                    <v-text-field label="CPF ou CNPJ" variant="outlined" density="comfortable" class="mb-2 rounded-lg custom-field" hide-details></v-text-field>
                    <v-text-field label="WhatsApp" variant="outlined" density="comfortable" class="mb-6 rounded-lg custom-field" hide-details></v-text-field>

                    <button class="btn-3d w-100 py-3 rounded-xl font-weight-black text-body-1" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }" @click="previewScreen = 'catalog'">
                      Acessar Catálogo <v-icon end>mdi-arrow-right</v-icon>
                    </button>
                  </div>
                </v-card>
              </div>
            </div>

            <div v-if="previewScreen === 'catalog'" class="pb-16 relative">

              <div v-if="realData.banners.length > 0" class="relative overflow-hidden" :style="{ height: previewDevice === 'mobile' ? '350px' : '500px', backgroundColor: '#111' }">
                <v-img :src="realData.banners[0].image_url" cover class="fill-height opacity-80"></v-img>
                <div class="absolute-fill d-flex flex-column justify-end pa-6 pa-md-12" style="background: linear-gradient(to top, rgba(0,0,0,0.9) 0%, transparent 100%);">
                  <v-chip size="small" :style="{ backgroundColor: themeConfig.primaryColor, color: '#fff' }" class="mb-3 align-self-start font-weight-black chip-3d border-0 tracking-widest text-uppercase">{{ realData.banners[0].tag || 'DESTAQUE' }}</v-chip>
                  <h2 class="text-white font-weight-black leading-tight mb-2 tracking-tighter" :class="previewDevice === 'mobile' ? 'text-h4' : 'text-h2'">{{ realData.banners[0].title }}</h2>
                  <p class="text-grey-lighten-2 text-body-2 mb-6" style="max-width: 600px;">{{ realData.banners[0].subtitle }}</p>
                  <button class="btn-3d px-8 py-3 rounded-pill font-weight-black align-self-start text-body-2" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }">{{ realData.banners[0].cta_text || 'Explorar' }}</button>
                </div>
              </div>
              <div v-else class="bg-grey-darken-3 d-flex align-center justify-center flex-column text-center pa-10" :style="{ height: previewDevice === 'mobile' ? '350px' : '500px' }">
                 <v-icon size="48" color="grey">mdi-image-off-outline</v-icon>
                 <p class="text-grey font-weight-bold mt-4">Nenhum Banner Cadastrado</p>
              </div>

              <div class="pa-4 border-b d-flex gap-2 overflow-x-auto custom-scroll-horizontal sticky-filter-bar z-40" :style="{ backgroundColor: 'rgba(255,255,255,0.9)', backdropFilter: 'blur(10px)' }">
                 <button class="chip-3d px-5 py-2 font-weight-bold text-caption rounded-pill border-0" :style="{ backgroundColor: themeConfig.primaryColor, color: '#fff' }">Todas</button>
                 <button v-for="cat in realData.categories" :key="cat.id" class="chip-3d px-5 py-2 font-weight-bold text-caption rounded-pill bg-grey-lighten-4 text-grey-darken-3 border-0">{{ cat.name }}</button>
                 <button v-if="realData.categories.length === 0" class="chip-3d px-5 py-2 font-weight-bold text-caption rounded-pill bg-grey-lighten-4 text-grey border-0">Sem categorias</button>
              </div>

              <div class="pa-4 pa-md-8">
                <div v-if="realData.prints.length > 0" class="d-grid gap-4 gap-md-6" :style="{ gridTemplateColumns: previewDevice === 'mobile' ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)' }">
                  <div v-for="print in realData.prints" :key="print.id" class="product-card rounded-2xl overflow-hidden border bg-white d-flex flex-column group" style="border-color: rgba(0,0,0,0.08);">
                    <div class="relative bg-grey-lighten-5 overflow-hidden" style="aspect-ratio: 1/1;">
                      <v-img :src="print.image_url" cover class="fill-height transition-transform group-hover-scale"></v-img>
                      <button class="absolute top-2 right-2 btn-3d bg-white rounded-circle d-flex align-center justify-center shadow-sm" style="width: 32px; height: 32px;" @click="toggleCartMock(print)">
                        <v-icon size="16" :color="isInCartMock(print.id) ? 'error' : 'grey-darken-2'">{{ isInCartMock(print.id) ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
                      </button>
                      <div class="absolute bottom-0 left-0 w-100 pa-2 overlay-actions opacity-0 group-hover-opacity-100 transition-all">
                        <button class="btn-3d w-100 py-2 rounded-lg font-weight-bold text-caption" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }"><v-icon start size="14">mdi-tshirt-crew-outline</v-icon> Testar 3D</button>
                      </div>
                    </div>
                    <div class="pa-3 pa-md-4 d-flex flex-column flex-grow-1">
                      <div class="text-[10px] font-weight-bold text-uppercase mb-1 tracking-wider" :style="{ color: themeConfig.primaryColor }">{{ getCategoryName(print.category_id) }}</div>
                      <div class="text-body-2 font-weight-black leading-tight text-truncate-2 mb-2 flex-grow-1" :style="{ color: themeConfig.textColor }">{{ print.title }}</div>
                      <div class="text-caption font-mono text-grey bg-grey-lighten-4 px-2 py-1 rounded align-self-start">REF: {{ print.ref_code }}</div>
                    </div>
                  </div>
                </div>

                <div v-else class="py-12 text-center bg-grey-lighten-5 rounded-2xl border border-grey-lighten-3 mx-2">
                  <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-palette-swatch-outline</v-icon>
                  <h3 class="text-h5 font-weight-black text-grey-darken-3 mb-2">Vitrine Vazia</h3>
                  <p class="text-grey text-body-2 px-4">Utilize o menu lateral (Gerenciar Conteúdo) para cadastrar estampas reais e vê-las aqui.</p>
                </div>
              </div>
            </div>

            <div v-if="internalState.cartOpen" class="absolute top-0 right-0 h-100 bg-white shadow-2xl z-50 d-flex flex-column transition-all" :style="{ width: previewDevice === 'mobile' ? '100%' : '380px' }">
              <div class="pa-4 border-b d-flex justify-space-between align-center bg-grey-lighten-5">
                <h3 class="font-weight-black text-body-1"><v-icon color="primary" class="mr-2">mdi-hanger</v-icon> Moodboard</h3>
                <v-btn icon="mdi-close" variant="text" size="small" @click="internalState.cartOpen = false"></v-btn>
              </div>
              <div class="flex-grow-1 pa-4 overflow-y-auto custom-scroll">
                 <div v-if="internalState.cart.length === 0" class="text-center opacity-60 mt-10">
                   <v-icon size="48" class="mb-3">mdi-heart-broken-outline</v-icon>
                   <p class="font-weight-bold">Carrinho vazio.</p>
                 </div>
                 <div v-for="item in internalState.cart" :key="item.id" class="d-flex align-center gap-3 mb-3 pa-2 border rounded-lg shadow-sm">
                   <v-img :src="item.image_url" width="50" height="50" cover class="rounded bg-grey-lighten-4 flex-shrink-0"></v-img>
                   <div class="flex-grow-1 overflow-hidden">
                     <div class="text-caption font-weight-black text-truncate">{{ item.title }}</div>
                     <div class="text-[10px] text-grey font-mono">{{ item.ref_code }}</div>
                   </div>
                   <v-btn icon="mdi-delete" variant="text" color="error" size="small" @click="toggleCartMock(item)"></v-btn>
                 </div>
              </div>
              <div class="pa-4 border-t bg-grey-lighten-5">
                <button class="btn-3d w-100 py-3 rounded-lg font-weight-black text-body-2" :style="{ backgroundColor: themeConfig.buttonColor, color: themeConfig.buttonTextColor }">Solicitar Orçamento</button>
              </div>
            </div>

            <div v-if="themeConfig.maintenanceMode" class="absolute-fill d-flex flex-column align-center justify-center p-6 text-center" style="background: rgba(0,0,0,0.85); backdrop-filter: blur(5px); z-index: 9999;">
               <v-icon size="64" color="error" class="mb-4">mdi-lock</v-icon>
               <h2 class="text-h5 font-weight-black text-white mb-2">Site Privado</h2>
               <p class="text-body-2 text-grey-lighten-1">O modo manutenção está ativado.</p>
            </div>

          </div>
        </div>
      </main>
    </div>

    <v-dialog v-model="listModal.show" max-width="1000" transition="dialog-bottom-transition">
      <v-card class="rounded-xl overflow-hidden d-flex flex-column bg-grey-lighten-5" style="height: 85vh;">
        <div class="px-6 py-4 bg-white border-b d-flex justify-space-between align-center shadow-sm flex-shrink-0">
          <div><div class="text-caption font-weight-black text-primary text-uppercase">Banco de Dados</div><h3 class="text-h5 font-weight-black text-grey-darken-4">{{ listModalTitle }}</h3></div>
          <v-btn icon="mdi-close" variant="text" class="btn-3d" size="small" @click="listModal.show = false"></v-btn>
        </div>

        <div class="flex-grow-1 overflow-y-auto pa-6 custom-scroll">
          <div class="d-flex justify-space-between align-center mb-4">
             <span class="text-caption font-weight-bold text-grey">Gerencie os registros públicos desta seção.</span>
             <v-btn color="success" prepend-icon="mdi-plus" class="font-weight-black text-none btn-3d px-6" @click="openFormModal(listModal.type)">Adicionar Novo</v-btn>
          </div>

          <v-table v-if="listModal.type === 'categories'" class="border rounded-xl bg-white shadow-sm overflow-hidden">
            <thead class="bg-grey-lighten-4"><tr><th class="font-weight-black text-uppercase text-caption">ID</th><th class="font-weight-black text-uppercase text-caption w-100">Nome da Categoria</th><th class="font-weight-black text-uppercase text-caption text-right">Ações</th></tr></thead>
            <tbody>
              <tr v-for="cat in realData.categories" :key="cat.id">
                <td class="pa-4 font-mono text-grey">{{ cat.id }}</td>
                <td class="font-weight-bold">{{ cat.name }}</td>
                <td class="text-right no-wrap">
                  <v-btn size="small" icon="mdi-pencil" variant="text" color="primary" class="mr-1" @click="openFormModal('categories', cat)"></v-btn>
                  <v-btn size="small" icon="mdi-delete" variant="text" color="error" @click="deleteItem('catalog_categories', cat.id)"></v-btn>
                </td>
              </tr>
              <tr v-if="realData.categories.length === 0"><td colspan="3" class="text-center pa-6 text-grey">Nenhuma categoria cadastrada.</td></tr>
            </tbody>
          </v-table>

          <v-table v-if="listModal.type === 'prints'" class="border rounded-xl bg-white shadow-sm overflow-hidden">
            <thead class="bg-grey-lighten-4"><tr><th class="font-weight-black text-uppercase text-caption">Img</th><th class="font-weight-black text-uppercase text-caption">REF</th><th class="font-weight-black text-uppercase text-caption w-100">Título</th><th class="font-weight-black text-uppercase text-caption">Categoria</th><th class="font-weight-black text-uppercase text-caption text-right">Ações</th></tr></thead>
            <tbody>
              <tr v-for="p in realData.prints" :key="p.id">
                <td class="pa-2"><v-img :src="p.image_url" width="40" height="40" cover class="rounded bg-grey-lighten-3"></v-img></td>
                <td class="font-mono text-caption font-weight-bold">{{ p.ref_code }}</td>
                <td class="font-weight-medium">{{ p.title }}</td>
                <td class="text-caption">{{ getCategoryName(p.category_id) }}</td>
                <td class="text-right no-wrap">
                  <v-btn size="small" icon="mdi-pencil" variant="text" color="primary" class="mr-1" @click="openFormModal('prints', p)"></v-btn>
                  <v-btn size="small" icon="mdi-delete" variant="text" color="error" @click="deleteItem('catalog_prints', p.id)"></v-btn>
                </td>
              </tr>
              <tr v-if="realData.prints.length === 0"><td colspan="5" class="text-center pa-6 text-grey">Nenhuma estampa cadastrada.</td></tr>
            </tbody>
          </v-table>

          <v-table v-if="listModal.type === 'banners'" class="border rounded-xl bg-white shadow-sm overflow-hidden">
            <thead class="bg-grey-lighten-4"><tr><th class="font-weight-black text-uppercase text-caption">Banner</th><th class="font-weight-black text-uppercase text-caption w-100">Título</th><th class="font-weight-black text-uppercase text-caption">Tag</th><th class="font-weight-black text-uppercase text-caption text-right">Ações</th></tr></thead>
            <tbody>
              <tr v-for="b in realData.banners" :key="b.id">
                <td class="pa-2"><v-img :src="b.image_url" width="100" height="40" cover class="rounded bg-grey-lighten-3"></v-img></td>
                <td class="font-weight-bold">{{ b.title }}</td>
                <td><v-chip size="x-small" class="font-weight-bold">{{ b.tag }}</v-chip></td>
                <td class="text-right no-wrap">
                  <v-btn size="small" icon="mdi-pencil" variant="text" color="primary" class="mr-1" @click="openFormModal('banners', b)"></v-btn>
                  <v-btn size="small" icon="mdi-delete" variant="text" color="error" @click="deleteItem('catalog_banners', b.id)"></v-btn>
                </td>
              </tr>
              <tr v-if="realData.banners.length === 0"><td colspan="4" class="text-center pa-6 text-grey">Nenhum banner cadastrado.</td></tr>
            </tbody>
          </v-table>
        </div>
      </v-card>
    </v-dialog>

    <v-dialog v-model="formModal.show" max-width="600" persistent>
      <v-card class="rounded-xl overflow-hidden bg-white">
        <div class="px-6 py-4 border-b d-flex justify-space-between align-center bg-grey-lighten-5">
          <h3 class="text-h6 font-weight-black text-grey-darken-4">{{ formModal.isEditing ? 'Editar' : 'Novo' }} Registro</h3>
          <v-btn icon="mdi-close" variant="text" size="small" @click="formModal.show = false"></v-btn>
        </div>

        <div class="pa-6">
          <v-form ref="crudForm" v-model="formModal.isValid" @submit.prevent="submitForm">

            <template v-if="formModal.type === 'categories'">
              <v-text-field v-model="formData.name" label="Nome da Categoria" variant="outlined" density="comfortable" class="builder-input" :rules="[v => !!v || 'Obrigatório']"></v-text-field>
            </template>

            <template v-if="formModal.type === 'prints'">
              <v-row dense>
                <v-col cols="12" sm="8"><v-text-field v-model="formData.title" label="Título" variant="outlined" density="comfortable" class="builder-input" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                <v-col cols="12" sm="4"><v-text-field v-model="formData.ref_code" label="REF" variant="outlined" density="comfortable" class="builder-input" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                <v-col cols="12"><v-select v-model="formData.category_id" :items="realData.categories" item-title="name" item-value="id" label="Categoria" variant="outlined" density="comfortable" class="builder-input" :rules="[v => !!v || 'Obrigatório']"></v-select></v-col>
                <v-col cols="12"><v-textarea v-model="formData.description" label="Descrição" variant="outlined" density="comfortable" rows="2" class="builder-input"></v-textarea></v-col>
                <v-col cols="12" sm="6"><v-switch v-model="formData.is_new" color="primary" label="Marcar como Novo" hide-details></v-switch></v-col>
                <v-col cols="12" sm="6"><v-switch v-model="formData.active" color="success" label="Ativo" hide-details></v-switch></v-col>
                <v-col cols="12"><v-file-input v-model="formUploadFile" accept="image/*" label="Upload da Estampa" variant="outlined" density="comfortable" prepend-inner-icon="mdi-upload" prepend-icon="" hide-details class="builder-input mt-2" :hint="formData.image_url ? 'Deixe em branco para manter a imagem' : ''" persistent-hint></v-file-input></v-col>
              </v-row>
            </template>

            <template v-if="formModal.type === 'banners'">
              <v-row dense>
                <v-col cols="12" sm="4"><v-text-field v-model="formData.tag" label="Tag (Ex: NOVO)" variant="outlined" density="comfortable" class="builder-input"></v-text-field></v-col>
                <v-col cols="12" sm="8"><v-text-field v-model="formData.title" label="Título Principal" variant="outlined" density="comfortable" class="builder-input" :rules="[v => !!v || 'Obrigatório']"></v-text-field></v-col>
                <v-col cols="12"><v-text-field v-model="formData.subtitle" label="Subtítulo" variant="outlined" density="comfortable" class="builder-input"></v-text-field></v-col>
                <v-col cols="12" sm="6"><v-text-field v-model="formData.cta_text" label="Texto do Botão" variant="outlined" density="comfortable" class="builder-input"></v-text-field></v-col>
                <v-col cols="12" sm="6"><v-switch v-model="formData.active" color="success" label="Ativo" hide-details></v-switch></v-col>
                <v-col cols="12"><v-file-input v-model="formUploadFile" accept="image/*" label="Upload do Banner HD" variant="outlined" density="comfortable" prepend-inner-icon="mdi-upload" prepend-icon="" hide-details class="builder-input mt-2" :hint="formData.image_url ? 'Deixe em branco para manter' : ''" persistent-hint></v-file-input></v-col>
              </v-row>
            </template>

          </v-form>
        </div>

        <div class="px-6 py-4 border-t d-flex justify-end gap-3 bg-grey-lighten-5">
          <v-btn variant="outlined" class="btn-3d font-weight-bold text-none rounded-lg" @click="formModal.show = false" :disabled="formModal.loading">Cancelar</v-btn>
          <v-btn color="success" variant="flat" class="btn-3d px-6 font-weight-black text-none rounded-lg" @click="submitForm" :loading="formModal.loading">Salvar Registro</v-btn>
        </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useThemeStore } from '@/stores/themeStore';

const appStore = useAppStore();
const themeStore = useThemeStore();

// UI States
const activePanels = ref(['branding', 'colors']);
const previewDevice = ref('desktop');
const previewScreen = ref('catalog');
const isSaving = ref(false);

const internalState = reactive({ cartOpen: false, cart: [] as any[] });
const isInCartMock = (id: number) => internalState.cart.some(i => i.id === id);
const toggleCartMock = (print: any) => {
  if (isInCartMock(print.id)) internalState.cart = internalState.cart.filter(i => i.id !== print.id);
  else internalState.cart.push(print);
};

// ==========================================
// THEME ENGINE STATE
// ==========================================
const themeConfig = reactive({
  logoLightUrl: '', logoDarkUrl: '', primaryColor: '#000000', backgroundColor: '#f8fafc', textColor: '#333333', headerColor: '#ffffff', buttonColor: '#000000', buttonTextColor: '#ffffff', fontSize: '14px', bgTextureUrl: '', maintenanceMode: false, popupEnabled: true, popupText: 'NOVA COLEÇÃO', popupBgColor: '#000000', popupTextColor: '#ffffff', loginTitle: 'Estúdio Interativo', loginSubtitle: 'Acesse nosso catálogo exclusivo.',
});
const uploadLogoLight = ref<File | null>(null);
const uploadLogoDark = ref<File | null>(null);
const uploadBgTexture = ref<File | null>(null);

// ==========================================
// DADOS REAIS (Buscados do Supabase)
// ==========================================
const realData = reactive({ categories: [] as any[], banners: [] as any[], prints: [] as any[], mockups: [] as any[] });

const listModal = reactive({ show: false, type: '' });
const listModalTitle = computed(() => {
  const map: any = { banners: 'Banners Principais', prints: 'Estampas', categories: 'Categorias de Estampa', mockups: 'Mockups 3D' };
  return map[listModal.type] || 'Gestão';
});

const formModal = reactive({ show: false, isEditing: false, type: '', loading: false, isValid: false });
const formData = ref<any>({});
const formUploadFile = ref<File | null>(null);

const dynamicThemeStyles = computed(() => ({
  fontSize: themeConfig.fontSize, backgroundColor: themeConfig.backgroundColor, backgroundImage: themeConfig.bgTextureUrl ? `url(${themeConfig.bgTextureUrl})` : 'none', backgroundSize: 'cover', backgroundPosition: 'center', backgroundAttachment: 'fixed', color: themeConfig.textColor, fontFamily: "'Inter', sans-serif"
}));

const isHeaderDark = computed(() => {
  if (!themeConfig.headerColor) return false;
  const hex = themeConfig.headerColor.replace('#', '');
  const r = parseInt(hex.substr(0, 2), 16); const g = parseInt(hex.substr(2, 2), 16); const b = parseInt(hex.substr(4, 2), 16);
  return (((r * 299) + (g * 587) + (b * 114)) / 1000) < 128;
});

const getCategoryName = (id: number) => realData.categories.find(c => c.id === id)?.name || 'Sem Categoria';
const handleLogoLightPreview = (file: File | null) => { if (file) themeConfig.logoLightUrl = URL.createObjectURL(file); };
const handleLogoDarkPreview = (file: File | null) => { if (file) themeConfig.logoDarkUrl = URL.createObjectURL(file); };
const handleTexturePreview = (file: File | null) => { if (file) themeConfig.bgTextureUrl = URL.createObjectURL(file); };
const openLiveSite = () => window.open('/catalogo-interativo', '_blank');

// ==========================================
// INTEGRAÇÃO COM SUPABASE (THEME & CRUD)
// ==========================================
const fetchSettings = async () => {
  try {
    const { data } = await supabase.from('catalog_settings').select('theme_config').eq('id', 1).single();
    if (data?.theme_config) Object.assign(themeConfig, data.theme_config);
  } catch (e) { console.log("Usando configs padrão."); }
};

const fetchRealData = async () => {
  try {
    const [catRes, banRes, prtRes] = await Promise.all([
      supabase.from('catalog_categories').select('*').order('name'),
      supabase.from('catalog_banners').select('*').order('created_at', { ascending: false }),
      supabase.from('catalog_prints').select('*').order('created_at', { ascending: false })
    ]);
    realData.categories = catRes.data || [];
    realData.banners = banRes.data || [];
    realData.prints = prtRes.data || [];
  } catch (error) {
    appStore.showSnackbar('Erro ao carregar dados do banco', 'error');
  }
};

const uploadToStorage = async (file: File, prefix: string) => {
  const fileName = `${prefix}_${Date.now()}.${file.name.split('.').pop()}`;
  const { error } = await supabase.storage.from('catalog-assets').upload(fileName, file);
  if (error) throw error;
  const { data } = supabase.storage.from('catalog-assets').getPublicUrl(fileName);
  return data.publicUrl;
};

const saveSettings = async () => {
  isSaving.value = true;
  try {
    if (uploadLogoLight.value) themeConfig.logoLightUrl = await uploadToStorage(uploadLogoLight.value, 'logo_light');
    if (uploadLogoDark.value) themeConfig.logoDarkUrl = await uploadToStorage(uploadLogoDark.value, 'logo_dark');
    if (uploadBgTexture.value) themeConfig.bgTextureUrl = await uploadToStorage(uploadBgTexture.value, 'bg_texture');
    uploadLogoLight.value = null; uploadLogoDark.value = null; uploadBgTexture.value = null;

    const payload = { id: 1, theme_config: { ...themeConfig }, updated_at: new Date().toISOString() };
    const { error } = await supabase.from('catalog_settings').upsert(payload);
    if (error) throw error;
    appStore.showSnackbar('Tema publicado!', 'success', { icon: 'mdi-check' });
  } catch (error) { appStore.showSnackbar('Erro ao salvar tema.', 'error'); }
  finally { isSaving.value = false; }
};

// ACTIONS CRUD
const openListModal = (type: string) => { listModal.type = type; listModal.show = true; };

const openFormModal = (type: string, item: any = null) => {
  formModal.type = type;
  formModal.isEditing = !!item;
  formModal.isValid = false;
  formUploadFile.value = null;

  if (item) {
    formData.value = { ...item };
  } else {
    // Define valores defaults isolados para cada tabela para evitar conflito de colunas
    if (type === 'categories') formData.value = { name: '' };
    else if (type === 'banners') formData.value = { active: true, tag: '', title: '', subtitle: '', cta_text: '' };
    else if (type === 'prints') formData.value = { active: true, is_new: false, title: '', ref_code: '', category_id: null, description: '' };
  }

  formModal.show = true;
};

const submitForm = async () => {
  if (!formModal.isValid) return appStore.showSnackbar('Verifique os campos obrigatórios', 'warning');
  formModal.loading = true;
  try {
    const tableMap: any = { prints: 'catalog_prints', categories: 'catalog_categories', banners: 'catalog_banners' };
    const table = tableMap[formModal.type];

    // Filtramos o payload garantindo que apenas as colunas corretas vão para o Supabase
    let payload: any = {};
    if (formModal.type === 'categories') {
      payload = { name: formData.value.name };
    } else if (formModal.type === 'banners') {
      payload = {
        tag: formData.value.tag, title: formData.value.title, subtitle: formData.value.subtitle,
        cta_text: formData.value.cta_text, active: formData.value.active
      };
    } else if (formModal.type === 'prints') {
      payload = {
        title: formData.value.title, ref_code: formData.value.ref_code, category_id: formData.value.category_id,
        description: formData.value.description, is_new: formData.value.is_new, active: formData.value.active
      };
    }

    if (formModal.isEditing) {
      payload.id = formData.value.id; // Se for edição, mantém o ID
    }

    // Faz o upload e salva a URL, caso não seja categoria
    if (formUploadFile.value) {
      payload.image_url = await uploadToStorage(formUploadFile.value, formModal.type);
    } else if (!formModal.isEditing && formModal.type !== 'categories') {
      throw new Error('A imagem é obrigatória para novos cadastros.');
    } else if (formModal.isEditing && formModal.type !== 'categories') {
      payload.image_url = formData.value.image_url; // Mantém a antiga
    }

    if (formModal.isEditing) {
      const { error } = await supabase.from(table).update(payload).eq('id', payload.id);
      if (error) throw error;
    } else {
      const { error } = await supabase.from(table).insert([payload]);
      if (error) throw error;
    }

    appStore.showSnackbar('Registro salvo!', 'success');
    formModal.show = false;
    await fetchRealData(); // Recarrega TUDO do banco real
  } catch (e: any) {
    console.error(e);
    appStore.showSnackbar(e.message || 'Erro ao salvar', 'error');
  } finally {
    formModal.loading = false;
  }
};

const deleteItem = async (table: string, id: number) => {
  if (!confirm('Excluir este item permanentemente?')) return;
  try {
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error) throw error;
    appStore.showSnackbar('Excluído!', 'success');
    fetchRealData();
  } catch (e) { appStore.showSnackbar('Erro ao excluir', 'error'); }
};

onMounted(() => { fetchSettings(); fetchRealData(); });
</script>

<style scoped lang="scss">
.theme-builder { min-height: calc(100vh - 64px); }
.d-grid { display: grid; }
.text-truncate-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.font-mono { font-family: 'SFMono-Regular', Consolas, monospace; }
.no-select { -webkit-user-select: none; user-select: none; }
.absolute-fill { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
.no-wrap { white-space: nowrap; }

/* BOTOES 3D */
.btn-3d { border-radius: 8px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.2) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; border: none; cursor: pointer; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.1) !important; }
.chip-3d { border-radius: 20px; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.5); border: 1px solid rgba(0,0,0,0.05); cursor: pointer;}

/* SIDEBAR E ACORDEOES */
.builder-sidebar { width: 340px; box-shadow: 2px 0 15px rgba(0,0,0,0.03); }
.flat-panels :deep(.v-expansion-panel) { background: transparent !important; border-radius: 0 !important; }
.flat-panels :deep(.v-expansion-panel-title) { padding: 14px 20px; min-height: unset !important; }
.flat-panels :deep(.v-expansion-panel-title__overlay) { opacity: 0 !important; }
.flat-panels :deep(.v-expansion-panel-text__wrapper) { padding: 0 20px 20px 20px; }
.builder-input :deep(.v-field__outline) { --v-field-border-opacity: 0.15; }
.dark-input :deep(.v-field__outline) { --v-field-border-opacity: 0.4; }
.dark-input :deep(.v-label) { color: rgba(255,255,255,0.7); }

/* COLOR PICKER */
.pro-color-picker { display: flex; align-items: center; justify-content: space-between; }
.color-control { display: flex; align-items: center; gap: 8px; padding: 4px 10px 4px 4px; border-radius: 8px; background: white; width: 140px; box-shadow: inset 0 1px 2px rgba(0,0,0,0.05); }
.color-control input[type="color"] { width: 28px; height: 28px; padding: 0; border: none; border-radius: 6px; cursor: pointer; background: transparent; }
.color-control input[type="color"]::-webkit-color-swatch-wrapper { padding: 0; }
.color-control input[type="color"]::-webkit-color-swatch { border: 1px solid rgba(0,0,0,0.1); border-radius: 4px; }

/* PREVIEW CONTROLS */
.preview-tab-btn { padding: 6px 16px; font-size: 12px; font-weight: bold; color: #757575; border-radius: 6px; transition: all 0.2s; }
.preview-tab-btn.active { background: white; color: #000; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.device-btn { width: 36px; height: 32px; border-radius: 6px; color: #757575; transition: all 0.2s; display: flex; align-items: center; justify-content: center; }
.device-btn.active { background: white; color: #000; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

/* DEVICE FRAMES E PREVIEW */
.device-frame { margin: 0 auto; transition: width 0.4s cubic-bezier(0.25, 0.8, 0.25, 1), height 0.4s cubic-bezier(0.25, 0.8, 0.25, 1), border-radius 0.4s; }
.is-desktop-frame { width: 100%; max-width: 1200px; height: 100%; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); }
.is-mobile-frame { width: 375px; height: 750px; border-radius: 40px !important; border: 14px solid #1a1a1a !important; box-shadow: 0 0 0 2px #e0e0e0, 0 30px 60px -12px rgba(0, 0, 0, 0.5) !important; background-color: #fff; &::before { content: ''; position: absolute; top: 0; left: 50%; transform: translateX(-50%); width: 120px; height: 24px; background: #1a1a1a; border-bottom-left-radius: 16px; border-bottom-right-radius: 16px; z-index: 999; } }

/* MOCK DE SITE */
.site-mock-container { position: relative; overflow-y: auto; height: 100%; width: 100%; }
.bg-black-overlay { background: radial-gradient(circle, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.8) 100%); }
.sticky-header { position: sticky; top: 0; backdrop-filter: blur(15px); }
.sticky-filter-bar { position: sticky; top: 60px; z-index: 40; }
.product-card { transition: transform 0.3s, box-shadow 0.3s; }
.product-card:hover { transform: translateY(-4px); box-shadow: 0 15px 30px -10px rgba(0,0,0,0.1) !important; }
.group-hover-scale { transition: transform 0.8s cubic-bezier(0.165, 0.84, 0.44, 1); }
.group:hover .group-hover-scale { transform: scale(1.08); }
.overlay-actions { background: linear-gradient(to top, rgba(0,0,0,0.5) 0%, transparent 100%); z-index: 4; }
.group-hover-opacity-100 { opacity: 1 !important; }

/* SCROLLBARS */
.custom-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 10px; }
.custom-scroll-horizontal::-webkit-scrollbar { height: 3px; }
.custom-scroll-horizontal::-webkit-scrollbar-thumb { background: #bdbdbd; border-radius: 4px; }
</style>
