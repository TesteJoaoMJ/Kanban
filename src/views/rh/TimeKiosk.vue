<template>
  <v-theme-provider theme="dark">
    <div class="v-theme--dark kiosk-container w-100 h-100 d-flex flex-column align-center justify-center position-relative overflow-hidden bg-grey-darken-4">

      <div v-if="viewState === 'UNCONFIGURED'" class="position-absolute top-0 left-0 w-100 h-100 bg-black-80 z-[150] d-flex flex-column align-center justify-center backdrop-blur-xl">
        <div class="admin-trigger cursor-pointer" @click="handleAdminClick" style="pointer-events: auto;">
          <v-icon color="grey-darken-2" size="120" class="mb-6 pulse-text">mdi-lock-alert-outline</v-icon>
        </div>
        <h1 class="text-h3 font-weight-black text-white text-uppercase tracking-widest text-shadow-glow">Totem Não Vinculado</h1>
        <p class="text-h6 text-grey mt-4 font-weight-regular text-center px-4" style="max-width: 600px;">
          Este dispositivo não possui identidade na rede.
        </p>
        <p class="text-caption text-primary-lighten-2 mt-2 tracking-widest text-uppercase">Clique 5 vezes no cadeado para abrir o painel de configuração.</p>
      </div>

      <div v-if="viewState === 'DENIED'" class="position-absolute top-0 left-0 w-100 h-100 bg-black-80 z-[100] d-flex flex-column align-center justify-center backdrop-blur-xl">
        <v-icon color="error" size="120" class="mb-6 shake-anim">mdi-map-marker-off</v-icon>
        <h1 class="text-h3 font-weight-black text-error text-uppercase tracking-widest text-shadow-glow">Perímetro Inválido</h1>
        <p class="text-h5 text-white mt-4 font-weight-bold text-center px-4" style="max-width: 600px;">{{ accessErrorMessage }}</p>
        <p class="text-body-1 text-primary-lighten-2 mt-2 tracking-widest text-uppercase">O registro está fora dos parâmetros da filial.</p>

        <div class="mt-8 d-flex gap-4">
          <v-btn color="primary" variant="flat" size="large" class="font-weight-black tracking-widest px-8 rounded-sm" @click="verifyAccess">
            <v-icon start>mdi-refresh</v-icon> Tentar Novamente
          </v-btn>
        </div>
      </div>

      <div class="kiosk-background position-absolute top-0 left-0 w-100 h-100 pointer-events-none">
        <div class="glow-orb primary-glow"></div>
        <div class="glow-orb secondary-glow"></div>
      </div>

      <div class="kiosk-header position-absolute top-0 w-100 d-flex flex-column align-center pt-8 z-50 pointer-events-none">
        <div class="d-flex align-center gap-3 mb-2 admin-trigger px-6 py-2 rounded-sm" @click="handleAdminClick" style="pointer-events: auto; cursor: pointer;">
          <v-icon color="primary" size="36">mdi-face-recognition</v-icon>
          <h1 class="text-h5 font-weight-black text-white letter-spacing-2 text-uppercase text-shadow user-select-none">
            {{ currentKioskInfo?.name || 'Kiosk Biométrico Central' }}
          </h1>
        </div>
        <h2 class="text-h1 font-weight-black text-white text-shadow-glow font-mono lh-1 user-select-none">{{ currentTime }}</h2>
        <p class="text-subtitle-1 text-primary-lighten-2 font-weight-bold mt-2 text-uppercase tracking-widest text-shadow user-select-none">{{ currentDate }}</p>
      </div>

      <div class="position-absolute top-0 left-0 pa-6 z-20 d-flex flex-column gap-3 h-100 pointer-events-none" style="width: 320px; padding-top: 140px !important;">
        <div v-if="recentLogs.length > 0" class="text-[10px] font-weight-black text-white opacity-50 text-uppercase tracking-widest mb-1 px-2 text-shadow">Registros Recentes</div>
        <transition-group name="log-list-vertical">
          <div v-for="log in recentLogs" :key="log.id" class="recent-log-card glass-panel rounded-sm pa-3 d-flex align-center gap-4 border-white-10 shadow-sm flex-shrink-0">
            <v-avatar size="42" class="border-white-20 shadow-sm rounded-sm">
              <v-img :src="log.avatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(log.name)}&background=1976D2&color=fff`"></v-img>
            </v-avatar>
            <div class="d-flex flex-column overflow-hidden">
              <span class="text-body-2 font-weight-black text-white lh-1 text-truncate">{{ log.name.split(' ')[0] }} {{ log.name.split(' ').length > 1 ? log.name.split(' ')[1].charAt(0) + '.' : '' }}</span>
              <span class="text-caption text-success font-weight-bold font-mono mt-1 d-flex align-center gap-1"><v-icon size="12">mdi-check-decagram</v-icon> {{ log.time }}</span>
            </div>
          </div>
        </transition-group>
      </div>

      <transition name="slide-right">
        <div v-if="cooldownTray.show" class="position-absolute top-0 right-0 pa-6 z-40 pointer-events-none" style="width: 360px; padding-top: 140px !important;">
           <div class="glass-panel rounded-sm pa-5 shadow-neon-elegant" :class="cooldownTray.isLimitReached ? 'border-error' : 'border-warning'">
             <div class="d-flex align-center gap-4 mb-5 border-b border-white-10 pb-4">
               <v-avatar :color="cooldownTray.isLimitReached ? 'error' : 'warning'" variant="tonal" size="48" class="rounded-sm">
                 <v-icon size="28" :color="cooldownTray.isLimitReached ? 'error' : 'warning'">
                   {{ cooldownTray.isLimitReached ? 'mdi-cancel' : 'mdi-clock-alert-outline' }}
                 </v-icon>
               </v-avatar>
               <div class="overflow-hidden">
                 <div class="text-[10px] font-weight-black text-uppercase tracking-widest lh-1 mb-1" :class="cooldownTray.isLimitReached ? 'text-error' : 'text-warning'">
                   {{ cooldownTray.isLimitReached ? 'Limite Atingido' : 'Trava de Tempo' }}
                 </div>
                 <div class="text-body-2 font-weight-black text-white text-truncate" :title="cooldownTray.employeeName">{{ cooldownTray.employeeName }}</div>
               </div>
             </div>
             <div class="text-[10px] text-white opacity-70 text-uppercase font-weight-bold tracking-widest mb-3">Batidas Hoje:</div>
             <div class="d-flex flex-wrap gap-2 mb-5">
               <v-chip v-for="p in cooldownTray.punches" :key="p" size="small" :color="cooldownTray.isLimitReached ? 'error' : 'primary'" variant="flat" class="font-mono font-weight-black rounded-sm px-3">{{ p }}</v-chip>
             </div>
             <div class="bg-black-40 rounded-sm pa-4 border-white-10 d-flex align-center justify-space-between backdrop-blur-md">
               <span class="text-caption font-weight-black text-white opacity-80 text-uppercase tracking-widest">
                 {{ cooldownTray.isLimitReached ? 'Status:' : 'Liberação às:' }}
               </span>
               <span class="text-h6 font-mono font-weight-black lh-1" :class="cooldownTray.isLimitReached ? 'text-error' : 'text-success'">
                 {{ cooldownTray.isLimitReached ? 'Bloqueado' : cooldownTray.nextAllowedTime }}
               </span>
             </div>
             <v-progress-linear indeterminate :color="cooldownTray.isLimitReached ? 'error' : 'warning'" height="2" class="opacity-30 mt-4 rounded-0"></v-progress-linear>
           </div>
        </div>
      </transition>

      <div class="scanner-wrapper position-relative z-10 d-flex flex-column align-center mt-12 w-100" style="max-width: 1000px; pointer-events: none;">
        <div class="video-frame position-relative rounded-sm overflow-hidden shadow-neon-elegant" :class="statusClass" style="width: 100%; height: 60vh; min-height: 400px; background: #000;">
          <video ref="blurVideoRef" autoplay muted playsinline class="position-absolute top-0 left-0 w-100 h-100 blur-bg"></video>
          <div class="position-absolute top-0 left-0 w-100 h-100 bg-black opacity-60 z-0"></div>
          <video ref="videoRef" autoplay muted playsinline class="position-absolute top-0 left-0 w-100 h-100 object-contain z-1"></video>
          <canvas ref="canvasRef" class="position-absolute top-0 left-0 w-100 h-100 object-contain pointer-events-none z-10"></canvas>

          <div v-if="viewState === 'CHECKING' || isInitializing" class="position-absolute top-0 left-0 w-100 h-100 d-flex flex-column align-center justify-center bg-black-80 z-20 backdrop-blur-xl">
            <v-progress-circular indeterminate color="primary" size="80" width="6" class="mb-5"></v-progress-circular>
            <span class="text-white font-weight-black text-uppercase tracking-widest text-body-1 pulse-text">{{ loadingText }}</span>
          </div>

          <transition name="flash">
             <div v-if="showSuccessFlash" class="position-absolute top-0 left-0 w-100 h-100 z-30 d-flex flex-column align-center justify-center success-flash">
                 <v-icon color="success" size="140" class="mb-4 pulse-ring">mdi-fingerprint</v-icon>
                 <span class="text-h4 font-weight-black text-success tracking-widest text-uppercase text-shadow-glow">Acesso Liberado</span>
                 <span class="text-h6 font-mono text-white mt-2 text-shadow">{{ currentTime }}</span>
             </div>
          </transition>

          <transition name="flash">
             <div v-if="showSpoofFlash" class="position-absolute top-0 left-0 w-100 h-100 z-30 d-flex flex-column align-center justify-center error-flash">
                 <v-icon color="error" size="140" class="mb-4 shake-anim">mdi-shield-alert-outline</v-icon>
                 <span class="text-h4 font-weight-black text-error tracking-widest text-uppercase text-shadow-glow">Acesso Negado</span>
                 <span class="text-h6 font-weight-bold text-white mt-2 text-shadow">Validação falhou ou limite atingido.</span>
             </div>
          </transition>

          <div v-if="livenessPending && !showSuccessFlash && !showSpoofFlash" class="position-absolute top-0 left-0 w-100 h-100 d-flex flex-column align-center justify-end z-10 pb-8 pointer-events-none">
             <div class="liveness-badge d-flex flex-column align-center justify-center bg-black-80 rounded-sm pa-4 border-warning shadow-neon-warning backdrop-blur-md">
                <div class="d-flex align-center gap-4">
                   <v-progress-circular :model-value="livenessProgress" color="warning" size="32" width="3"></v-progress-circular>
                   <div class="d-flex flex-column">
                      <span class="text-subtitle-2 font-weight-black text-white text-uppercase tracking-widest lh-1">Analisando Sinais Vitais</span>
                      <span class="text-warning font-weight-bold text-caption mt-1">Mantenha a naturalidade...</span>
                   </div>
                </div>
             </div>
          </div>

          <template v-if="viewState === 'RUNNING' && !isInitializing && !showSuccessFlash && !showSpoofFlash">
             <div class="scanner-hud position-absolute top-0 left-0 w-100 h-100 pointer-events-none z-10">
                <div class="scanner-corner top-left"></div>
                <div class="scanner-corner top-right"></div>
                <div class="scanner-corner bottom-left"></div>
                <div class="scanner-corner bottom-right"></div>
                <div class="scan-line" :class="livenessPending ? 'scan-line-warning' : ''"></div>
             </div>
          </template>
        </div>

        <transition name="status-slide" mode="out-in">
          <div v-if="currentScanStatus" :key="currentScanStatus.type" class="status-panel mt-6 glass-panel rounded-sm pa-4 d-flex align-center gap-4 border" :class="statusBorderClass" style="min-width: 450px; max-width: 700px;">
            <v-avatar :color="currentScanStatus.color" size="56" class="shadow-sm rounded-sm">
              <v-icon size="32" color="white">{{ currentScanStatus.icon }}</v-icon>
            </v-avatar>
            <div class="d-flex flex-column flex-grow-1">
              <span class="text-caption font-weight-bold text-uppercase opacity-70 text-white tracking-widest">{{ currentScanStatus.title }}</span>
              <span class="text-h6 font-weight-black text-white lh-1 mt-1">{{ currentScanStatus.message }}</span>
            </div>
          </div>
        </transition>
      </div>

      <v-dialog v-model="showPinPrompt" max-width="400" persistent z-index="9999">
        <v-card class="glass-panel text-white border-white-10 rounded-sm pa-2" theme="dark">
          <v-card-title class="text-h6 font-weight-black text-primary text-center mt-2 text-uppercase tracking-widest">
            <v-icon color="primary" class="mb-2" size="40">mdi-shield-account</v-icon><br>
            Acesso Administrativo
          </v-card-title>
          <v-card-text>
            <form @submit.prevent="validatePin">
              <v-text-field
                v-model="adminPinInput"
                label="Senha Admin"
                type="password"
                variant="outlined"
                color="primary"
                bg-color="#121212"
                hide-details
                autofocus
              ></v-text-field>
              <button type="submit" style="display:none"></button>
            </form>
          </v-card-text>
          <v-card-actions class="px-6 pb-6 d-flex gap-3 mt-4">
            <v-btn color="grey" variant="text" block class="rounded-sm" @click="showPinPrompt = false; adminPinInput = ''">Cancelar</v-btn>
            <v-btn color="primary" variant="flat" block class="rounded-sm" @click="validatePin">Entrar</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <v-navigation-drawer
        v-model="showAdminDrawer"
        location="right"
        temporary
        width="550"
        theme="dark"
        class="admin-drawer glass-panel border-s border-white-10 text-white"
        style="background: rgba(18, 18, 22, 0.98) !important;"
      >
        <div class="h-100 d-flex flex-column relative">
          <div class="pa-6 border-b border-white-10 d-flex align-center justify-space-between bg-black-40">
            <div class="d-flex align-center gap-3">
              <v-icon color="primary" size="28">mdi-tablet-dashboard</v-icon>
              <div>
                <h3 class="text-subtitle-1 font-weight-black text-uppercase tracking-widest lh-1">Gestor de Totens</h3>
                <span v-if="currentKioskInfo" class="text-[10px] text-success font-weight-bold d-flex align-center gap-1 mt-1">
                  <v-icon size="10" color="success">mdi-circle</v-icon> Atual: {{ currentKioskInfo.name }}
                </span>
                <span v-else class="text-[10px] text-warning font-weight-bold d-flex align-center gap-1 mt-1">
                  <v-icon size="10" color="warning">mdi-alert-circle</v-icon> Totem não vinculado
                </span>
              </div>
            </div>
            <v-btn icon="mdi-close" variant="text" size="small" color="grey" @click="closeAdminPanel"></v-btn>
          </div>

          <v-tabs v-model="adminTab" color="primary" grow bg-color="transparent" class="border-b border-white-10">
            <v-tab value="list" class="text-caption font-weight-black text-uppercase tracking-widest rounded-0">Dispositivos</v-tab>
            <v-tab value="new" class="text-caption font-weight-black text-uppercase tracking-widest rounded-0" @click="handleNewTabClick">Novo Totem</v-tab>
          </v-tabs>

          <div class="flex-grow-1 overflow-y-auto pa-6 custom-scrollbar">
            <v-window v-model="adminTab" class="bg-transparent" :touch="false">

              <v-window-item value="list">
                <div class="d-flex align-center justify-space-between mb-4">
                  <span class="text-caption text-grey text-uppercase tracking-widest">Mapeamento de Rede</span>
                  <v-btn color="primary" variant="text" size="x-small" @click="fetchAdminData" :loading="loadingAdminData">
                    <v-icon start>mdi-refresh</v-icon> Atualizar
                  </v-btn>
                </div>

                <div v-if="loadingAdminData" class="d-flex justify-center py-8">
                  <v-progress-circular indeterminate color="primary"></v-progress-circular>
                </div>

                <div v-else-if="allKiosks.length === 0" class="text-center py-8 text-grey border border-white-10 rounded-sm bg-black-40">
                  <v-icon size="32" class="mb-2 opacity-50">mdi-database-remove-outline</v-icon>
                  <p class="text-body-2">Nenhum totem cadastrado.</p>
                </div>

                <div v-else class="d-flex flex-column gap-3">
                  <div v-for="k in allKiosks" :key="k.id" class="border border-white-10 rounded-sm pa-4 transition-all" :class="currentKioskInfo?.id === k.id ? 'bg-primary-darken-4 border-primary' : 'bg-black-40 hover-highlight'">
                    <div class="d-flex justify-space-between align-start mb-2">
                      <div>
                        <h4 class="text-body-1 font-weight-black lh-1 mb-1">{{ k.name }}</h4>
                        <span class="text-caption text-grey d-flex align-center gap-1">
                          <v-icon size="12">mdi-store</v-icon> {{ k.stores?.name || 'Sem Loja' }}
                        </span>
                      </div>
                      <v-chip size="x-small" :color="k.allowed_ip ? 'success' : 'warning'" variant="flat" class="font-weight-bold rounded-sm text-uppercase">
                        {{ k.allowed_ip ? 'Operante' : 'Pendente' }}
                      </v-chip>
                    </div>

                    <div class="d-flex align-center justify-space-between mt-4">
                      <span class="text-[10px] font-mono text-grey border border-white-10 px-2 py-1 rounded-sm bg-black">
                        IP: {{ k.allowed_ip || '---.---.---.---' }}
                      </span>

                      <div class="d-flex gap-2">
                        <v-btn v-if="currentKioskInfo?.id !== k.id" color="primary" variant="flat" size="small" class="rounded-sm font-weight-bold" @click="syncTabletToKiosk(k)" :loading="syncingId === k.id">
                          <v-icon start>mdi-sync</v-icon> Vincular
                        </v-btn>
                        <v-btn v-else color="error" variant="tonal" size="small" class="rounded-sm font-weight-bold" @click="unbindCurrentTablet">
                          Desvincular
                        </v-btn>
                        <v-btn icon="mdi-delete" variant="text" color="error" size="small" class="rounded-sm" @click="deleteKiosk(k.id)"></v-btn>
                      </div>
                    </div>
                  </div>
                </div>
              </v-window-item>

              <v-window-item value="new">
                <v-form @submit.prevent="createNewKiosk" v-model="isNewKioskValid">

                  <div class="text-caption text-primary text-uppercase tracking-widest mb-4 font-weight-bold d-flex align-center gap-2">
                    <v-icon size="16">mdi-information-outline</v-icon> Informações Básicas
                  </div>

                  <v-select
                    v-model="newKiosk.store_id"
                    :items="stores"
                    item-title="name"
                    item-value="id"
                    label="Loja de Destino (Store)"
                    variant="outlined"
                    bg-color="#121212"
                    color="primary"
                    density="comfortable"
                    class="mb-3 rounded-sm custom-dark-select"
                    :rules="[v => !!v || 'Obrigatório']"
                    :menu-props="{ contentClass: 'dark-dropdown-menu' }"
                  ></v-select>

                  <v-text-field
                    v-model="newKiosk.name"
                    label="Nome do Totem (Ex: Recepção Térreo)"
                    variant="outlined"
                    bg-color="#121212"
                    color="primary"
                    density="comfortable"
                    class="mb-6 rounded-sm custom-dark-input"
                    :rules="[v => !!v || 'Obrigatório']"
                  ></v-text-field>

                  <div class="text-caption text-primary text-uppercase tracking-widest mb-4 font-weight-bold d-flex align-center gap-2">
                    <v-icon size="16">mdi-network-outline</v-icon> Restrição de Rede (IP)
                  </div>

                  <div class="d-flex gap-2 mb-6">
                    <v-text-field
                      v-model="newKiosk.allowed_ip"
                      label="IP Público Autorizado"
                      variant="outlined"
                      bg-color="#121212"
                      color="primary"
                      density="comfortable"
                      class="rounded-sm flex-grow-1 custom-dark-input"
                      hide-details
                      :rules="[v => !!v || 'Obrigatório']"
                    ></v-text-field>
                    <v-btn color="secondary" height="48" class="rounded-sm" @click="fetchCurrentIP" :loading="loadingIP" title="Puxar IP Atual">
                      <v-icon>mdi-crosshairs-gps</v-icon>
                    </v-btn>
                  </div>

                  <div class="text-caption text-primary text-uppercase tracking-widest mb-4 font-weight-bold d-flex align-center gap-2">
                    <v-icon size="16">mdi-map-marker-radius</v-icon> Âncora Geográfica (GPS Real)
                  </div>

                  <div class="d-flex gap-2 mb-3">
                    <v-text-field
                      v-model="newKiosk.address"
                      label="Endereço (Busca)"
                      variant="outlined"
                      bg-color="#121212"
                      color="primary"
                      density="comfortable"
                      class="rounded-sm flex-grow-1 custom-dark-input"
                      hide-details
                      placeholder="Rua, Número, Cidade"
                      @keyup.enter="searchAddress"
                    ></v-text-field>
                    <v-btn color="primary" height="48" class="rounded-sm" @click="searchAddress" :loading="loadingGeocode">
                      <v-icon>mdi-magnify</v-icon>
                    </v-btn>
                  </div>

                  <div class="d-flex gap-2 mb-4 align-center">
                    <v-text-field v-model="newKiosk.lat" label="Lat" variant="outlined" bg-color="#121212" color="primary" density="compact" hide-details class="rounded-sm custom-dark-input" readonly></v-text-field>
                    <v-text-field v-model="newKiosk.lng" label="Lng" variant="outlined" bg-color="#121212" color="primary" density="compact" hide-details class="rounded-sm custom-dark-input" readonly></v-text-field>
                    <v-btn color="secondary" variant="tonal" height="40" class="rounded-sm" @click="fetchCurrentGPS" :loading="loadingGPS" title="Pegar GPS do Tablet">
                      <v-icon>mdi-crosshairs</v-icon>
                    </v-btn>
                  </div>

                  <div class="text-caption text-white opacity-70 mb-2">Raio de Tolerância (Metros)</div>
                  <v-slider
                    v-model="newKiosk.max_radius_meters"
                    :min="10"
                    :max="500"
                    :step="10"
                    color="primary"
                    track-color="white-10"
                    class="mb-4"
                  >
                    <template v-slot:append>
                      <v-text-field
                        v-model="newKiosk.max_radius_meters"
                        type="number"
                        style="width: 80px"
                        density="compact"
                        hide-details
                        variant="outlined"
                        bg-color="#121212"
                        class="rounded-sm custom-dark-input"
                      ></v-text-field>
                    </template>
                  </v-slider>

                  <div class="map-wrapper-container mb-6 position-relative" :class="{ 'is-fullscreen': isMapFullscreen }">
                    <div id="kiosk-real-map" class="w-100 h-100 border border-white-10 rounded-sm bg-black z-10"></div>

                    <div v-if="!mapLoaded" class="position-absolute top-0 left-0 w-100 h-100 d-flex flex-column align-center justify-center bg-black-80 backdrop-blur-md z-20">
                      <v-progress-circular indeterminate color="primary"></v-progress-circular>
                      <span class="text-caption text-grey mt-2">Carregando Motor de Mapas...</span>
                    </div>

                    <v-btn
                      v-if="mapLoaded"
                      icon
                      variant="flat"
                      color="white"
                      size="small"
                      class="position-absolute top-0 right-0 ma-2 z-[999] border border-white-10 shadow-sm"
                      @click="toggleMapFullscreen"
                    >
                      <v-icon color="black">{{ isMapFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
                    </v-btn>

                    <div v-if="mapLoaded" class="position-absolute top-50 left-50 translate-middle z-[500] pointer-events-none d-flex flex-column align-center justify-center">
                      <v-icon color="primary" size="32" class="drop-shadow">mdi-crosshairs</v-icon>
                    </div>
                  </div>

                  <v-btn type="submit" color="success" block size="large" class="font-weight-black rounded-sm tracking-widest text-uppercase" :disabled="!isNewKioskValid || !newKiosk.lat || !newKiosk.allowed_ip" :loading="savingNewKiosk">
                    <v-icon start>mdi-content-save-all</v-icon> Salvar Totem
                  </v-btn>
                </v-form>
              </v-window-item>
            </v-window>
          </div>
        </div>
      </v-navigation-drawer>

      <audio ref="successSound" src="https://cdn.shopify.com/s/files/1/0661/4574/6991/files/success-1-6297.mp3?v=1710960000" preload="auto"></audio>
      <audio ref="errorSound" src="https://cdn.shopify.com/s/files/1/0661/4574/6991/files/error-call-to-attention-129258.mp3?v=1710960000" preload="auto"></audio>
    </div>
  </v-theme-provider>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, reactive, nextTick } from 'vue';
import { supabase } from '@/api/supabase';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import * as faceapi from 'face-api.js';

// --- ESTADOS PRINCIPAIS DE FLUXO ---
type ViewState = 'CHECKING' | 'UNCONFIGURED' | 'RUNNING' | 'DENIED';
const viewState = ref<ViewState>('CHECKING');
const accessErrorMessage = ref('');
const loadingText = ref('Iniciando...');

// --- DADOS DO BACKEND ---
const currentKioskInfo = ref<any>(null);

// --- ADMIN E GESTÃO ---
let clickCount = 0;
let clickTimer: any = null;
const showPinPrompt = ref(false);
const adminPinInput = ref('');
const showAdminDrawer = ref(false);
const adminTab = ref('list');

const allKiosks = ref<any[]>([]);
const stores = ref<any[]>([]);
const loadingAdminData = ref(false);
const syncingId = ref<string | null>(null);

// Form state
const isNewKioskValid = ref(false);
const savingNewKiosk = ref(false);
const loadingGeocode = ref(false);
const loadingIP = ref(false);
const loadingGPS = ref(false);

const newKiosk = reactive({
  store_id: null,
  name: '',
  max_radius_meters: 50,
  allowed_ip: '',
  address: '',
  lat: -23.5505 as number | null, // SP Default
  lng: -46.6333 as number | null
});

// --- LEAFLET REAL MAP ENGINE ---
const mapLoaded = ref(false);
const isMapFullscreen = ref(false);
let leafletMap: any = null;
let leafletCircle: any = null;

// Carrega Leaflet via CDN para não precisar instalar via npm
const injectLeaflet = (): Promise<any> => {
  return new Promise((resolve) => {
    if ((window as any).L) return resolve((window as any).L);
    const css = document.createElement('link');
    css.rel = 'stylesheet';
    css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(css);

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => resolve((window as any).L);
    document.head.appendChild(script);
  });
};

const initializeRealMap = async () => {
  const L = await injectLeaflet();
  mapLoaded.value = true;
  await nextTick();

  if (leafletMap) {
    leafletMap.remove(); // Reseta se já existir
  }

  const container = document.getElementById('kiosk-real-map');
  if (!container) return;

  const lat = newKiosk.lat || -23.5505;
  const lng = newKiosk.lng || -46.6333;

  leafletMap = L.map('kiosk-real-map', {
    zoomControl: false, // Esconde botões de zoom feios
    attributionControl: false
  }).setView([lat, lng], 16);

  // Tema Dark via classe CSS que aplica filtro no mapa
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    className: 'dark-map-tiles'
  }).addTo(leafletMap);

  leafletCircle = L.circle([lat, lng], {
    color: '#1976D2',
    fillColor: '#1976D2',
    fillOpacity: 0.3,
    radius: newKiosk.max_radius_meters,
    weight: 2
  }).addTo(leafletMap);

  // Evento principal: Ao arrastar o mapa, o centro define a nova coordenada do totem
  leafletMap.on('move', () => {
    const center = leafletMap.getCenter();
    newKiosk.lat = center.lat;
    newKiosk.lng = center.lng;
    leafletCircle.setLatLng(center);
  });
};

const toggleMapFullscreen = () => {
  isMapFullscreen.value = !isMapFullscreen.value;
  // Leaflet precisa re-calcular o tamanho quando o container muda via CSS
  setTimeout(() => {
    if (leafletMap) leafletMap.invalidateSize();
  }, 400);
};

// Observa mudanças no raio do slider e atualiza o mapa visualmente
watch(() => newKiosk.max_radius_meters, (newVal) => {
  if (leafletCircle) {
    leafletCircle.setRadius(newVal);
  }
});

const handleNewTabClick = async () => {
  if (!mapLoaded.value) {
    setTimeout(initializeRealMap, 300); // Dá um tempo pro painel abrir e o DOM renderizar
  } else {
    setTimeout(() => leafletMap?.invalidateSize(), 300);
  }
};

// --- DOM & MIDIA ---
const videoRef = ref<HTMLVideoElement | null>(null);
const blurVideoRef = ref<HTMLVideoElement | null>(null);
const canvasRef = ref<HTMLCanvasElement | null>(null);
const successSound = ref<HTMLAudioElement | null>(null);
const errorSound = ref<HTMLAudioElement | null>(null);

const currentTime = ref('');
const currentDate = ref('');
let clockInterval: any;

// --- ESTADOS DE IA E SCANNER ---
const isInitializing = ref(false);
const showSuccessFlash = ref(false);
const showSpoofFlash = ref(false);
let videoStream: MediaStream | null = null;
let detectionInterval: any;
let faceMatcher: faceapi.FaceMatcher | null = null;

const livenessPending = ref(false);
const livenessProgress = ref(0);
let currentLivenessCandidateId = '';
const currentLivenessName = ref('');
let livenessBuffer: { ear: number, mar: number }[] = [];
const LIVENESS_FRAMES = 15;
const MIN_VARIANCE_THRESHOLD = 0.010;
const cooldownTray = reactive({ show: false, employeeId: '', employeeName: '', punches: [] as string[], nextAllowedTime: '', isLimitReached: false });
let trayTimeout: any;
type ScanStatus = { type: 'success' | 'error' | 'warning', title: string, message: string, color: string, icon: string } | null;
const currentScanStatus = ref<ScanStatus>(null);
let statusTimeout: any;
const recentLogs = ref<any[]>([]);

// ==========================================
// 1. FLUXO INICIAL E IDENTIDADE
// ==========================================
const checkInitialState = async () => {
  viewState.value = 'CHECKING';
  loadingText.value = 'Acessando Rede...';

  const storedKioskId = localStorage.getItem('mj_kiosk_id');
  if (!storedKioskId) {
    viewState.value = 'UNCONFIGURED';
    return;
  }

  try {
    const { data: kiosk, error } = await supabase
      .from('time_tracking_kiosks')
      .select('*, stores(name)')
      .eq('id', storedKioskId)
      .maybeSingle();

    if (error || !kiosk || !kiosk.active) {
      localStorage.removeItem('mj_kiosk_id');
      viewState.value = 'UNCONFIGURED';
      return;
    }

    currentKioskInfo.value = kiosk;
    if (!kiosk.allowed_ip || !kiosk.lat) {
      viewState.value = 'UNCONFIGURED';
    } else {
      await verifyAccess();
    }
  } catch (err) {
    viewState.value = 'UNCONFIGURED';
  }
};

// ==========================================
// 2. ADMINISTRAÇÃO (DRAWER LOGIC)
// ==========================================
const handleAdminClick = () => {
  clickCount++;
  if (clickTimer) clearTimeout(clickTimer);
  if (clickCount >= 5) {
    showPinPrompt.value = true;
    clickCount = 0;
  } else {
    clickTimer = setTimeout(() => { clickCount = 0; }, 2000);
  }
};

const validatePin = () => {
  if (adminPinInput.value === 'mjadmin') {
    showPinPrompt.value = false;
    adminPinInput.value = '';
    openAdminPanel();
  } else {
    alert("Senha Incorreta.");
    adminPinInput.value = '';
  }
};

const openAdminPanel = async () => {
  if (videoStream) videoStream.getTracks().forEach(t => t.stop());
  showAdminDrawer.value = true;
  await fetchAdminData();

  if (adminTab.value === 'new') {
    setTimeout(initializeRealMap, 300);
  }
};

const closeAdminPanel = () => {
  showAdminDrawer.value = false;
  isMapFullscreen.value = false;
  if (leafletMap) {
    leafletMap.remove();
    leafletMap = null;
    mapLoaded.value = false;
  }
  checkInitialState();
};

const fetchAdminData = async () => {
  loadingAdminData.value = true;
  try {
    const [kiosksRes, storesRes] = await Promise.all([
      supabase.from('time_tracking_kiosks').select('*, stores(name)').order('created_at', { ascending: false }),
      supabase.from('stores').select('id, name').eq('active', true)
    ]);
    if (kiosksRes.data) allKiosks.value = kiosksRes.data;
    if (storesRes.data) stores.value = storesRes.data;
  } catch(e) {
    console.error("Erro ao carregar dados admin:", e);
  } finally {
    loadingAdminData.value = false;
  }
};

const fetchCurrentIP = async () => {
  loadingIP.value = true;
  try {
    const res = await fetch('https://api.ipify.org?format=json');
    const data = await res.json();
    newKiosk.allowed_ip = data.ip;
  } catch(e) {
    alert("Falha ao puxar IP.");
  } finally {
    loadingIP.value = false;
  }
};

const fetchCurrentGPS = () => {
  loadingGPS.value = true;
  if (!navigator.geolocation) {
    alert("Navegador não suporta GPS.");
    loadingGPS.value = false;
    return;
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      newKiosk.lat = pos.coords.latitude;
      newKiosk.lng = pos.coords.longitude;
      if (leafletMap) {
        leafletMap.setView([newKiosk.lat, newKiosk.lng], 17);
        leafletCircle.setLatLng([newKiosk.lat, newKiosk.lng]);
      }
      loadingGPS.value = false;
    },
    (err) => {
      alert("Falha ao ler GPS. Permita no navegador.");
      loadingGPS.value = false;
    },
    { enableHighAccuracy: true, timeout: 10000 }
  );
};

const searchAddress = async () => {
  if (!newKiosk.address) return;
  loadingGeocode.value = true;
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(newKiosk.address)}`);
    const data = await res.json();
    if (data && data.length > 0) {
      newKiosk.lat = parseFloat(data[0].lat);
      newKiosk.lng = parseFloat(data[0].lon);
      if (leafletMap) {
        leafletMap.setView([newKiosk.lat, newKiosk.lng], 16);
        leafletCircle.setLatLng([newKiosk.lat, newKiosk.lng]);
      }
    } else {
      alert("Endereço não encontrado.");
    }
  } catch(e) {
    alert("Erro na busca de endereço.");
  } finally {
    loadingGeocode.value = false;
  }
};

const createNewKiosk = async () => {
  if (!isNewKioskValid.value || !newKiosk.lat || !newKiosk.allowed_ip) return;
  savingNewKiosk.value = true;
  try {
    const { error } = await supabase.from('time_tracking_kiosks').insert([{
      store_id: newKiosk.store_id,
      name: newKiosk.name,
      max_radius_meters: newKiosk.max_radius_meters,
      allowed_ip: newKiosk.allowed_ip,
      lat: newKiosk.lat,
      lng: newKiosk.lng,
      active: true
    }]);

    if (error) throw error;

    newKiosk.name = ''; newKiosk.address = ''; newKiosk.allowed_ip = '';
    adminTab.value = 'list';
    isMapFullscreen.value = false;
    await fetchAdminData();
  } catch (e) {
    alert("Erro ao salvar Totem. Verifique suas regras RLS no Supabase.");
  } finally {
    savingNewKiosk.value = false;
  }
};

const deleteKiosk = async (id: string) => {
  if (!confirm("Deletar identidade deste Totem?")) return;
  try {
    await supabase.from('time_tracking_kiosks').delete().eq('id', id);
    if (currentKioskInfo.value?.id === id) {
      localStorage.removeItem('mj_kiosk_id');
      currentKioskInfo.value = null;
    }
    await fetchAdminData();
  } catch(e) { alert("Erro ao deletar."); }
};

const syncTabletToKiosk = async (kioskTarget: any) => {
  syncingId.value = kioskTarget.id;
  try {
    let ip = '';
    try {
      const res = await fetch('https://api.ipify.org?format=json');
      const data = await res.json();
      ip = data.ip;
    } catch(e) { throw new Error("Falha no IP."); }

    if (!navigator.geolocation) throw new Error("Sem sensor de localização.");

    const position = await new Promise<GeolocationPosition>((resolve, reject) => {
       navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000 });
    });

    const { error } = await supabase.from('time_tracking_kiosks').update({
      allowed_ip: ip, lat: position.coords.latitude, lng: position.coords.longitude
    }).eq('id', kioskTarget.id);

    if (error) throw error;

    localStorage.setItem('mj_kiosk_id', kioskTarget.id);
    currentKioskInfo.value = { ...kioskTarget, allowed_ip: ip, lat: position.coords.latitude, lng: position.coords.longitude };
    await fetchAdminData();
  } catch (err: any) { alert(err.message || "Falha na sincronização."); }
  finally { syncingId.value = null; }
};

const unbindCurrentTablet = () => {
  if(confirm("Desvincular rede atual?")) {
    localStorage.removeItem('mj_kiosk_id');
    currentKioskInfo.value = null;
    fetchAdminData();
  }
};

// ==========================================
// 3. VALIDAÇÃO DE PERÍMETRO
// ==========================================
const getDistanceFromLatLonInM = (lat1: number, lon1: number, lat2: number, lon2: number) => {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return Math.round(R * c);
};

const verifyAccess = async () => {
  viewState.value = 'CHECKING';
  loadingText.value = 'Analisando Coordenadas Geográficas...';

  const kiosk = currentKioskInfo.value;
  if (!kiosk || !kiosk.allowed_ip) { viewState.value = 'UNCONFIGURED'; return; }

  let isIpValid = false; let isGpsValid = false; let ipError = ''; let gpsError = '';

  try {
    const res = await fetch('https://api.ipify.org?format=json');
    const ipData = await res.json();
    if (ipData.ip === kiosk.allowed_ip) isIpValid = true;
    else ipError = `IP Externo recusado. `;
  } catch(e) { ipError = 'Falha no ping de IP. '; }

  if (!isIpValid && navigator.geolocation) {
     try {
       const position = await new Promise<GeolocationPosition>((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 });
       });
       const dist = getDistanceFromLatLonInM(position.coords.latitude, position.coords.longitude, kiosk.lat, kiosk.lng);
       if (dist <= kiosk.max_radius_meters) isGpsValid = true;
       else gpsError = `Distância: ${dist}m (Max: ${kiosk.max_radius_meters}m).`;
     } catch (err) { gpsError = 'Sinal de GPS Inoperante.'; }
  }

  if (isIpValid || isGpsValid) {
     viewState.value = 'RUNNING';
     await initializeSystem();
  } else {
     viewState.value = 'DENIED';
     accessErrorMessage.value = ipError + (ipError && gpsError ? ' | ' : '') + gpsError;
  }
};

// ==========================================
// 4. MOTOR BIOMÉTRICO (FACEAPI)
// ==========================================
const initializeSystem = async () => {
  isInitializing.value = true;
  try {
    loadingText.value = 'Carregando IA Neural...';
    const MODEL_URL = 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights';

    await Promise.all([
      faceapi.nets.ssdMobilenetv1.loadFromUri(MODEL_URL),
      faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL),
      faceapi.nets.faceRecognitionNet.loadFromUri(MODEL_URL)
    ]);

    await buildFaceMatcher();

    videoStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: { ideal: 1280 }, height: { ideal: 720 } } });

    if (videoRef.value && blurVideoRef.value) {
      videoRef.value.srcObject = videoStream;
      blurVideoRef.value.srcObject = videoStream;
    }

    videoRef.value?.addEventListener('play', () => {
      isInitializing.value = false;
      setTimeout(startFaceTracking, 500);
    });
  } catch (error) {
    showStatus('error', 'Falha Crítica', 'Câmera inacessível ou IA corrompida.', 'error', 'mdi-alert-octagon');
  }
};

const buildFaceMatcher = async () => {
  const { data: employees } = await supabase.from('employees_mj').select('id, nome, face_descriptors').eq('status', 'ativo').not('face_descriptors', 'is', null);
  if (!employees || employees.length === 0) return;

  const labeledDescriptors: faceapi.LabeledFaceDescriptors[] = [];
  for (const emp of employees) {
    if (emp.face_descriptors && Array.isArray(emp.face_descriptors)) {
      const descriptorsList = emp.face_descriptors.map((bio: any) => {
         if(bio.descriptor && Array.isArray(bio.descriptor)) return new Float32Array(bio.descriptor);
         return null;
      }).filter((d: any) => d !== null);

      if (descriptorsList.length > 0) {
        labeledDescriptors.push(new faceapi.LabeledFaceDescriptors(JSON.stringify({ id: emp.id, name: emp.nome, avatar: null }), descriptorsList));
      }
    }
  }
  if (labeledDescriptors.length > 0) faceMatcher = new faceapi.FaceMatcher(labeledDescriptors, 0.45);
};

const calculateEAR = (eyePoints: faceapi.Point[]) => {
  const vertical1 = Math.hypot(eyePoints[1].x - eyePoints[5].x, eyePoints[1].y - eyePoints[5].y);
  const vertical2 = Math.hypot(eyePoints[2].x - eyePoints[4].x, eyePoints[2].y - eyePoints[4].y);
  const horizontal = Math.hypot(eyePoints[0].x - eyePoints[3].x, eyePoints[0].y - eyePoints[3].y);
  return (vertical1 + vertical2) / (2.0 * horizontal);
};
const calculateMAR = (mouthPoints: faceapi.Point[]) => {
  const height = Math.hypot(mouthPoints[3].x - mouthPoints[9].x, mouthPoints[3].y - mouthPoints[9].y);
  const width = Math.hypot(mouthPoints[0].x - mouthPoints[6].x, mouthPoints[0].y - mouthPoints[6].y);
  return height / (width === 0 ? 1 : width);
};

const startFaceTracking = () => {
  if (!videoRef.value || !canvasRef.value || viewState.value !== 'RUNNING') return;
  const displaySize = { width: videoRef.value.videoWidth || 1280, height: videoRef.value.videoHeight || 720 };
  faceapi.matchDimensions(canvasRef.value, displaySize);

  let isProcessingFrame = false;
  let emptyFramesCount = 0;

  detectionInterval = setInterval(async () => {
    if (isProcessingFrame || !faceMatcher || isInitializing.value || viewState.value !== 'RUNNING') return;
    isProcessingFrame = true;

    try {
      const detection = await faceapi.detectSingleFace(videoRef.value!).withFaceLandmarks().withFaceDescriptor();
      const ctx = canvasRef.value!.getContext('2d');
      ctx?.clearRect(0, 0, displaySize.width, displaySize.height);

      if (detection) {
        emptyFramesCount = 0;
        const resizedDetection = faceapi.resizeResults(detection, displaySize);
        let boxColor = 'rgba(0, 255, 255, 0.8)';
        let boxLabel = 'Autenticando Vetores...';

        const match = faceMatcher.findBestMatch(detection.descriptor);

        if (match.label !== 'unknown') {
           const empData = JSON.parse(match.label);

           if (cooldownTray.show && cooldownTray.employeeId === empData.id) {
               boxColor = cooldownTray.isLimitReached ? 'rgba(244, 67, 54, 1)' : 'rgba(251, 140, 0, 1)';
               boxLabel = cooldownTray.isLimitReached ? 'Limite Diário Atingido' : 'Trava de Tempo Ativa';
           } else {
               if (currentLivenessCandidateId !== empData.id) {
                  currentLivenessCandidateId = empData.id;
                  currentLivenessName.value = empData.name.split(' ')[0];
                  livenessBuffer = [];
                  livenessPending.value = true;
                  livenessProgress.value = 0;
                  boxColor = 'rgba(251, 140, 0, 1)';
                  boxLabel = `Identificado: ${currentLivenessName.value}`;

               } else if (livenessBuffer.length < LIVENESS_FRAMES) {
                  boxColor = 'rgba(251, 140, 0, 1)';
                  boxLabel = 'Análise Vital em Curso...';
                  const leftEye = resizedDetection.landmarks.getLeftEye();
                  const rightEye = resizedDetection.landmarks.getRightEye();
                  const mouth = resizedDetection.landmarks.getMouth();
                  livenessBuffer.push({ ear: (calculateEAR(leftEye) + calculateEAR(rightEye))/2, mar: calculateMAR(mouth) });
                  livenessProgress.value = (livenessBuffer.length / LIVENESS_FRAMES) * 100;
               } else if (livenessBuffer.length === LIVENESS_FRAMES) {
                  const earDiff = Math.max(...livenessBuffer.map(b=>b.ear)) - Math.min(...livenessBuffer.map(b=>b.ear));
                  const marDiff = Math.max(...livenessBuffer.map(b=>b.mar)) - Math.min(...livenessBuffer.map(b=>b.mar));

                  if (earDiff < MIN_VARIANCE_THRESHOLD && marDiff < MIN_VARIANCE_THRESHOLD) {
                     livenessPending.value = false;
                     showSpoofFlash.value = true;
                     if(errorSound.value){ errorSound.value.currentTime=0; errorSound.value.play().catch(()=>{}); }
                     setTimeout(() => showSpoofFlash.value = false, 2500);
                     currentLivenessCandidateId = 'BLOCKED_SPOOF';
                     setTimeout(() => currentLivenessCandidateId = '', 4000);
                  } else {
                     boxColor = 'rgba(76, 175, 80, 1)';
                     boxLabel = 'Sinais Vitais Confirmados';
                     livenessPending.value = false;
                     await handleSuccessfulMatch(match.label);
                     currentLivenessCandidateId = 'LOCKED';
                     setTimeout(() => currentLivenessCandidateId = '', 3000);
                  }
               }
           }
        } else {
           livenessPending.value = false;
           boxColor = 'rgba(244, 67, 54, 0.8)';
           boxLabel = 'Vetor Desconhecido';
           if (!currentScanStatus.value) showStatus('warning', 'Perfil Inexistente', 'Assinatura não reconhecida.', 'error', 'mdi-account-question');
        }
        new faceapi.draw.DrawBox(resizedDetection.detection.box, { label: boxLabel, lineWidth: 3, boxColor }).draw(canvasRef.value!);
      } else {
        if (++emptyFramesCount > 5) livenessPending.value = false;
      }
    } catch(e) {} finally { isProcessingFrame = false; }
  }, 100);
};

const handleSuccessfulMatch = async (labelDataString: string) => {
  if (cooldownTray.show || showSuccessFlash.value || showSpoofFlash.value) return;

  const empData = JSON.parse(labelDataString);
  const now = new Date();
  const dateStr = format(now, 'yyyy-MM-dd');
  const timeStr = format(now, 'HH:mm');

  let todayPunches: string[] = [];
  let logId: number | null = null;

  const { data: todayLog } = await supabase.from('time_tracking_logs').select('*').eq('employee_id', empData.id).eq('date', dateStr).maybeSingle();
  if (todayLog) {
     logId = todayLog.id;
     todayPunches = todayLog.punches || [todayLog.in1, todayLog.out1, todayLog.in2, todayLog.out2].filter(Boolean);
  }

  const { data: set } = await supabase.from('time_tracking_settings').select('kiosk_cooldown_minutes').limit(1).maybeSingle();
  const cooldownMin = set?.kiosk_cooldown_minutes || 30;

  if (todayPunches.length >= 4) {
      if (!cooldownTray.show) {
         cooldownTray.employeeId = empData.id;
         cooldownTray.employeeName = empData.name;
         cooldownTray.punches = todayPunches;
         cooldownTray.isLimitReached = true;
         cooldownTray.show = true;
         if (trayTimeout) clearTimeout(trayTimeout);
         trayTimeout = setTimeout(() => cooldownTray.show = false, 10000);
      }
      showStatus('error', 'Limite Atingido', 'Você já registrou 4 pontos hoje.', 'error', 'mdi-cancel');
      return;
  }

  if (todayPunches.length > 0) {
     const lastPunchDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), ...todayPunches[todayPunches.length - 1].split(':').map(Number));
     if ((now.getTime() - lastPunchDate.getTime()) / 60000 < cooldownMin) {
        if (!cooldownTray.show) {
           cooldownTray.employeeId = empData.id;
           cooldownTray.employeeName = empData.name;
           cooldownTray.punches = todayPunches;
           cooldownTray.isLimitReached = false;
           cooldownTray.nextAllowedTime = format(new Date(lastPunchDate.getTime() + (cooldownMin * 60000)), 'HH:mm');
           cooldownTray.show = true;
           if (errorSound.value) { errorSound.value.currentTime=0; errorSound.value.play().catch(()=>{}); }
           if (trayTimeout) clearTimeout(trayTimeout);
           trayTimeout = setTimeout(() => cooldownTray.show = false, 10000);
        }
        return;
     }
  }

  if (successSound.value) { successSound.value.currentTime=0; successSound.value.play().catch(()=>{}); }
  showSuccessFlash.value = true;
  setTimeout(() => showSuccessFlash.value = false, 1800);
  showStatus('success', 'Registro Firmado', `${empData.name} - ${timeStr}`, 'success', 'mdi-check-decagram');

  recentLogs.value.unshift({ id: crypto.randomUUID(), name: empData.name, avatar: empData.avatar, time: timeStr });
  if (recentLogs.value.length > 8) recentLogs.value.pop();

  const updatedPunches = [...todayPunches, timeStr].sort();
  const payload: any = {
     employee_id: empData.id, date: dateStr, punches: updatedPunches,
     in1: updatedPunches[0] || null, out1: updatedPunches[1] || null,
     in2: updatedPunches[2] || null, out2: updatedPunches[3] || null,
     status: 'Via Kiosk'
  };

  const canvas = document.createElement('canvas'); canvas.width = 640; canvas.height = 480;
  canvas.getContext('2d')?.drawImage(videoRef.value!, 0, 0, 640, 480);
  const photo = canvas.toDataURL('image/jpeg', 0.5);
  payload.punch_photos = [...(todayLog?.punch_photos || []), { time: timeStr, photo }];

  if (logId) await supabase.from('time_tracking_logs').update(payload).eq('id', logId);
  else await supabase.from('time_tracking_logs').insert([payload]);
};

const showStatus = (type: any, title: string, message: string, color: string, icon: string) => {
  if (statusTimeout) clearTimeout(statusTimeout);
  currentScanStatus.value = { type, title, message, color, icon };
  statusTimeout = setTimeout(() => currentScanStatus.value = null, 4000);
};

const updateClock = () => {
  const now = new Date();
  currentTime.value = format(now, 'HH:mm:ss');
  currentDate.value = format(now, "EEEE, dd 'de' MMMM", { locale: ptBR });
};

onMounted(() => {
  updateClock();
  clockInterval = setInterval(updateClock, 1000);
  checkInitialState();
});

onUnmounted(() => {
  clearInterval(clockInterval);
  clearInterval(detectionInterval);
  clearTimeout(statusTimeout);
  clearTimeout(trayTimeout);
  if (videoStream) videoStream.getTracks().forEach(t => t.stop());
  if (leafletMap) leafletMap.remove();
});

const statusClass = computed(() => {
  if (showSuccessFlash.value) return 'border-success';
  if (showSpoofFlash.value) return 'border-error';
  if (livenessPending.value) return 'border-warning';
  if (!currentScanStatus.value) return 'border-white-20';
  return `border-${currentScanStatus.value.color}`;
});
const statusBorderClass = computed(() => currentScanStatus.value ? `border-${currentScanStatus.value.color} border-opacity-50` : '');
</script>

<style lang="scss">
/* FORÇA TOTAL GLOBAL PARA O MENU DO V-SELECT NÃO FICAR BRANCO */
.dark-dropdown-menu .v-list {
  background-color: #1a1a20 !important;
  color: #ffffff !important;
}
.dark-dropdown-menu .v-list-item:hover {
  background-color: rgba(255, 255, 255, 0.08) !important;
}
</style>

<style scoped lang="scss">
/* --- ESTILOS GERAIS --- */
.bg-black-80 { background-color: rgba(0, 0, 0, 0.85); backdrop-filter: blur(10px); }
.bg-black-40 { background-color: rgba(0, 0, 0, 0.4); }
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-white-20 { border-color: rgba(255,255,255,0.2) !important; }
.border-warning { border: 1px solid rgba(var(--v-theme-warning), 0.6) !important; }
.border-error { border: 1px solid rgba(var(--v-theme-error), 0.6) !important; }
.text-shadow-glow { text-shadow: 0 0 20px rgba(255, 255, 255, 0.5), 0 0 40px rgba(var(--v-theme-primary), 0.4); }
.text-shadow { text-shadow: 0 2px 8px rgba(0,0,0,0.9); }
.letter-spacing-2 { letter-spacing: 2px; }
.lh-1 { line-height: 1.1; }
.user-select-none { user-select: none; }
.cursor-pointer { cursor: pointer; }
.transition-all { transition: all 0.3s ease; }
.rounded-sm { border-radius: 4px !important; }

/* MAPA REAL LEAFLET CSS */
.map-wrapper-container {
  height: 240px;
  transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
  overflow: hidden;
  border-radius: 4px;
}
.map-wrapper-container.is-fullscreen {
  position: fixed !important;
  top: 0; left: 0;
  width: 100vw !important;
  height: 100vh !important;
  z-index: 99999;
  border-radius: 0;
  margin: 0 !important;
}
.drop-shadow { filter: drop-shadow(0 4px 6px rgba(0,0,0,0.8)); }
:deep(.dark-map-tiles) {
  filter: invert(100%) hue-rotate(180deg) brightness(85%) contrast(110%);
}

/* SCROLLBAR INVISÍVEL ELEGANTE */
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.3); }

/* ANIMAÇÃO DE FUNDO KIOSK */
.kiosk-background { z-index: 1; overflow: hidden; }
.glow-orb { position: absolute; border-radius: 50%; filter: blur(100px); opacity: 0.15; animation: floatOrb 20s infinite alternate ease-in-out; }
.primary-glow { width: 60vw; height: 60vw; background: rgb(var(--v-theme-primary)); top: -20%; left: -10%; }
.secondary-glow { width: 50vw; height: 50vw; background: rgb(var(--v-theme-success)); bottom: -20%; right: -10%; animation-delay: -10s; }
@keyframes floatOrb { 0% { transform: translate(0, 0) scale(1); } 100% { transform: translate(5%, 5%) scale(1.1); } }

/* PAINÉIS DE VIDRO E SOMBRAS */
.glass-panel { background: rgba(20, 20, 25, 0.65); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); }
.shadow-neon-elegant { box-shadow: 0 8px 32px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.1) !important; }
.shadow-neon-warning { box-shadow: 0 0 40px rgba(var(--v-theme-warning), 0.3); }

/* VÍDEO E CANVAS */
.object-contain { object-fit: contain; }
.blur-bg { filter: blur(30px); opacity: 0.5; transform: scale(1.1); object-fit: cover; }
.scanner-hud { background-image: linear-gradient(rgba(25, 118, 210, 0.15) 1px, transparent 1px), linear-gradient(90deg, rgba(25, 118, 210, 0.15) 1px, transparent 1px); background-size: 60px 60px; background-position: center center; }
.scanner-corner { position: absolute; width: 80px; height: 80px; border-style: solid; border-color: rgba(25, 118, 210, 1); box-shadow: 0 0 20px rgba(25, 118, 210, 0.6); transition: all 0.3s ease; }
.top-left { top: 40px; left: 40px; border-width: 6px 0 0 6px; border-top-left-radius: 4px; }
.top-right { top: 40px; right: 40px; border-width: 6px 6px 0 0; border-top-right-radius: 4px; }
.bottom-left { bottom: 40px; left: 40px; border-width: 0 0 6px 6px; border-bottom-left-radius: 4px; }
.bottom-right { bottom: 40px; right: 40px; border-width: 0 6px 6px 0; border-bottom-right-radius: 4px; }
.scan-line { width: 100%; height: 6px; background: linear-gradient(to bottom, transparent, rgba(25, 118, 210, 1) 50%, transparent); box-shadow: 0 0 25px rgba(25, 118, 210, 1), 0 0 50px rgba(25, 118, 210, 0.6); position: absolute; top: 0; animation: scanAnim 2.5s ease-in-out infinite; }
.scan-line-warning { background: linear-gradient(to bottom, transparent, rgba(var(--v-theme-warning), 1) 50%, transparent); box-shadow: 0 0 25px rgba(var(--v-theme-warning), 1), 0 0 50px rgba(var(--v-theme-warning), 0.6); animation-duration: 1.5s; }
@keyframes scanAnim { 0% { top: 5%; opacity: 0; } 10% { opacity: 1; } 90% { opacity: 1; } 100% { top: 95%; opacity: 0; } }

/* FLASH DE SUCESSO/ERRO */
.success-flash { background: radial-gradient(circle, rgba(76, 175, 80, 0.5) 0%, rgba(0, 0, 0, 0.85) 100%) !important; backdrop-filter: blur(8px); }
.error-flash { background: radial-gradient(circle, rgba(244, 67, 54, 0.6) 0%, rgba(0, 0, 0, 0.9) 100%) !important; backdrop-filter: blur(12px); }
.flash-enter-active { animation: flashIn 0.3s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
.flash-leave-active { animation: flashOut 0.6s ease-in forwards; }
@keyframes flashIn { from { opacity: 0; transform: scale(1.1); } to { opacity: 1; transform: scale(1); } }
@keyframes flashOut { from { opacity: 1; } to { opacity: 0; } }

/* ANIMAÇÕES GERAIS */
.pulse-text { animation: pulse 1.5s infinite; }
.pulse-ring { animation: pulseRing 1.5s infinite; }
.shake-anim { animation: shake 0.5s cubic-bezier(.36,.07,.19,.97) both; }
@keyframes pulse { 0% { opacity: 0.7; } 50% { opacity: 1; } 100% { opacity: 0.7; } }
@keyframes pulseRing { 0% { transform: scale(0.9); filter: drop-shadow(0 0 0 rgba(76, 175, 80, 0.7)); } 70% { transform: scale(1.1); filter: drop-shadow(0 0 20px rgba(76, 175, 80, 0)); } 100% { transform: scale(0.9); filter: drop-shadow(0 0 0 rgba(76, 175, 80, 0)); } }
@keyframes shake { 10%, 90% { transform: translate3d(-2px, 0, 0); } 20%, 80% { transform: translate3d(4px, 0, 0); } 30%, 50%, 70% { transform: translate3d(-6px, 0, 0); } 40%, 60% { transform: translate3d(6px, 0, 0); } }

/* TRANSIÇÕES DE COMPONENTES */
.status-slide-enter-active, .status-slide-leave-active { transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1); }
.status-slide-enter-from { opacity: 0; transform: translateY(-20px) scale(0.95); }
.status-slide-leave-to { opacity: 0; transform: translateY(20px) scale(0.95); }
.slide-right-enter-active, .slide-right-leave-active { transition: all 0.5s cubic-bezier(0.2, 0.8, 0.2, 1); }
.slide-right-enter-from { opacity: 0; transform: translateX(50px); }
.slide-right-leave-to { opacity: 0; transform: translateX(50px); }
.log-list-vertical-enter-active, .log-list-vertical-leave-active { transition: all 0.5s ease; }
.log-list-vertical-enter-from { opacity: 0; transform: translateX(-30px); }
.log-list-vertical-leave-to { opacity: 0; transform: translateY(20px); }

/* INTERAÇÕES */
.hover-highlight:hover { background-color: rgba(255,255,255,0.08) !important; border-color: rgba(var(--v-theme-primary), 0.5) !important; }
.admin-trigger:hover { background-color: rgba(255,255,255,0.05); transition: background-color 0.3s; }
</style>
