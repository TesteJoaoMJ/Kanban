<template>
  <div class="view-wrap product-view">
    <div v-if="isLoading" class="loading-state mj-surface mj-border">
      <v-progress-circular indeterminate color="primary" size="48" />
      <p>Carregando detalhes da estampa...</p>
    </div>

    <v-container v-else-if="activeStamp" class="container-xl product-container">
      <div class="product-breadcrumb">
        <v-btn icon variant="tonal" size="small" class="back-btn" @click="router.back()">
          <v-icon>mdi-arrow-left</v-icon>
        </v-btn>
        <span>
          Acervo / {{ activeStamp.catalog_categories?.name || 'Coleção' }} / {{ activeStamp.ref_code }}
        </span>
      </div>

      <div class="product-grid">
        <section class="product-visual-column">

          <div
            class="capture-wrapper mj-surface mj-border"
            :class="[activeTool === 'lasso' ? 'mode-selection' : '', activeTool === 'color' ? 'mode-color' : '']"
            ref="mockupCaptureArea"
            @mousedown="handleMouseDown"
            @mousemove="handleMouseMove"
            @mouseup="handleMouseUp"
            @mouseleave="handleMouseUp"
            @touchstart="handleTouchStart"
            @touchmove="handleTouchMove"
            @touchend="handleMouseUp"
            @wheel.prevent="handleWheel"
          >
            <div class="ps-corner"></div>

            <div class="ps-ruler-h">
              <div class="ruler-track-h" :style="rulerTrackStyleH">
                <div
                  v-for="marker in rulerMarkersH"
                  :key="marker.id"
                  class="ruler-cm-marker-h"
                  :style="{ left: marker.pos }"
                >
                  <span v-if="marker.isMajor" class="marker-text-h">{{ marker.cm }}</span>
                  <div class="marker-line-h" :class="{ 'major': marker.isMajor, 'minor': !marker.isMajor }"></div>
                </div>
              </div>
            </div>

            <div class="ps-ruler-v">
              <div class="ruler-track-v" :style="rulerTrackStyleV">
                <div
                  v-for="marker in rulerMarkersV"
                  :key="marker.id"
                  class="ruler-cm-marker-v"
                  :style="{ top: marker.pos }"
                >
                  <span v-if="marker.isMajor" class="marker-text-v">{{ marker.cm }}</span>
                  <div class="marker-line-v" :class="{ 'major': marker.isMajor, 'minor': !marker.isMajor }"></div>
                </div>
              </div>
            </div>

            <div class="product-visual">

              <div v-if="!selectedMockup" class="grid-overlay" :style="gridStyle"></div>

              <template v-if="selectedMockup">
                <div v-if="selectedMockup.mask_url" class="mockup-mask" :style="maskStyle">
                  <div class="pattern-fill" :style="patternStyle"></div>
                </div>
                <div v-else class="pattern-fill full" :style="patternStyle"></div>
                <img v-if="selectedMockup.base_image_url" :src="selectedMockup.base_image_url" alt="Mockup" class="mockup-base" />
                <img v-if="selectedMockup.shadow_overlay_url" :src="selectedMockup.shadow_overlay_url" alt="Sombra" class="mockup-shadow" />
              </template>

              <template v-else>
                <div class="raw-stamp-fill" :style="rawStampStyle"></div>
              </template>

              <svg v-if="lassoPoints.length > 0 && activeTool === 'lasso'" class="lasso-overlay">
                <polygon :points="lassoPointsString" class="lasso-polygon" />
              </svg>

              <template v-if="lassoPoints.length > 0 && activeTool === 'lasso' && lassoBoundingBox">
                <div class="lasso-ruler-h" :style="{ top: `${lassoBoundingBox.maxY + 10}px`, left: `${lassoBoundingBox.minX}px`, width: `${lassoBoundingBox.w}px` }">
                  <div class="ruler-line-h"></div>
                  <div class="ruler-label-h">{{ formatMeasureString(selectionDim.cmW) }}</div>
                </div>

                <div class="lasso-ruler-v" :style="{ left: `${lassoBoundingBox.maxX + 10}px`, top: `${lassoBoundingBox.minY}px`, height: `${lassoBoundingBox.h}px` }">
                  <div class="ruler-line-v"></div>
                  <div class="ruler-label-v">{{ formatMeasureString(selectionDim.cmH) }}</div>
                </div>
              </template>

              <div v-if="lassoPoints.length > 0 && activeTool === 'lasso'" class="dimensions-tooltip" :style="tooltipStyle">
                <div class="dim-mode-badge" :class="measureMode === 'printed' ? 'bg-primary' : 'bg-purple'">
                  {{ measureMode === 'printed' ? 'Tamanho Impresso' : 'Tamanho Original' }}
                </div>
                <div class="dim-row mt-1">
                  <span>W:</span>
                  <span>{{ selectionDim.pxW }} px</span>
                  <span class="dim-cm">{{ selectionDim.cmW }} cm</span>
                </div>
                <div class="dim-row">
                  <span>H:</span>
                  <span>{{ selectionDim.pxH }} px</span>
                  <span class="dim-cm">{{ selectionDim.cmH }} cm</span>
                </div>
              </div>

              <div v-if="isProcessingColor" class="color-processing-overlay">
                <v-progress-circular indeterminate color="white" size="48" width="4" />
                <span class="mt-2 font-weight-bold text-white text-caption text-uppercase tracking-widest">Aplicando Cor...</span>
              </div>

              <div class="simulation-badge">Escala Visual: {{ (safeZoom * 100).toFixed(0) }}%</div>
            </div>
          </div>

          <div class="modern-tools-panel mt-4">

            <div class="d-flex align-center justify-space-between flex-wrap gap-4">
              <div class="glass-toolbar">
                <v-tooltip location="top" text="Navegar pelo Canvas (V)" content-class="custom-tooltip-dark">
                  <template v-slot:activator="{ props }">
                    <button class="tool-btn" :class="{ 'active': activeTool === 'pan' }" @click="activeTool = 'pan'" v-bind="props">
                      <v-icon size="20">mdi-hand-back-right-outline</v-icon>
                    </button>
                  </template>
                </v-tooltip>

                <v-tooltip location="top" text="Laço de Medição (M)" content-class="custom-tooltip-dark">
                  <template v-slot:activator="{ props }">
                    <button class="tool-btn" :class="{ 'active': activeTool === 'lasso' }" @click="activeTool = 'lasso'" v-bind="props">
                      <v-icon size="20">mdi-lasso</v-icon>
                    </button>
                  </template>
                </v-tooltip>

                <v-tooltip location="top" text="Substituição Mágica de Cor (C)" content-class="custom-tooltip-dark">
                  <template v-slot:activator="{ props }">
                    <button class="tool-btn" :class="{ 'active': activeTool === 'color' }" @click="activeTool = 'color'" v-bind="props">
                      <v-icon size="20">mdi-format-color-fill</v-icon>
                    </button>
                  </template>
                </v-tooltip>

                <div class="toolbar-divider"></div>

                <v-tooltip location="top" text="Como usar as ferramentas?" content-class="custom-tooltip-dark">
                  <template v-slot:activator="{ props }">
                    <button class="tool-btn help-btn" @click="showTutorial = true" v-bind="props">
                      <v-icon size="20">mdi-help-circle-outline</v-icon>
                    </button>
                  </template>
                </v-tooltip>
              </div>

              <div class="zoom-capsule flex-grow-1">
                <button class="zoom-btn" @click="viewerZoom = Math.max(0.3, viewerZoom - 0.1)"><v-icon size="18">mdi-minus</v-icon></button>
                <input v-model.number="viewerZoom" type="range" min="0.3" max="5" step="0.1" class="mj-slider flex-grow-1 mx-2" />
                <button class="zoom-btn" @click="viewerZoom = Math.min(5, viewerZoom + 0.1)"><v-icon size="18">mdi-plus</v-icon></button>
                <div class="zoom-value">{{ (safeZoom * 100).toFixed(0) }}%</div>
              </div>
            </div>

            <div class="tool-options-container mt-4">
              <v-expand-transition>

                <div v-if="activeTool === 'lasso'" class="tool-options-bar mj-surface-2 border rounded-xl pa-4 d-flex align-center justify-space-between flex-wrap gap-4">
                  <div class="d-flex flex-column">
                    <span class="text-caption font-weight-black text-uppercase opacity-70 mb-1">Cálculo de Proporção</span>
                    <v-btn-toggle v-model="measureMode" mandatory density="compact" color="primary" variant="outlined" class="rounded-lg bg-surface">
                      <v-btn value="printed" class="text-caption font-weight-bold px-4">Tamanho Impresso Final</v-btn>
                      <v-btn value="original" class="text-caption font-weight-bold px-4">Tamanho Original da Arte</v-btn>
                    </v-btn-toggle>
                  </div>
                  <div class="text-[11px] font-weight-medium opacity-60 max-w-sm text-right lh-1-2">
                    {{ measureMode === 'printed' ? 'O laço calcula as medidas considerando a expansão/escala atual do tecido.' : 'O laço revela a medida original ignorando o zoom, exibindo o tamanho nativo do elemento.' }}
                  </div>
                </div>

                <div v-else-if="activeTool === 'color'" class="tool-options-bar mj-surface-2 border rounded-xl pa-4 d-flex align-center flex-wrap gap-6">
                  <div class="d-flex align-center gap-3">
                    <div class="color-picker-wrapper elevation-2">
                      <input type="color" v-model="targetReplaceColor" class="color-picker-input cursor-pointer">
                    </div>
                    <div class="d-flex flex-column">
                      <span class="text-caption font-weight-black text-uppercase opacity-70 mb-1 lh-1">Nova Cor Alvo</span>
                      <span class="text-body-2 font-weight-black lh-1">{{ targetReplaceColor.toUpperCase() }}</span>
                    </div>
                  </div>

                  <div class="toolbar-divider-vertical d-none d-sm-block"></div>

                  <div class="d-flex flex-column flex-grow-1" style="min-width: 200px; max-width: 300px;">
                    <div class="d-flex align-center justify-space-between mb-1">
                      <span class="text-caption font-weight-black text-uppercase opacity-70">Tolerância Mágica</span>
                      <span class="text-caption font-weight-bold">{{ colorTolerance }}</span>
                    </div>
                    <input v-model.number="colorTolerance" type="range" min="0" max="150" step="1" class="mj-slider w-100" />
                  </div>

                  <v-spacer class="d-none d-md-block"></v-spacer>

                  <v-btn size="small" variant="flat" color="error" class="font-weight-black rounded-lg px-4" @click="restoreOriginalImage" :disabled="!hasModifiedImage">
                    <v-icon start size="16">mdi-undo-variant</v-icon> Desfazer Cores
                  </v-btn>
                </div>

              </v-expand-transition>
            </div>

          </div>

          <div v-if="availableMockups.length" class="mockup-selector">
            <div class="mockup-selector-title">Visualizar em aplicações</div>
            <div class="mockup-carousel-wrapper">
              <button class="carousel-arrow" @click="scrollMockups('left')">
                <v-icon size="20">mdi-chevron-left</v-icon>
              </button>

              <div class="mockup-list" ref="mockupListRef">
                <button class="mockup-thumb" :class="{ active: !selectedMockup }" @click="selectedMockup = null">
                  <img :src="getOptimizedUrl(activeStamp.main_image_url, 400)" @error="handleImageError" alt="Sem mockup" loading="lazy" />
                </button>

                <button
                  v-for="mock in availableMockups"
                  :key="mock.id"
                  class="mockup-thumb"
                  :class="{ active: selectedMockup?.id === mock.id }"
                  @click="selectedMockup = mock"
                >
                  <img v-if="mock.base_image_url" :src="mock.base_image_url" @error="handleImageError" alt="Mockup" loading="lazy" />
                  <div v-else class="mockup-thumb-fallback">
                    <v-icon>mdi-tshirt-crew-outline</v-icon>
                  </div>
                </button>
              </div>

              <button class="carousel-arrow" @click="scrollMockups('right')">
                <v-icon size="20">mdi-chevron-right</v-icon>
              </button>
            </div>
          </div>
        </section>

        <section class="product-info-column">
          <div class="product-kicker">{{ activeStamp.ref_code }}</div>

          <div class="d-flex justify-space-between align-start mt-4">
            <h1 class="product-title mt-0">{{ activeStamp.title }}</h1>
            <v-btn
              icon
              variant="tonal"
              :color="isFavorite ? 'error' : 'grey'"
              class="ml-4 flex-shrink-0 favorite-btn"
              @click="toggleFavorite"
              :title="isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos'"
            >
              <v-icon size="28">{{ isFavorite ? 'mdi-heart' : 'mdi-heart-outline' }}</v-icon>
            </v-btn>
          </div>

          <p class="product-description">
            {{ activeStamp.description || 'Estampa preparada para apresentação visual de alto padrão, com repetição contínua e leitura clara em diferentes aplicações de produto.' }}
          </p>

          <div class="product-highlights">
            <div class="highlight-card mj-surface mj-border">
              <div class="d-flex align-center justify-center rounded-lg" style="width: 48px; height: 48px; background: rgba(var(--v-theme-primary), 0.1);">
                <v-icon size="28" :color="activeStamp.stamp_type === 'Barrado' ? 'warning' : 'primary'">
                  {{ activeStamp.stamp_type === 'Barrado' ? 'mdi-border-bottom' : 'mdi-texture' }}
                </v-icon>
              </div>
              <div>
                <div class="highlight-label">Tipo de Estampa</div>
                <div class="highlight-value" :class="activeStamp.stamp_type === 'Barrado' ? 'text-warning' : 'text-primary'">
                  {{ activeStamp.stamp_type || 'Corrida' }}
                </div>
              </div>
            </div>
          </div>

          <div class="buy-module mj-surface mj-border">
            <div class="buy-tabs">
              <button
                class="buy-tab"
                :class="{ active: purchaseMode === 'fabric' }"
                @click="setPurchaseMode('fabric')"
              >
                Tecido MJ
              </button>

              <button
                class="buy-tab"
                :class="{ active: purchaseMode === 'own_fabric' }"
                @click="setPurchaseMode('own_fabric')"
              >
                Seu Tecido
              </button>

              <button
                class="buy-tab"
                :class="{ active: purchaseMode === 'pilot' }"
                @click="setPurchaseMode('pilot')"
              >
                Solicitar Piloto
              </button>

              <button
                v-if="allowPsdSales"
                class="buy-tab"
                :class="{ active: purchaseMode === 'digital' }"
                @click="setPurchaseMode('digital')"
              >
                Arquivo PSD
              </button>
            </div>

            <transition name="fade" mode="out-in">
              <div v-if="purchaseMode === 'fabric'" key="fabric" class="buy-content">
                <div class="buy-section-title">1. Escolha a base têxtil MJ</div>

                <div class="custom-select-wrapper" v-if="fabrics.length">
                  <div class="mj-custom-select mj-surface-2 mj-border" @click="isDropdownOpen = !isDropdownOpen" :class="{ 'is-open': isDropdownOpen }">
                    <div class="select-content">
                      <template v-if="selectedFabric">
                        <div class="fabric-info-compact">
                          <span class="fabric-name">{{ selectedFabric.name }}</span>
                          <div class="tier-tags" v-if="getSortedTiers(selectedFabric.price_tiers).length">
                            <span class="tier-tag mj-border">
                              <v-icon size="12" start color="success">mdi-tag-multiple</v-icon>
                              Atacado a partir de {{ getUnit(selectedFabric) === 'kg' ? '40kg' : '150m' }}
                            </span>
                          </div>
                        </div>
                        <div class="fabric-price-tag-compact mj-border">
                          <span class="price-val">R$ {{ formatPrice(selectedFabric.base_price || selectedFabric.price) }}</span>
                          <span class="price-un">/{{ getUnit(selectedFabric) }}</span>
                        </div>
                      </template>
                      <template v-else>
                        <span class="placeholder-text">Selecione uma base para estampar...</span>
                      </template>
                    </div>
                    <v-icon class="chevron-icon" :class="{ 'rotate': isDropdownOpen }">mdi-chevron-down</v-icon>
                  </div>

                  <div v-if="isDropdownOpen" class="dropdown-overlay" @click="isDropdownOpen = false"></div>

                  <transition name="fade-slide">
                    <div v-if="isDropdownOpen" class="mj-custom-dropdown">
                      <div class="dropdown-header">Bases Disponíveis</div>
                      <div class="fabric-options">
                        <div
                          v-for="fabric in fabrics"
                          :key="fabric.id"
                          class="fabric-card"
                          :class="{ active: selectedFabric?.id === fabric.id }"
                          @click="selectFabricItem(fabric)"
                        >
                          <div class="fabric-radio">
                            <div class="radio-inner"></div>
                          </div>
                          <div class="fabric-info">
                            <span class="fabric-name">{{ fabric.name }}</span>
                            <span class="fabric-desc" v-if="fabric.description">{{ fabric.description }}</span>

                            <div class="tier-tags" v-if="getSortedTiers(fabric.price_tiers).length">
                              <span class="tier-tag mj-border">
                                <v-icon size="12" start color="success">mdi-tag-multiple</v-icon>
                                Atacado a partir de {{ getUnit(fabric) === 'kg' ? '40kg' : '150m' }}
                              </span>
                            </div>
                          </div>
                          <div class="fabric-price-tag mj-surface-2 mj-border">
                            <span class="price-val">R$ {{ formatPrice(fabric.base_price || fabric.price) }}</span>
                            <span class="price-un">/{{ getUnit(fabric) }}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </transition>
                </div>

                <div v-else class="empty-fabrics mj-surface-2 mj-border">
                  Nenhum tecido disponível para estampar no momento.
                </div>

                <div class="buy-section-title mt-8">
                  2. Defina a quantidade
                  <span class="text-error text-caption ml-2 font-weight-bold">(Mín. {{ currentMinQty }} {{ getUnitName(selectedFabric) }})</span>
                </div>

                <div class="buy-row">
                  <div class="elegant-qty-wrapper mj-border" :class="{ 'disabled': !selectedFabric }">
                    <button class="eq-btn minus" @click="productQuantity > currentMinQty ? productQuantity -= currentQtyStep : null" :disabled="!selectedFabric || productQuantity <= currentMinQty">
                      <v-icon size="24">mdi-minus</v-icon>
                    </button>
                    <div class="eq-display">
                      <input
                        v-model.number="productQuantity"
                        type="number"
                        :min="currentMinQty"
                        :step="currentQtyStep"
                        class="eq-input"
                        :disabled="!selectedFabric"
                        @blur="validateQuantity"
                      />
                      <span class="eq-unit">{{ getUnitName(selectedFabric) }}</span>
                    </div>
                    <button class="eq-btn plus" @click="productQuantity += currentQtyStep" :disabled="!selectedFabric">
                      <v-icon size="24">mdi-plus</v-icon>
                    </button>
                  </div>

                  <div class="wholesale-info mj-surface mj-border" v-if="selectedFabric && getSortedTiers(selectedFabric.price_tiers).length">
                    <div class="wholesale-title">Descontos progressivos na base:</div>
                    <div class="wholesale-tiers">
                      <span v-for="tier in getSortedTiers(selectedFabric.price_tiers)" :key="tier.min_qty"
                            class="tier-pill" :class="{'active-tier': productQuantity >= tier.min_qty}">
                        {{ tier.min_qty }}{{ getUnit(selectedFabric) }}+ : R$ {{ formatPrice(tier.price) }}
                      </span>
                    </div>
                  </div>
                </div>

                <transition name="fade">
                  <div class="price-breakdown mj-surface-2 mj-border mt-6" v-if="selectedFabric">
                    <div class="breakdown-row">
                      <span>Custo Base do Tecido (Estamparia Inclusa)</span>
                      <span :class="{'strike-through text-muted': currentFabricUnitPrice < (selectedFabric.base_price || selectedFabric.price)}">
                        R$ {{ formatPrice(selectedFabric.base_price || selectedFabric.price) }}/{{ getUnit(selectedFabric) }}
                      </span>
                    </div>
                    <div class="breakdown-row discount-row" v-if="currentFabricUnitPrice < (selectedFabric.base_price || selectedFabric.price)">
                      <span><v-icon size="14" color="success" start>mdi-check-decagram</v-icon> Desconto Aplicado ({{ productQuantity }}{{ getUnit(selectedFabric) }}+)</span>
                      <span class="text-success font-weight-bold">R$ {{ formatPrice(currentFabricUnitPrice) }}/{{ getUnit(selectedFabric) }}</span>
                    </div>

                    <div class="breakdown-divider"></div>

                    <div class="breakdown-row total-unit">
                      <span>Valor Total Unitário</span>
                      <span>R$ {{ formatPrice(currentFabricUnitPrice) }}</span>
                    </div>
                  </div>
                </transition>

                <div class="final-total-display mt-6" :class="{ 'opacity-50': !selectedFabric }">
                  <span class="total-label">Estimativa Total ({{ productQuantity }} {{ getUnitName(selectedFabric) }})</span>
                  <span class="total-value text-primary">R$ {{ formatPrice(calculatedFabricPrice) }}</span>
                </div>

                <div class="action-stack mt-6">
                  <v-btn
                    color="primary"
                    variant="tonal"
                    size="x-large"
                    block
                    class="buy-btn mb-4"
                    @click="handleAddPhysicalToCart"
                    :disabled="!selectedFabric"
                    :loading="isGeneratingPrint"
                  >
                    <v-icon start>mdi-cart-plus</v-icon>
                    Adicionar Seleção ao Carrinho
                  </v-btn>

                  <v-btn
                    size="x-large"
                    block
                    class="buy-btn whatsapp-pulse-btn"
                    @click="handleFastWhatsappCheckout"
                    :disabled="!selectedFabric"
                    :loading="isGeneratingPrint"
                  >
                    <v-icon start size="24">mdi-whatsapp</v-icon>
                    Falar c/ Vendedor & Enviar Simulação
                  </v-btn>
                </div>
              </div>

              <div v-else-if="purchaseMode === 'own_fabric'" key="own_fabric" class="buy-content">
                <div class="buy-section-title mt-2">
                  1. Defina a metragem para a estamparia
                  <span class="text-error text-caption ml-2 font-weight-bold">(Mín. {{ currentMinQty }} metros)</span>
                </div>

                <div class="buy-row">
                  <div class="elegant-qty-wrapper mj-border">
                    <button class="eq-btn minus" @click="productQuantity > currentMinQty ? productQuantity -= currentQtyStep : null" :disabled="productQuantity <= currentMinQty">
                      <v-icon size="24">mdi-minus</v-icon>
                    </button>
                    <div class="eq-display">
                      <input
                        v-model.number="productQuantity"
                        type="number"
                        :min="currentMinQty"
                        :step="currentQtyStep"
                        class="eq-input"
                        @blur="validateQuantity"
                      />
                      <span class="eq-unit">metros</span>
                    </div>
                    <button class="eq-btn plus" @click="productQuantity += currentQtyStep">
                      <v-icon size="24">mdi-plus</v-icon>
                    </button>
                  </div>
                </div>

                <div class="final-total-display mt-6">
                  <span class="total-label">Estimativa Total de Estamparia ({{ productQuantity }} metros)</span>
                  <span class="total-value text-primary">R$ {{ formatPrice(printCostPerMeter * productQuantity) }}</span>
                </div>

                <div class="action-stack mt-6">
                  <v-btn
                    color="primary"
                    variant="tonal"
                    size="x-large"
                    block
                    class="buy-btn mb-4"
                    @click="handleAddPhysicalToCart"
                    :loading="isGeneratingPrint"
                  >
                    <v-icon start>mdi-cart-plus</v-icon>
                    Adicionar Serviço ao Carrinho
                  </v-btn>

                  <v-btn
                    size="x-large"
                    block
                    class="buy-btn whatsapp-pulse-btn"
                    @click="handleFastWhatsappCheckout"
                    :loading="isGeneratingPrint"
                  >
                    <v-icon start size="24">mdi-whatsapp</v-icon>
                    Falar c/ Vendedor & Enviar Simulação
                  </v-btn>
                </div>
              </div>

              <div v-else-if="purchaseMode === 'pilot'" key="pilot" class="buy-content">

                <div class="buy-section-title">1. Tipo de Aprovação</div>
                <div class="d-flex flex-column gap-3 mb-6">
                  <div class="mj-custom-select mj-surface-2 mj-border pa-4 d-flex align-start gap-3 cursor-pointer transition-swing"
                       :style="pilotApprovalType === 'digital' ? 'border-color: rgb(var(--v-theme-primary)) !important; background-color: rgba(var(--v-theme-primary), 0.05) !important;' : ''"
                       @click="pilotApprovalType = 'digital'">
                       <v-radio :model-value="pilotApprovalType" value="digital" color="primary" hide-details class="mt-n1 pointer-events-none" style="pointer-events: none;"></v-radio>
                       <div>
                          <div class="font-weight-bold text-body-1" :class="pilotApprovalType === 'digital' ? 'text-primary' : 'text-main'">Aprovação Digital</div>
                          <div class="text-caption text-medium-emphasis mt-1">A equipe imprime o piloto e envia uma foto/vídeo para sua aprovação. <strong>(Mais rápido)</strong></div>
                       </div>
                  </div>

                  <div class="mj-custom-select mj-surface-2 mj-border pa-4 d-flex align-start gap-3 cursor-pointer transition-swing"
                       :style="pilotApprovalType === 'physical' ? 'border-color: rgb(var(--v-theme-primary)) !important; background-color: rgba(var(--v-theme-primary), 0.05) !important;' : ''"
                       @click="pilotApprovalType = 'physical'">
                       <v-radio :model-value="pilotApprovalType" value="physical" color="primary" hide-details class="mt-n1 pointer-events-none" style="pointer-events: none;"></v-radio>
                       <div>
                          <div class="font-weight-bold text-body-1" :class="pilotApprovalType === 'physical' ? 'text-primary' : 'text-main'">Aprovação Física</div>
                          <div class="text-caption text-medium-emphasis mt-1">O piloto é impresso e enviado via correios para você analisar fisicamente. <strong>(Pode demorar mais)</strong></div>
                       </div>
                  </div>
                </div>

                <div class="buy-section-title">2. Escolha a base têxtil para o teste</div>

                <div class="custom-select-wrapper" v-if="fabrics.length">
                  <div class="mj-custom-select mj-surface-2 mj-border" @click="isPilotDropdownOpen = !isPilotDropdownOpen" :class="{ 'is-open': isPilotDropdownOpen }">
                    <div class="select-content">
                      <template v-if="pilotFabric">
                        <div class="fabric-info-compact">
                          <span class="fabric-name">{{ pilotFabric.name }}</span>
                        </div>
                        <div class="fabric-price-tag-compact mj-border">
                          <span class="price-val">R$ {{ formatPrice(pilotFabric.base_price || pilotFabric.price) }}</span>
                          <span class="price-un">/metro</span>
                        </div>
                      </template>
                      <template v-else>
                        <span class="placeholder-text">Selecione uma base para o piloto...</span>
                      </template>
                    </div>
                    <v-icon class="chevron-icon" :class="{ 'rotate': isPilotDropdownOpen }">mdi-chevron-down</v-icon>
                  </div>

                  <div v-if="isPilotDropdownOpen" class="dropdown-overlay" @click="isPilotDropdownOpen = false"></div>

                  <transition name="fade-slide">
                    <div v-if="isPilotDropdownOpen" class="mj-custom-dropdown">
                      <div class="dropdown-header">Bases Disponíveis</div>
                      <div class="fabric-options">
                        <div
                          v-for="fabric in fabrics"
                          :key="fabric.id"
                          class="fabric-card"
                          :class="{ active: pilotFabric?.id === fabric.id }"
                          @click="selectPilotFabricItem(fabric)"
                        >
                          <div class="fabric-radio">
                            <div class="radio-inner"></div>
                          </div>
                          <div class="fabric-info">
                            <span class="fabric-name">{{ fabric.name }}</span>
                            <span class="fabric-desc" v-if="fabric.description">{{ fabric.description }}</span>
                          </div>
                          <div class="fabric-price-tag mj-surface-2 mj-border">
                            <span class="price-val">R$ {{ formatPrice(fabric.base_price || fabric.price) }}</span>
                            <span class="price-un">/m</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </transition>
                </div>

                <div class="buy-section-title mt-6">
                  3. Defina a quantidade (Metros)
                </div>

                <div class="buy-row">
                  <div class="elegant-qty-wrapper mj-border" :class="{ 'disabled': !pilotFabric }">
                    <button class="eq-btn minus" @click="pilotQuantity > 1 ? pilotQuantity -= 1 : null" :disabled="!pilotFabric || pilotQuantity <= 1">
                      <v-icon size="24">mdi-minus</v-icon>
                    </button>
                    <div class="eq-display">
                      <input
                        v-model.number="pilotQuantity"
                        type="number"
                        min="1"
                        step="1"
                        class="eq-input"
                        :disabled="!pilotFabric"
                        @blur="pilotQuantity < 1 ? pilotQuantity = 1 : null"
                      />
                      <span class="eq-unit">metros</span>
                    </div>
                    <button class="eq-btn plus" @click="pilotQuantity += 1" :disabled="!pilotFabric">
                      <v-icon size="24">mdi-plus</v-icon>
                    </button>
                  </div>
                </div>

                <v-alert color="warning" variant="tonal" class="mt-6 mb-2 rounded-lg border-warning" density="compact">
                  <template v-slot:prepend>
                    <v-icon size="24" color="warning" class="mr-2">mdi-clock-alert-outline</v-icon>
                  </template>
                  <span class="text-caption font-weight-bold">Aviso importante: O prazo de produção e entrega para testes de piloto é de no mínimo <strong>20 dias úteis</strong>.</span>
                </v-alert>

                <div class="final-total-display mt-6" :class="{ 'opacity-50': !pilotFabric }">
                  <span class="total-label">Custo do Piloto (S/ Descontos)</span>
                  <span class="total-value text-primary">R$ {{ formatPrice(pilotFabric ? (pilotFabric.base_price || pilotFabric.price) * pilotQuantity : 0) }}</span>
                </div>

                <div class="action-stack mt-6">
                  <v-btn
                    color="primary"
                    size="x-large"
                    block
                    class="buy-btn mb-4 checkout-btn"
                    @click="generatePilotPix"
                    :disabled="!pilotFabric"
                    :loading="isGeneratingPix"
                  >
                    <v-icon start>mdi-qrcode-scan</v-icon>
                    Solicitar e Pagar Piloto (PIX)
                  </v-btn>

                  <v-btn
                    size="x-large"
                    block
                    class="buy-btn whatsapp-pulse-btn"
                    @click="handlePilotWhatsapp"
                    :disabled="!pilotFabric"
                    :loading="isGeneratingPix"
                  >
                    <v-icon start size="24">mdi-whatsapp</v-icon>
                    Solicitar com Representante
                  </v-btn>
                </div>
              </div>

              <div v-else-if="purchaseMode === 'digital' && allowPsdSales" key="digital" class="buy-content">
                <div class="digital-specs">
                  <div class="spec-item">
                    <div class="spec-icon mj-surface mj-border"><v-icon color="primary">mdi-file-image-outline</v-icon></div>
                    <div>
                      <strong>Arquivo Fechado</strong>
                      <span>Formato PSD (Photoshop) e TIFF</span>
                    </div>
                  </div>
                  <div class="spec-item">
                    <div class="spec-icon mj-surface mj-border"><v-icon color="primary">mdi-aspect-ratio</v-icon></div>
                    <div>
                      <strong>Alta Resolução</strong>
                      <span>300 DPI - Rapport perfeito</span>
                    </div>
                  </div>
                  <div class="spec-item">
                    <div class="spec-icon mj-surface mj-border"><v-icon color="primary">mdi-lock-open-check-outline</v-icon></div>
                    <div>
                      <strong>Licença Comercial</strong>
                      <span>Uso liberado para produção sem royalties</span>
                    </div>
                  </div>
                </div>

                <div class="digital-price-box mj-surface mj-border">
                  <span class="digital-price-label">Valor Único do Arquivo</span>
                  <span class="digital-price-value">R$ {{ formatPrice(activeStamp.digital_price || 190.00) }}</span>
                </div>

                <div class="action-stack mt-6">
                  <v-btn color="primary" variant="tonal" size="x-large" block class="buy-btn mb-4" @click="handleAddDigitalToCart">
                    <v-icon start>mdi-cart-plus</v-icon>
                    Adicionar PSD ao Carrinho
                  </v-btn>
                  <v-btn color="success" size="x-large" block class="buy-btn checkout-btn mb-4" @click="goToCheckout">
                    <v-icon start>mdi-lightning-bolt</v-icon>
                    Comprar Agora (PIX)
                  </v-btn>
                </div>
              </div>
            </transition>
          </div>
        </section>
      </div>

      <section v-if="relatedStamps.length" class="related-block">
        <div class="section-head">
          <div>
            <div class="eyebrow">Mais da coleção</div>
            <h2 class="section-title large">Você também pode gostar</h2>
          </div>
        </div>

        <div class="stamp-grid">
          <article
            v-for="stamp in relatedStamps"
            :key="stamp.id"
            class="stamp-card mj-surface mj-border"
            @click="router.push(`/marketplace/produto/${stamp.id}`)"
          >
            <div class="stamp-media-wrap">
              <img
                class="stamp-media"
                :src="getOptimizedUrl(stamp.main_image_url, 1080)"
                @error="handleImageError"
                loading="lazy"
                alt="Estampa Relacionada"
              />
            </div>
            <div class="stamp-meta">
              <div class="stamp-ref">{{ stamp.ref_code }}</div>
              <h3 class="stamp-title">{{ stamp.title }}</h3>
            </div>
          </article>
        </div>
      </section>
    </v-container>

    <div v-else class="empty-state mj-surface mj-border" style="max-width: 600px; margin: 100px auto;">
      <v-icon size="52">mdi-alert-circle-outline</v-icon>
      <h3>Estampa não encontrada</h3>
      <p>A estampa pode ter sido removida ou está inativa no momento.</p>
      <v-btn color="primary" class="mt-4" @click="router.push('/marketplace/descobrir')">Voltar ao Acervo</v-btn>
    </div>

    <v-dialog v-model="showLocationWarning" max-width="400" persistent>
      <v-card class="rounded-xl border pa-6 text-center">
        <v-icon size="48" color="primary" class="mx-auto mb-4">mdi-map-marker-alert-outline</v-icon>
        <h3 class="text-h6 font-weight-black mb-2">Atenção à Localidade</h3>
        <p class="text-body-2 text-medium-emphasis mb-6">
          O serviço de estamparia em tecido próprio (Seu Tecido) está disponível apenas para Tietê e região, além da Grande SP.
        </p>
        <v-btn color="primary" block size="large" class="rounded-pill font-weight-bold" @click="showLocationWarning = false">OK, Entendi</v-btn>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showPixModal" max-width="480" persistent>
      <v-card class="rounded-xl pa-8 text-center border shadow-lg mj-surface">
        <template v-if="!pilotApproved">
          <div class="d-flex align-center justify-center mb-4">
             <v-icon size="40" color="success" class="mr-2">mdi-qrcode-scan</v-icon>
             <h3 class="text-h5 font-weight-black">Pagamento do Piloto</h3>
          </div>
          <p class="text-body-2 text-medium-emphasis mb-6">Escaneie o QR Code abaixo ou use o código Pix Copia e Cola para confirmar a solicitação do seu piloto.</p>

          <div class="pa-4 bg-white rounded-xl mx-auto border" style="width: fit-content;" v-if="pixData.copyPaste">
            <qrcode-vue
              :value="pixData.copyPaste"
              :size="220"
              level="M"
              render-as="svg"
            />
          </div>

          <v-text-field
             class="mt-6 mb-2"
             :model-value="pixData.copyPaste"
             readonly
             append-inner-icon="mdi-content-copy"
             @click:append-inner="copyPixText"
             variant="outlined"
             density="comfortable"
             hide-details
             bg-color="surface-2"
             label="Pix Copia e Cola"
          ></v-text-field>

          <div class="d-flex align-center justify-center gap-3 mt-6 mb-2">
             <v-progress-circular indeterminate color="primary" size="24" width="3"></v-progress-circular>
             <span class="text-caption font-weight-bold text-uppercase tracking-widest text-primary">Aguardando pagamento...</span>
          </div>
          <v-btn variant="text" block class="mt-4 opacity-70 font-weight-bold" @click="cancelPixPolling">Cancelar Solicitação</v-btn>
        </template>

        <template v-else>
          <div class="py-6">
            <v-icon size="80" color="success" class="mx-auto mb-6 pulse-animation">mdi-check-circle</v-icon>
            <h3 class="text-h4 font-weight-black text-success mb-3">Pagamento Aprovado!</h3>
            <p class="text-body-1 text-medium-emphasis mb-8 px-4">Sua solicitação de piloto físico foi confirmada, o recibo foi gerado e já está em nossa fila de produção.</p>
            <v-btn color="success" block size="x-large" class="rounded-pill font-weight-black mb-3" @click="router.push('/marketplace/perfil?tab=pilotos')">
               <v-icon start>mdi-format-list-checks</v-icon> Acompanhar Meus Pilotos
            </v-btn>
            <v-btn variant="outlined" block size="x-large" class="rounded-pill font-weight-bold" @click="showPixModal = false">Continuar Explorando</v-btn>
          </div>
        </template>
      </v-card>
    </v-dialog>

    <v-dialog
      v-model="showTutorial"
      max-width="1180"
      class="tutorial-dialog"
      scrollable
    >
      <v-card class="tutorial-modal mj-surface border">
        <div class="tutorial-header">
          <div class="tutorial-header-left">
            <div class="tutorial-header-icon">
              <v-icon color="primary" size="24">mdi-school-outline</v-icon>
            </div>

            <div class="tutorial-header-copy">
              <span class="tutorial-header-kicker">Guia do Estúdio</span>
              <h2 class="tutorial-header-title">Ferramentas de Estúdio</h2>
              <p class="tutorial-header-subtitle">
                Aprenda rapidamente como navegar, medir elementos e testar novas cores com precisão visual.
              </p>
            </div>
          </div>

          <v-btn
            icon="mdi-close"
            variant="text"
            size="small"
            class="tutorial-close-btn"
            @click="showTutorial = false"
          />
        </div>

        <div class="tutorial-tabs-wrap">
          <v-tabs
            v-model="tutorialTab"
            color="primary"
            grow
            density="comfortable"
            class="tutorial-tabs"
          >
            <v-tab value="pan" class="font-weight-bold text-none">
              <v-icon start size="18">mdi-hand-back-right-outline</v-icon>
              Pan & Zoom
            </v-tab>

            <v-tab value="lasso" class="font-weight-bold text-none">
              <v-icon start size="18">mdi-lasso</v-icon>
              Medição
            </v-tab>

            <v-tab value="color" class="font-weight-bold text-none">
              <v-icon start size="18">mdi-format-color-fill</v-icon>
              Cores
            </v-tab>
          </v-tabs>
        </div>

        <div class="tutorial-body">
          <v-window v-model="tutorialTab" class="tutorial-window">
            <v-window-item value="pan">
              <div class="tutorial-pane">
                <section class="tutorial-demo-card">
                  <div class="tutorial-demo-topbar">
                    <div class="tutorial-pill tutorial-pill-primary">
                      <v-icon size="14">mdi-hand-back-right-outline</v-icon>
                      Ferramenta ativa
                    </div>

                    <div class="tutorial-pill tutorial-pill-dark">
                      Atalho: V
                    </div>
                  </div>

                  <div class="tutorial-animation-box tutorial-animation-box-xl">
                    <div class="tutorial-scene-frame"></div>
                    <div class="tutorial-mini-ruler-h"></div>
                    <div class="tutorial-mini-ruler-v"></div>

                    <div class="anim-dummy-stamp anim-pan-stamp"></div>
                    <div class="tutorial-mock-canvas-grid"></div>

                    <div class="tutorial-mini-zoom-ui">
                      <v-icon size="14">mdi-magnify-minus-outline</v-icon>
                      <div class="tutorial-mini-zoom-track">
                        <div class="tutorial-mini-zoom-fill" style="width: 58%"></div>
                      </div>
                      <v-icon size="14">mdi-magnify-plus-outline</v-icon>
                    </div>

                    <div class="tutorial-canvas-badge">Zoom visual: 120%</div>
                    <v-icon size="40" class="anim-hand-cursor">mdi-cursor-default</v-icon>
                  </div>

                  <p class="tutorial-demo-caption">
                    A visualização se move como um canvas real, com área de trabalho, grade e controle de zoom.
                  </p>
                </section>

                <section class="tutorial-content-card">
                  <div class="tutorial-kicker">Estúdio • Navegação</div>

                  <div class="tutorial-title-row">
                    <h3 class="tutorial-title">Pan & Zoom</h3>
                    <div class="tutorial-keycap">V</div>
                  </div>

                  <p class="tutorial-lead">
                    Esta é a ferramenta principal para explorar a estampa no canvas. Use-a para reposicionar a arte, conferir enquadramento e inspecionar a escala antes de medir ou recolorir.
                  </p>

                  <div class="tutorial-steps">
                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">1</div>
                      <div>
                        <div class="tutorial-step-title">Arraste o canvas</div>
                        <div class="tutorial-step-text">
                          Clique e mova a visualização para reposicionar a estampa livremente.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">2</div>
                      <div>
                        <div class="tutorial-step-title">Aplique zoom com naturalidade</div>
                        <div class="tutorial-step-text">
                          Use o <strong>scroll do mouse</strong> no desktop ou o gesto de <strong>pinça</strong> no celular.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">3</div>
                      <div>
                        <div class="tutorial-step-title">Revise composição e rapport</div>
                        <div class="tutorial-step-text">
                          Ideal para entender repetição, área visível, posicionamento e sensação geral da arte.
                        </div>
                      </div>
                    </div>
                  </div>

                  <v-alert
                    color="primary"
                    variant="tonal"
                    density="comfortable"
                    class="tutorial-alert mt-5"
                  >
                    <strong>Melhor momento para usar:</strong> antes de medir ou testar cores, ajuste primeiro a visualização para o ponto exato que deseja analisar.
                  </v-alert>
                </section>
              </div>
            </v-window-item>

            <v-window-item value="lasso">
              <div class="tutorial-pane">
                <section class="tutorial-demo-card">
                  <div class="tutorial-demo-topbar">
                    <div class="tutorial-pill tutorial-pill-primary">
                      <v-icon size="14">mdi-lasso</v-icon>
                      Ferramenta ativa
                    </div>

                    <div class="tutorial-pill tutorial-pill-dark">
                      Atalho: M
                    </div>
                  </div>

                  <div class="tutorial-animation-box tutorial-animation-box-xl">
                    <div class="tutorial-scene-frame"></div>
                    <div class="tutorial-mini-ruler-h"></div>
                    <div class="tutorial-mini-ruler-v"></div>
                    <div class="tutorial-demo-lasso-art"></div>

                    <svg class="anim-lasso-svg" viewBox="0 0 100 80">
                      <path class="anim-lasso-draw" d="M 0 0 L 100 0 L 100 80 L 0 80 Z" />
                    </svg>

                    <div class="anim-lasso-tooltip">
                      W: 10cm<br />
                      H: 8cm
                    </div>

                    <div class="tutorial-mode-chip">Tamanho Impresso</div>
                    <v-icon size="30" class="anim-lasso-cursor">mdi-cursor-default</v-icon>
                  </div>

                  <p class="tutorial-demo-caption">
                    O laço contorna visualmente um elemento e apresenta a leitura dimensional como no estúdio real.
                  </p>
                </section>

                <section class="tutorial-content-card">
                  <div class="tutorial-kicker">Estúdio • Medição</div>

                  <div class="tutorial-title-row">
                    <h3 class="tutorial-title">Laço de Medição</h3>
                    <div class="tutorial-keycap">M</div>
                  </div>

                  <p class="tutorial-lead">
                    Meça elementos específicos da arte de forma visual e imediata. Isso ajuda a validar se flores, ornamentos, barrados ou módulos estão no tamanho esperado para impressão.
                  </p>

                  <div class="tutorial-steps">
                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">1</div>
                      <div>
                        <div class="tutorial-step-title">Contorne a área desejada</div>
                        <div class="tutorial-step-text">
                          Clique e arraste ao redor do elemento que você quer analisar.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">2</div>
                      <div>
                        <div class="tutorial-step-title">Leia largura e altura</div>
                        <div class="tutorial-step-text">
                          O tooltip mostra medidas de maneira clara para facilitar a validação visual da escala.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">3</div>
                      <div>
                        <div class="tutorial-step-title">Compare os modos de cálculo</div>
                        <div class="tutorial-step-text">
                          Alterne entre <strong>Tamanho Impresso</strong> e <strong>Tamanho Original</strong> para entender a diferença entre escala aplicada e dimensão nativa da arte.
                        </div>
                      </div>
                    </div>
                  </div>

                  <v-alert
                    color="primary"
                    variant="tonal"
                    density="comfortable"
                    class="tutorial-alert mt-5"
                  >
                    <strong>Dica profissional:</strong> use <em>Tamanho Impresso</em> para validar o resultado final no tecido e <em>Tamanho Original</em> para inspecionar a base real do desenho.
                  </v-alert>
                </section>
              </div>
            </v-window-item>

            <v-window-item value="color">
              <div class="tutorial-pane">
                <section class="tutorial-demo-card">
                  <div class="tutorial-demo-topbar">
                    <div class="tutorial-pill tutorial-pill-primary">
                      <v-icon size="14">mdi-format-color-fill</v-icon>
                      Ferramenta ativa
                    </div>

                    <div class="tutorial-pill tutorial-pill-dark">
                      Atalho: C
                    </div>
                  </div>

                  <div class="tutorial-animation-box tutorial-animation-box-xl">
                    <div class="tutorial-scene-frame"></div>

                    <div class="anim-dummy-stamp anim-color-stamp"></div>

                    <div class="anim-fake-toolbar tutorial-fake-toolbar-pro">
                      <div class="tutorial-fake-toolbar-label">Nova cor</div>
                      <div class="anim-fake-picker"></div>
                      <div class="tutorial-fake-slider">
                        <span>Tolerância</span>
                        <div class="tutorial-fake-slider-track">
                          <div class="tutorial-fake-slider-fill"></div>
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-demo-color-art"></div>
                    <div class="anim-ripple"></div>
                    <v-icon size="30" class="anim-color-cursor">mdi-cursor-default</v-icon>
                  </div>

                  <p class="tutorial-demo-caption">
                    A recoloração acontece sobre uma mini arte simulada, aproximando melhor o comportamento real da ferramenta.
                  </p>
                </section>

                <section class="tutorial-content-card">
                  <div class="tutorial-kicker">Estúdio • Recoloração</div>

                  <div class="tutorial-title-row">
                    <h3 class="tutorial-title">Substituição Mágica de Cor</h3>
                    <div class="tutorial-keycap">C</div>
                  </div>

                  <p class="tutorial-lead">
                    Teste rapidamente novas combinações cromáticas sem sair da visualização. Ótimo para criar variantes, explorar paletas e validar direção estética com agilidade.
                  </p>

                  <div class="tutorial-steps">
                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">1</div>
                      <div>
                        <div class="tutorial-step-title">Escolha a nova cor</div>
                        <div class="tutorial-step-text">
                          Defina a tonalidade desejada no painel da ferramenta.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">2</div>
                      <div>
                        <div class="tutorial-step-title">Ajuste a tolerância</div>
                        <div class="tutorial-step-text">
                          Quanto maior a tolerância, maior a faixa de tons parecidos que será substituída.
                        </div>
                      </div>
                    </div>

                    <div class="tutorial-step-card">
                      <div class="tutorial-step-index">3</div>
                      <div>
                        <div class="tutorial-step-title">Clique no tom desejado</div>
                        <div class="tutorial-step-text">
                          O sistema identifica a cor alvo e aplica a troca nas áreas compatíveis de maneira visual.
                        </div>
                      </div>
                    </div>
                  </div>

                  <v-alert
                    color="primary"
                    variant="tonal"
                    density="comfortable"
                    class="tutorial-alert mt-5"
                  >
                    <strong>Melhor prática:</strong> comece com tolerância baixa para trocas mais precisas e aumente gradualmente quando quiser abranger variações próximas.
                  </v-alert>
                </section>
              </div>
            </v-window-item>
          </v-window>
        </div>

        <div class="tutorial-footer">
          <div class="tutorial-footer-note">
            Você pode alternar entre as ferramentas a qualquer momento usando os atalhos do teclado.
          </div>

          <v-btn
            color="primary"
            variant="flat"
            class="tutorial-confirm-btn"
            @click="showTutorial = false"
          >
            Entendi, vamos lá!
          </v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch, inject, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'
import html2canvas from 'html2canvas'
import QrcodeVue from 'qrcode.vue'
import { coraApi } from '@/api/coraProxy'

const MR_JACKY_CORA_ID = 'int-3VpXneDbEmHHHYFNN8hoIh'

const router = useRouter()
const route = useRoute()

const cartContext = inject('marketplaceCart') as any
const userStore = useMarketplaceUserStore()

const isLoading = ref(true)
const isGeneratingPrint = ref(false)
const purchaseMode = ref<'fabric' | 'own_fabric' | 'pilot' | 'digital'>('fabric')
const isDropdownOpen = ref(false)

const mockupCaptureArea = ref<HTMLElement | null>(null)

const activeStamp = ref<any>(null)
const availableMockups = ref<any[]>([])
const selectedMockup = ref<any>(null)
const relatedStamps = ref<any[]>([])
const fabrics = ref<any[]>([])

const viewerZoom = ref(1) // Escala 1.0x inicial
const productQuantity = ref(25)
const selectedFabric = ref<any>(null)

const userProfile = ref<any>({ name: 'Cliente', document: '', location: '' })
const isDesignApproved = ref(false)
const designAccessRequested = ref(false)
const allowPsdSales = ref(true)

// ==========================================
// DADOS EXCLUSIVOS DO PILOTO
// ==========================================
const isPilotDropdownOpen = ref(false)
const pilotFabric = ref<any>(null)
const pilotQuantity = ref(1) // Mínimo de 1 metro sempre para pilotos
const isGeneratingPix = ref(false)

// Tipo de aprovação do Piloto
const pilotApprovalType = ref<'digital' | 'physical'>('digital')

// Estado Modal PIX
const showPixModal = ref(false)
const pixData = ref({ qrCodeBase64: '', copyPaste: '', txId: '', pilotId: '' })
const pilotApproved = ref(false)
let pixPollingInterval: any = null

const safeZoom = computed(() => Math.max(0.3, Number(viewerZoom.value || 1)))
const isFavorite = computed(() => activeStamp.value ? userStore.isInWishlist(activeStamp.value.id) : false)

// Estado das Ferramentas
const activeTool = ref<'pan' | 'lasso' | 'color'>('pan')
const measureMode = ref<'printed' | 'original'>('printed')
const showTutorial = ref(false)
const tutorialTab = ref('pan')

const showLocationWarning = ref(false)

function setPurchaseMode(mode: 'fabric' | 'own_fabric' | 'pilot' | 'digital') {
  if (mode === 'own_fabric') {
    showLocationWarning.value = true;
  }
  purchaseMode.value = mode;
}

// Sistema de restrição estrita (25 em 25 ou 10 em 10 para KG)
const currentMinQty = computed(() => {
  if (purchaseMode.value === 'own_fabric') return 25;
  if (selectedFabric.value && getUnit(selectedFabric.value) === 'kg') return 10;
  return 25;
});

const currentQtyStep = computed(() => {
  if (purchaseMode.value === 'own_fabric') return 25;
  if (selectedFabric.value && getUnit(selectedFabric.value) === 'kg') return 10;
  return 25;
});

function validateQuantity() {
  const min = currentMinQty.value;
  const step = currentQtyStep.value;

  if (typeof productQuantity.value !== 'number' || isNaN(productQuantity.value)) {
    productQuantity.value = min;
  } else if (productQuantity.value < min) {
    productQuantity.value = min;
  } else {
    productQuantity.value = Math.ceil(productQuantity.value / step) * step;
  }
}

watch([purchaseMode, selectedFabric], () => {
  if (purchaseMode.value !== 'pilot') validateQuantity();
});

function getUnit(fabric: any) {
  if (!fabric || !fabric.unit) return 'm';
  return fabric.unit.toLowerCase() === 'kg' ? 'kg' : 'm';
}

function getUnitName(fabric: any) {
  if (!fabric || !fabric.unit) return 'metros';
  return fabric.unit.toLowerCase() === 'kg' ? 'kg' : 'metros';
}

function formatMeasureString(cmValue: string | number) {
  const val = Number(cmValue);
  if (isNaN(val)) return '0cm';
  if (val >= 100) return (val / 100).toFixed(2) + 'm';
  return val.toFixed(1) + 'cm';
}

// =======================================================
//   SISTEMA DE WORKSPACE: PAN, GRID & LAÇO (LASSO)
// =======================================================
const panX = ref(0)
const panY = ref(0)
const isDragging = ref(false)
const isLassoing = ref(false)

const dragStart = reactive({ x: 0, y: 0 })
const currentMouse = reactive({ x: 0, y: 0 })
const lassoPoints = ref<{x: number, y: number}[]>([])

let initialPinchDistance = 0;
let initialViewerZoom = 1;

const gridStyle = computed(() => ({
  '--grid-position-x': `${panX.value}px`,
  '--grid-position-y': `${panY.value}px`,
  '--grid-size': `${50 * safeZoom.value}px`,
  '--grid-color': 'rgba(148, 163, 184, 0.25)'
}))

function handleKeydown(e: KeyboardEvent) {
  if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
  if (e.key.toLowerCase() === 'm') activeTool.value = 'lasso'
  if (e.key.toLowerCase() === 'v') activeTool.value = 'pan'
  if (e.key.toLowerCase() === 'c') activeTool.value = 'color'
}

onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
  if (route.params.id) loadProductData(route.params.id as string)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
  if (pixPollingInterval) clearInterval(pixPollingInterval)
})

function getEventCoords(e: MouseEvent | TouchEvent) {
  const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
  let clientX, clientY
  if (window.TouchEvent && e instanceof TouchEvent) {
    clientX = e.touches[0].clientX; clientY = e.touches[0].clientY
  } else {
    clientX = (e as MouseEvent).clientX; clientY = (e as MouseEvent).clientY
  }
  return {
    x: clientX - rect.left - 32,
    y: clientY - rect.top - 32
  }
}

function handleWheel(e: WheelEvent) {
  if (selectedMockup.value !== null) return;
  const zoomIntensity = 0.1;
  const direction = e.deltaY < 0 ? 1 : -1;
  let newZoom = viewerZoom.value + (direction * zoomIntensity);
  viewerZoom.value = Math.max(0.3, Math.min(5, newZoom));
}

function handleTouchStart(e: TouchEvent) {
  if (e.touches.length === 2 && selectedMockup.value === null) {
    e.preventDefault();
    isDragging.value = false;
    initialPinchDistance = Math.hypot(
      e.touches[0].clientX - e.touches[1].clientX,
      e.touches[0].clientY - e.touches[1].clientY
    );
    initialViewerZoom = viewerZoom.value;
    return;
  }
  if (activeTool.value === 'lasso' || activeTool.value === 'color' || selectedMockup.value === null) {
    e.preventDefault();
  }
  handleMouseDown(e);
}

function handleTouchMove(e: TouchEvent) {
  if (e.touches.length === 2 && selectedMockup.value === null) {
    e.preventDefault();
    const currentDistance = Math.hypot(
      e.touches[0].clientX - e.touches[1].clientX,
      e.touches[0].clientY - e.touches[1].clientY
    );
    const scale = currentDistance / initialPinchDistance;
    viewerZoom.value = Math.max(0.3, Math.min(5, initialViewerZoom * scale));
    return;
  }
  if (activeTool.value === 'lasso' || isDragging.value) {
    e.preventDefault();
  }
  handleMouseMove(e);
}

function handleMouseDown(e: MouseEvent | TouchEvent) {
  const coords = getEventCoords(e)
  currentMouse.x = coords.x
  currentMouse.y = coords.y

  if (activeTool.value === 'lasso') {
    isLassoing.value = true
    lassoPoints.value = [coords]
  } else if (activeTool.value === 'color' && selectedMockup.value === null) {
    performColorReplace(coords.x, coords.y);
  } else {
    if (selectedMockup.value === null) {
      isDragging.value = true
      dragStart.x = coords.x
      dragStart.y = coords.y
    }
  }
}

function handleMouseMove(e: MouseEvent | TouchEvent) {
  const coords = getEventCoords(e)
  currentMouse.x = coords.x
  currentMouse.y = coords.y

  if (activeTool.value === 'lasso' && isLassoing.value) {
    lassoPoints.value.push(coords)
  } else if (isDragging.value && selectedMockup.value === null) {
    panX.value += (coords.x - dragStart.x)
    panY.value += (coords.y - dragStart.y)
    dragStart.x = coords.x
    dragStart.y = coords.y
  }
}

function handleMouseUp() {
  isDragging.value = false
  isLassoing.value = false
}

watch(activeTool, (newVal) => {
  if (newVal !== 'lasso') {
    lassoPoints.value = []
    isLassoing.value = false
  }
})

const lassoPointsString = computed(() => {
  return lassoPoints.value.map(p => `${p.x},${p.y}`).join(' ')
})

const lassoBoundingBox = computed(() => {
  if (lassoPoints.value.length === 0) return null
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity

  for (const p of lassoPoints.value) {
    if (p.x < minX) minX = p.x
    if (p.x > maxX) maxX = p.x
    if (p.y < minY) minY = p.y
    if (p.y > maxY) maxY = p.y
  }

  return { minX, minY, maxX, maxY, w: maxX - minX, h: maxY - minY }
})

const tooltipStyle = computed(() => {
  return {
    top: `${currentMouse.y + 16}px`,
    left: `${currentMouse.x + 16}px`
  }
})

const selectionDim = computed(() => {
  const box = lassoBoundingBox.value
  if (!activeStamp.value || !mockupCaptureArea.value || !box || box.w === 0) {
    return { pxW: 0, pxH: 0, cmW: 0, cmH: 0 }
  }

  const containerHeightPx = mockupCaptureArea.value.clientHeight - 32
  const stampPhysicalHeightCm = activeStamp.value.height_cm || 50;
  const stampPhysicalWidthCm = activeStamp.value.width_cm || 50;

  const basePxPerCmY = containerHeightPx / stampPhysicalHeightCm;
  const basePxPerCmX = (containerHeightPx * (stampPhysicalWidthCm / stampPhysicalHeightCm)) / stampPhysicalWidthCm;

  const divisorX = measureMode.value === 'original' ? (basePxPerCmX * safeZoom.value) : basePxPerCmX;
  const divisorY = measureMode.value === 'original' ? (basePxPerCmY * safeZoom.value) : basePxPerCmY;

  return {
    pxW: box.w.toFixed(0),
    pxH: box.h.toFixed(0),
    cmW: (box.w / divisorX).toFixed(2),
    cmH: (box.h / divisorY).toFixed(2)
  }
})

const targetReplaceColor = ref('#0d99ff');
const colorTolerance = ref(40);
const isProcessingColor = ref(false);
const hasModifiedImage = ref(false);
const originalImageSrcRef = ref('');

let offscreenCanvas: HTMLCanvasElement | null = null;
let offscreenCtx: CanvasRenderingContext2D | null = null;
let originalImageData: ImageData | null = null;

function hexToRgb(hex: string) {
  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? { r: parseInt(result[1], 16), g: parseInt(result[2], 16), b: parseInt(result[3], 16) } : { r:0, g:0, b:0 };
}

function colorDistance(r1: number, g1: number, b1: number, r2: number, g2: number, b2: number) {
  return Math.sqrt(Math.pow(r2 - r1, 2) + Math.pow(g2 - g1, 2) + Math.pow(b2 - b1, 2));
}

function initOffscreenCanvas(url: string) {
  offscreenCanvas = document.createElement('canvas');
  offscreenCtx = offscreenCanvas.getContext('2d', { willReadFrequently: true });

  const img = new Image();
  img.crossOrigin = 'Anonymous';
  img.onload = () => {
    if (!offscreenCanvas || !offscreenCtx) return;
    offscreenCanvas.width = img.width;
    offscreenCanvas.height = img.height;
    offscreenCtx.drawImage(img, 0, 0);
    originalImageData = offscreenCtx.getImageData(0, 0, img.width, img.height);
  };
  img.src = url;
}

function restoreOriginalImage() {
  if (activeStamp.value && originalImageSrcRef.value) {
    activeStamp.value.main_image_url = originalImageSrcRef.value;
    hasModifiedImage.value = false;
    if (offscreenCtx && offscreenCanvas && originalImageData) {
      offscreenCtx.putImageData(originalImageData, 0, 0);
    }
  }
}

async function performColorReplace(clickX: number, clickY: number) {
  if (!offscreenCanvas || !offscreenCtx || !originalImageData || !mockupCaptureArea.value) return;

  const containerW = mockupCaptureArea.value.clientWidth - 32;
  const containerH = mockupCaptureArea.value.clientHeight - 32;

  const hCm = activeStamp.value.height_cm || 50;
  const wCm = activeStamp.value.width_cm || 50;
  const ratio = wCm / hCm;

  const drawnH = containerH * safeZoom.value;
  const drawnW = drawnH * ratio;

  const centerX = (containerW / 2) + panX.value;
  const centerY = (containerH / 2) + panY.value;

  const leftX = centerX - (drawnW / 2);
  const topY = centerY - (drawnH / 2);

  const imgX = clickX - leftX;
  const imgY = clickY - topY;

  if (imgX < 0 || imgX > drawnW || imgY < 0 || imgY > drawnH) return;

  const origX = Math.floor((imgX / drawnW) * offscreenCanvas.width);
  const origY = Math.floor((imgY / drawnH) * offscreenCanvas.height);

  isProcessingColor.value = true;

  setTimeout(() => {
    if (!offscreenCtx || !offscreenCanvas || !originalImageData) return;

    const currentImgData = offscreenCtx.getImageData(0, 0, offscreenCanvas.width, offscreenCanvas.height);
    const data = currentImgData.data;

    const clickIndex = (origY * currentImgData.width + origX) * 4;
    const clickedR = data[clickIndex];
    const clickedG = data[clickIndex + 1];
    const clickedB = data[clickIndex + 2];
    const clickedA = data[clickIndex + 3];

    if (clickedA === 0) {
      isProcessingColor.value = false;
      return;
    }

    const targetRgb = hexToRgb(targetReplaceColor.value);

    for (let i = 0; i < data.length; i += 4) {
      if (data[i+3] === 0) continue;

      const dist = colorDistance(clickedR, clickedG, clickedB, data[i], data[i+1], data[i+2]);
      if (dist <= colorTolerance.value) {
        data[i] = targetRgb.r;
        data[i+1] = targetRgb.g;
        data[i+2] = targetRgb.b;
      }
    }

    offscreenCtx.putImageData(currentImgData, 0, 0);

    offscreenCanvas.toBlob((blob) => {
      if (blob) {
         const newUrl = URL.createObjectURL(blob);
         activeStamp.value.main_image_url = newUrl;
         hasModifiedImage.value = true;
      }
      isProcessingColor.value = false;
    }, 'image/png');

  }, 50);
}

const finalPrintWidth = computed(() => ((activeStamp.value?.width_cm || 50) * safeZoom.value).toFixed(1))
const finalPrintHeight = computed(() => ((activeStamp.value?.height_cm || 50) * safeZoom.value).toFixed(1))

const rulerTrackStyleH = computed(() => ({ transform: `translateX(${panX.value}px)` }))
const rulerTrackStyleV = computed(() => ({ transform: `translateY(${panY.value}px)` }))

function generateRuler(isHoriz: boolean) {
  const markers = []
  let majorStep = 10
  let minorStep = 5

  if (safeZoom.value >= 3) { majorStep = 2; minorStep = 1 }
  else if (safeZoom.value >= 1.5) { majorStep = 5; minorStep = 1 }

  const hCm = activeStamp.value?.height_cm || 50;
  const wCm = activeStamp.value?.width_cm || 50;
  const ratio = wCm / hCm;

  const scaledHeightPercent = safeZoom.value * 100;
  const scaledWidthPercent = scaledHeightPercent * ratio;

  const maxCm = isHoriz ? wCm : hCm;
  const scaledPercent = isHoriz ? scaledWidthPercent : scaledHeightPercent;

  const startPos = 50 - (scaledPercent / 2);

  for (let i = 0; i <= maxCm; i += minorStep) {
    const percentPos = (i / maxCm) * scaledPercent
    markers.push({
      id: `marker-${i}`,
      cm: i,
      pos: `${startPos + percentPos}%`,
      isMajor: i % majorStep === 0
    })
  }
  return markers
}

const rulerMarkersH = computed(() => generateRuler(true))
const rulerMarkersV = computed(() => generateRuler(false))

const patternStyle = computed(() => ({
  backgroundColor: activeStamp.value?.dominant_color || '#ffffff',
  backgroundImage: `url(${activeStamp.value?.main_image_url || '/placeholder.png'})`,
  backgroundRepeat: 'repeat',
  backgroundPosition: 'top left',
  backgroundSize: `auto ${safeZoom.value * 100}%`,
  transition: 'background-size 0.1s linear',
}))

const rawStampStyle = computed(() => {
  const hCm = activeStamp.value?.height_cm || 50;
  const wCm = activeStamp.value?.width_cm || 50;
  const ratio = wCm / hCm;

  return {
    backgroundImage: `url(${activeStamp.value?.main_image_url || '/placeholder.png'})`,
    backgroundRepeat: 'no-repeat',
    backgroundPosition: `calc(50% + ${panX.value}px) calc(50% + ${panY.value}px)`,
    backgroundSize: `calc(100% * ${ratio} * ${safeZoom.value}) calc(100% * ${safeZoom.value})`,
    width: '100%',
    height: '100%',
    transition: isDragging.value ? 'none' : 'background-size 0.1s linear, background-position 0.1s linear',
    cursor: activeTool.value === 'lasso' ? 'crosshair' : (activeTool.value === 'color' ? 'cell' : (isDragging.value ? 'grabbing' : 'grab'))
  }
})

const maskStyle = computed(() => ({
  WebkitMaskImage: `url(${selectedMockup.value?.mask_url})`,
  maskImage: `url(${selectedMockup.value?.mask_url})`,
  WebkitMaskSize: 'contain',
  maskSize: 'contain',
  WebkitMaskPosition: 'center',
  maskPosition: 'center',
  WebkitMaskRepeat: 'no-repeat',
  maskRepeat: 'no-repeat',
}))

const mockupListRef = ref<HTMLElement | null>(null)

function scrollMockups(direction: 'left' | 'right') {
  if (!mockupListRef.value) return
  const scrollAmount = 180
  if (direction === 'left') mockupListRef.value.scrollBy({ left: -scrollAmount, behavior: 'smooth' })
  else mockupListRef.value.scrollBy({ left: scrollAmount, behavior: 'smooth' })
}

async function toggleFavorite() {
  if (!userStore.isAuthenticated) {
    alert('Por favor, faça login para salvar estampas nos seus favoritos!')
    return
  }
  if (activeStamp.value) await userStore.toggleWishlist(activeStamp.value.id)
}

function getOptimizedUrl(originalUrl: string | null | undefined, targetWidth: number) {
  if (!originalUrl) return '/placeholder.png'
  if (!originalUrl.includes('supabase.co') || !originalUrl.includes('/object/public/')) return originalUrl
  try {
    const urlParts = originalUrl.split('/object/public/')
    const pathAndBucket = urlParts[1]
    const firstSlashIndex = pathAndBucket.indexOf('/')
    const bucket = pathAndBucket.substring(0, firstSlashIndex)
    let filePath = pathAndBucket.substring(firstSlashIndex + 1)
    if (filePath.includes('?')) filePath = filePath.split('?')[0]
    filePath = decodeURIComponent(filePath)
    const { data } = supabase.storage.from(bucket).getPublicUrl(filePath, { transform: { width: targetWidth } })
    return data.publicUrl
  } catch (err) {
    return originalUrl
  }
}

function handleImageError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.includes('placeholder.png')) img.src = '/placeholder.png'
}

const printCostPerMeter = 7.00

function getSortedTiers(tiers: any) {
  if (!tiers || !Array.isArray(tiers)) return []
  return [...tiers].sort((a, b) => b.min_qty - a.min_qty)
}

const currentFabricUnitPrice = computed(() => {
  if (!selectedFabric.value) return 0
  const basePrice = Number(selectedFabric.value.base_price || selectedFabric.value.price || 0)
  const tiers = getSortedTiers(selectedFabric.value.price_tiers)
  let applicablePrice = basePrice
  for (const tier of tiers) {
    if (productQuantity.value >= tier.min_qty) {
      applicablePrice = Number(tier.price)
      break
    }
  }
  return applicablePrice
})

const calculatedFabricPrice = computed(() => {
  if (!selectedFabric.value) return 0
  return currentFabricUnitPrice.value * productQuantity.value
})

function formatPrice(value: number) {
  return Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function selectFabricItem(fabric: any) {
  selectedFabric.value = fabric
  isDropdownOpen.value = false
}

function selectPilotFabricItem(fabric: any) {
  pilotFabric.value = fabric
  isPilotDropdownOpen.value = false
}

async function loadProductData(id: string) {
  isLoading.value = true
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session) {
      const { data: leadData } = await supabase.from('public_leads').select('*').eq('email', session.user.email).maybeSingle()
      if (leadData) {
        userProfile.value = leadData

        if (leadData.design_access_status === 'granted' || leadData.is_vip === true) {
           isDesignApproved.value = true
        } else if (leadData.design_access_status === 'pending') {
           designAccessRequested.value = true
        }

        if (!userStore.user) {
          await userStore.setUser({
            id: leadData.id,
            name: leadData.name || '',
            email: leadData.email,
            phone: leadData.phone,
            document: leadData.document,
            avatarUrl: leadData.avatar_url
          })
        }
      }
    }

    try {
      const { data: settingsData } = await supabase.from('storefront_settings').select('allow_psd_sales').order('updated_at', { ascending: false }).limit(1).maybeSingle()
      if (settingsData && settingsData.allow_psd_sales === false) {
        allowPsdSales.value = false
        purchaseMode.value = 'fabric'
      } else {
        allowPsdSales.value = true
      }
    } catch (e) {}

    const { data: stampData } = await supabase.from('catalog_stamps').select('*, catalog_categories(name)').eq('id', id).maybeSingle()

    if (!stampData) {
      isLoading.value = false
      return
    }
    activeStamp.value = stampData
    originalImageSrcRef.value = stampData.main_image_url

    if (stampData.main_image_url) initOffscreenCanvas(stampData.main_image_url)

    try {
      const { data: fabricData } = await supabase.from('catalog_fabrics').select('*').eq('is_active', true).order('base_price', { ascending: true })
      fabrics.value = fabricData || []
    } catch (err) { fabrics.value = [] }

    const { data: mockupData } = await supabase.from('catalog_mockups').select('*').eq('is_active', true)
    if (mockupData) {
      availableMockups.value = mockupData.filter((m) => {
        const cats = m.config?.categories || []
        if (!cats.length) return true
        return cats.includes(activeStamp.value.category_id)
      })
      if (availableMockups.value.length) selectedMockup.value = availableMockups.value[0]
    }

    const { data: relatedData } = await supabase.from('catalog_stamps').select('*').eq('category_id', activeStamp.value.category_id).neq('id', activeStamp.value.id).limit(4)
    relatedStamps.value = relatedData || []

    viewerZoom.value = 1
    panX.value = 0
    panY.value = 0
    productQuantity.value = 25
    selectedFabric.value = null
    pilotFabric.value = null
    isDropdownOpen.value = false
    isPilotDropdownOpen.value = false

  } catch (error) {
    console.error('Erro ao carregar produto:', error)
  } finally {
    isLoading.value = false
  }
}

watch(() => route.params.id, (newId) => { if (newId) loadProductData(newId as string) })

async function captureAndUploadSimulation() {
  if (!mockupCaptureArea.value) return null
  try {
    const tempGrid = document.querySelector('.grid-overlay') as HTMLElement
    if (tempGrid) tempGrid.style.display = 'none'
    const tempLasso = document.querySelector('.lasso-overlay') as HTMLElement
    if (tempLasso) tempLasso.style.display = 'none'
    const tempTooltip = document.querySelector('.dimensions-tooltip') as HTMLElement
    if (tempTooltip) tempTooltip.style.display = 'none'

    const canvas = await html2canvas(mockupCaptureArea.value, {
      useCORS: true,
      scale: 1.5,
      backgroundColor: '#ffffff'
    })

    if (tempGrid) tempGrid.style.display = 'block'
    if (tempLasso) tempLasso.style.display = 'block'
    if (tempTooltip) tempTooltip.style.display = 'flex'

    const blob = await new Promise<Blob | null>(resolve => canvas.toBlob(resolve, 'image/jpeg', 0.8))
    if (!blob) throw new Error('Falha ao gerar imagem')

    const fileName = `sim_${Date.now()}_${activeStamp.value.ref_code}.jpg`
    const path = `simulations/${fileName}`

    const { error } = await supabase.storage.from('catalog-assets').upload(path, blob)
    if (error) throw error

    const { data } = supabase.storage.from('catalog-assets').getPublicUrl(path)
    return data.publicUrl

  } catch (e) {
    console.error('Erro na captura:', e)
    return null
  }
}

async function handleAddPhysicalToCart() {
  if (purchaseMode.value === 'fabric' && !selectedFabric.value) return;
  isGeneratingPrint.value = true;

  const simulationUrl = await captureAndUploadSimulation();

  let fabricName = '';
  let fabricUnitPrice = 0;

  if (purchaseMode.value === 'fabric') {
     fabricName = selectedFabric.value.name;
     fabricUnitPrice = currentFabricUnitPrice.value;
  } else if (purchaseMode.value === 'own_fabric') {
     fabricName = 'Tecido do Cliente';
     fabricUnitPrice = 0;
  }

  const customStampPayload = {
    ...activeStamp.value,
    title: `${activeStamp.value.title} - ${purchaseMode.value === 'own_fabric' ? 'Tecido Cliente' : 'Tecido MJ'}`,
    is_physical: true,
    fabric_id: purchaseMode.value === 'fabric' ? selectedFabric.value.id : 'own_fabric',
    fabric_name: fabricName,
    fabric_unit_price: fabricUnitPrice,
    simulation_url: simulationUrl,
    requested_scale: safeZoom.value,
    requested_print_width: finalPrintWidth.value,
    requested_print_height: finalPrintHeight.value
  }

  if (cartContext && cartContext.addToCarrinho) {
    cartContext.addToCarrinho(customStampPayload, productQuantity.value)
  }
  isGeneratingPrint.value = false
}

function handleAddDigitalToCart() {
  if (!activeStamp.value) return
  const digitalPayload = { ...activeStamp.value, is_physical: false }
  if (cartContext && cartContext.addToCarrinho) {
    cartContext.addToCarrinho(digitalPayload, 1)
  }
}

function goToCheckout() {
  router.push(`/marketplace/checkout?digital_stamp=${activeStamp.value.id}`)
}

async function handleFastWhatsappCheckout() {
  if (purchaseMode.value === 'fabric' && !selectedFabric.value) return;
  isGeneratingPrint.value = true;

  const simulationUrl = await captureAndUploadSimulation();

  let lineTotal = 0;
  let fabricName = '';
  if (purchaseMode.value === 'fabric') {
     lineTotal = currentFabricUnitPrice.value * productQuantity.value;
     fabricName = selectedFabric.value.name;
  } else if (purchaseMode.value === 'own_fabric') {
     lineTotal = printCostPerMeter * productQuantity.value;
     fabricName = 'Tecido do Cliente';
  }

  const attendantPhone = '5515991876055';

  let msg = `*OLÁ! GOSTARIA DE FINALIZAR UM PEDIDO DE PRODUÇÃO FÍSICA*\n\n`
  msg += `*Cliente:* ${userProfile.value.name}\n`
  msg += `*CNPJ/CPF:* ${userProfile.value.document || 'Não informado'}\n`
  msg += `*Local:* ${userProfile.value.location || 'Não informado'}\n\n`
  msg += `*PEDIDO:*\n`
  msg += `▪️ *${activeStamp.value.title}* (Ref: ${activeStamp.value.ref_code})\n`
  msg += `   Modo: ${purchaseMode.value === 'own_fabric' ? 'Estampar no Tecido do Cliente' : 'Tecido MJ'}\n`
  if (purchaseMode.value === 'fabric') {
    msg += `   Tecido Selecionado: ${fabricName}\n`
  }
  msg += `   Quantidade: ${productQuantity.value} ${purchaseMode.value === 'own_fabric' ? 'metros' : getUnitName(selectedFabric.value)}\n`
  msg += `   Tamanho Final do Quadro: *${finalPrintWidth.value}cm x ${finalPrintHeight.value}cm* (Escala: ${(safeZoom.value * 100).toFixed(0)}%)\n`
  msg += `   Subtotal: R$ ${formatPrice(lineTotal)}\n\n`
  msg += `*Simulação Visual de Escala:* ${simulationUrl || '(Não foi possível anexar)'}\n\n`

  msg += `*TOTAL ESTIMADO:* R$ ${formatPrice(lineTotal)}\n\n`
  msg += `Aguardando confirmação de disponibilidade e prazo.`

  window.open(`https://wa.me/${attendantPhone}?text=${encodeURIComponent(msg)}`, '_blank')

  isGeneratingPrint.value = false
}

// =======================================================
// FLUXOS DO PILOTO (PIX E WHATSAPP)
// =======================================================

async function handlePilotWhatsapp() {
    if (!pilotFabric.value || !activeStamp.value || !userProfile.value?.id) {
        alert("Por favor, faça login e selecione um tecido.");
        return;
    }

    isGeneratingPix.value = true;
    try {
        const amount = (pilotFabric.value.base_price || pilotFabric.value.price) * pilotQuantity.value;
        const simulationUrl = await captureAndUploadSimulation();

        // NÃO inserimos no banco de dados aqui. O Representante vai gerar o pedido manualmente depois.
        const attendantPhone = '5515991876055';
        let msg = `*OLÁ! GOSTARIA DE SOLICITAR UM PILOTO DE ESTAMPA*\n\n`
        msg += `*Cliente:* ${userProfile.value.name}\n`
        msg += `*CNPJ/CPF:* ${userProfile.value.document || 'Não informado'}\n\n`
        msg += `*DADOS DO PILOTO:*\n`
        msg += `▪️ *${activeStamp.value.title}* (Ref: ${activeStamp.value.ref_code})\n`
        msg += `   Tecido Selecionado: ${pilotFabric.value.name}\n`
        msg += `   Quantidade: ${pilotQuantity.value} metros\n`
        msg += `   Tipo de Aprovação: *${pilotApprovalType.value === 'digital' ? 'Digital (Foto/Vídeo)' : 'Física (Receber amostra)'}*\n`
        msg += `   Tamanho Final do Quadro: *${finalPrintWidth.value}cm x ${finalPrintHeight.value}cm* (Escala: ${(safeZoom.value * 100).toFixed(0)}%)\n`
        msg += `   Valor Estimado: R$ ${formatPrice(amount)}\n\n`
        msg += `*Simulação:* ${simulationUrl || '(Não foi possível anexar)'}\n\n`
        msg += `*Estou ciente do prazo mínimo de 20 dias úteis para a entrega do piloto.*\n`
        msg += `Aguardando link de pagamento ou chave PIX.`

        window.open(`https://wa.me/${attendantPhone}?text=${encodeURIComponent(msg)}`, '_blank')

    } catch(e) {
        console.error(e);
        alert("Erro ao enviar solicitação.");
    } finally {
        isGeneratingPix.value = false;
    }
}

async function generatePilotPix() {
    if (!pilotFabric.value || !activeStamp.value || !userProfile.value?.id) {
        alert("Faça o login e selecione uma base antes de continuar.");
        return;
    }

    isGeneratingPix.value = true;
    let createdPilotId = null;

    try {
        const amount = (pilotFabric.value.base_price || pilotFabric.value.price) * pilotQuantity.value;
        const amountInCents = Math.round(amount * 100);
        const cleanDocument = (userProfile.value.document || '00000000000').replace(/\D/g, '');

        // 1. Criar Piloto no Banco
        const { data: pilotRequest, error: dbError } = await supabase
            .from('pilot_requests')
            .insert({
                user_id: userProfile.value.id,
                stamp_id: activeStamp.value.id,
                fabric_id: pilotFabric.value.id,
                amount: amount,
                quantity_meters: pilotQuantity.value,
                status: 'pending_payment',
                payment_status: 'pending',
                representative_request: false,
                approval_type: pilotApprovalType.value
            })
            .select()
            .single();

        if (dbError) throw dbError;
        createdPilotId = pilotRequest.id;

        // 2. Gerar o PIX via Cora Proxy (mesma lógica do MarketplaceCheckout)
        const coraResponse = await coraApi.generatePix({
            amount: amountInCents,
            code: `PLT-${pilotRequest.id.substring(0,8)}`,
            customer: {
                name: userProfile.value.name || 'Cliente Piloto',
                identity: cleanDocument
            }
        }, MR_JACKY_CORA_ID);

        if (!coraResponse) {
            throw new Error('Retorno vazio da API Cora.');
        }

        const qrCodeCopyPaste = coraResponse.emv || coraResponse.payment_options?.pix?.emv || '';
        const coraInvoiceIdStr = coraResponse.id || '';

        if (!qrCodeCopyPaste) {
            throw new Error("Código PIX não retornado pelo gateway.");
        }

        // 3. Atualizar Tabela com dados do PIX e Abrir Modal
        await supabase.from('pilot_requests').update({
            pix_qr_code: qrCodeCopyPaste,
            payment_id: coraInvoiceIdStr
        }).eq('id', pilotRequest.id);

        pixData.value = {
            qrCodeBase64: '', // Não usamos mais backend pra renderizar qr-code base64, renderizamos com qrcode.vue
            copyPaste: qrCodeCopyPaste,
            txId: coraInvoiceIdStr,
            pilotId: pilotRequest.id
        };

        pilotApproved.value = false;
        showPixModal.value = true;
        startPixPolling(pilotRequest.id, amount, coraInvoiceIdStr);

    } catch(e: any) {
        console.error("Erro ao gerar PIX do Piloto:", e);

        // Rollback para não deixar o banco sujo com um pedido travado
        if (createdPilotId) {
             await supabase.from('pilot_requests').delete().eq('id', createdPilotId);
        }

        alert(`Não foi possível gerar o PIX de pagamento neste momento. Motivo: ${e.message || 'Falha de comunicação'}. Por favor, tente novamente ou solicite via representante.`);
    } finally {
        isGeneratingPix.value = false;
    }
}

function startPixPolling(pilotId: string, amount: number, coraInvoiceId: string) {
    if (pixPollingInterval) clearInterval(pixPollingInterval);

    pixPollingInterval = setInterval(async () => {
        try {
            const res = await coraApi.checkStatus(coraInvoiceId, MR_JACKY_CORA_ID);

            if (res && res.status === 'PAID') {
                pilotApproved.value = true;
                clearInterval(pixPollingInterval);

                // Atualiza status do Piloto
                await supabase.from('pilot_requests').update({
                    payment_status: 'paid',
                    status: 'paid'
                }).eq('id', pilotId);

                // Gerar o Recibo no Histórico do Cliente (Transactions)
                await supabase.from('client_transactions').insert({
                    user_id: userProfile.value.id,
                    transaction_type: 'pilot',
                    reference_id: pilotId,
                    amount: amount,
                    status: 'approved',
                    payment_method: 'PIX',
                    description: `Piloto de Estampa - Ref: ${activeStamp.value.ref_code} em ${pilotFabric.value.name}`
                });
            }
        } catch (e) {
            console.warn('Erro no polling do PIX do Piloto', e);
        }
    }, 4500);
}

function cancelPixPolling() {
    if (pixPollingInterval) clearInterval(pixPollingInterval);
    showPixModal.value = false;
}

function copyPixText() {
    navigator.clipboard.writeText(pixData.value.copyPaste).then(() => {
        alert('Código PIX Copiado!');
    });
}
</script>

<style scoped>
/* =========================================================
   ESTILOS PREMIUM DA PÁGINA DO PRODUTO (E-COMMERCE) E CORES #a14b12
========================================================= */

.product-view {
  --v-theme-primary: 161, 75, 18 !important; /* Cor Injetada: #a14b12 */
  --v-theme-primary-darken-1: 130, 55, 10 !important;
}

.view-wrap { padding-top: 82px; }
.product-view { min-height: calc(100vh - 82px); }

.loading-state {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  height: 60vh; gap: 16px; border-radius: 12px; margin: 40px auto; max-width: 600px;
  color: var(--text-muted);
}

.product-container { padding-top: 34px; padding-bottom: 60px; }

.product-breadcrumb {
  display: flex; align-items: center; gap: 12px; color: var(--text-muted);
  font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 20px;
}

.back-btn { border-radius: 8px !important; }

.product-grid {
  display: grid; grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
  gap: 32px; align-items: start;
}

/* =========================================================
   WORKSPACE GRID (Réguas e Malha de Fundo Infinita)
========================================================= */

.product-visual-column { display: flex; flex-direction: column; width: 100%; min-width: 0; }

.capture-wrapper {
  display: grid;
  grid-template-columns: 32px 1fr;
  grid-template-rows: 32px 1fr;
  position: relative;
  width: 100%;
  border-radius: 26px;
  overflow: hidden;
  background: linear-gradient(180deg, rgba(255,255,255,0.92) 0%, rgba(241,245,249,0.96) 100%);
  user-select: none;
  box-shadow: inset 0 0 0 1px rgba(148, 163, 184, 0.1), 0 24px 48px rgba(15,23,42,0.08);
}

.ps-corner {
  grid-column: 1;
  grid-row: 1;
  position: relative;
  z-index: 20;
  background: linear-gradient(180deg, rgba(255,255,255,0.92) 0%, rgba(241,245,249,0.96) 100%);
  border-right: 1px solid rgba(148, 163, 184, 0.22);
  border-bottom: 1px solid rgba(148, 163, 184, 0.22);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.9),
    0 8px 18px rgba(15,23,42,0.06);
  backdrop-filter: blur(12px);
}

.ps-ruler-h {
  grid-column: 2;
  grid-row: 1;
  position: relative;
  overflow: hidden;
  z-index: 10;
  background: linear-gradient(180deg, rgba(255,255,255,0.94) 0%, rgba(248,250,252,0.96) 100%);
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.88),
    0 10px 24px rgba(15,23,42,0.05);
  backdrop-filter: blur(10px);
}

.ruler-track-h { position: absolute; inset: 0; pointer-events: none; }
.ruler-cm-marker-h { position: absolute; top: 0; height: 100%; }
.marker-text-h {
  position: absolute; left: 6px; bottom: 4px; font-size: 9px;
  font-family: 'Inter', monospace; font-weight: 800; color: #475569; line-height: 1;
}
.marker-line-h { position: absolute; bottom: 0; left: 0; width: 1px; background: rgba(71, 85, 105, 0.62); }
.marker-line-h.major { height: 12px; background: rgba(15, 23, 42, 0.7); }
.marker-line-h.minor { height: 6px; background: rgba(100, 116, 139, 0.55); }

.ps-ruler-v {
  grid-column: 1;
  grid-row: 2;
  position: relative;
  overflow: hidden;
  z-index: 10;
  background: linear-gradient(180deg, rgba(255,255,255,0.94) 0%, rgba(248,250,252,0.96) 100%);
  border-right: 1px solid rgba(148, 163, 184, 0.18);
  box-shadow:
    inset 1px 0 0 rgba(255,255,255,0.88),
    10px 0 24px rgba(15,23,42,0.04);
  backdrop-filter: blur(10px);
}

.ruler-track-v { position: absolute; inset: 0; pointer-events: none; }
.ruler-cm-marker-v { position: absolute; left: 0; width: 100%; }
.marker-text-v {
  position: absolute; right: 10px; top: -4px; font-size: 9px;
  font-family: 'Inter', monospace; font-weight: 800; color: #475569; line-height: 1;
}
.marker-line-v { position: absolute; right: 0; top: 0; height: 1px; background: rgba(71, 85, 105, 0.62); }
.marker-line-v.major { width: 12px; background: rgba(15, 23, 42, 0.7); }
.marker-line-v.minor { width: 6px; background: rgba(100, 116, 139, 0.55); }

.product-visual {
  grid-column: 2; grid-row: 2; position: relative; aspect-ratio: 1 / 1;
  background-color: #ffffff; display: flex; align-items: center; justify-content: center; overflow: hidden;
}

.grid-overlay {
  position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; z-index: 1; opacity: 0.8;
  background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px);
  background-size: var(--grid-size, 48px) var(--grid-size, 48px);
  background-position: var(--grid-position-x, 0px) var(--grid-position-y, 0px);
  background-repeat: repeat;
}

.simulation-badge {
  position: absolute; bottom: 8px; right: 12px; font-size: 10px; font-weight: 900;
  text-transform: uppercase; color: rgba(0,0,0,0.6); z-index: 5;
  background: rgba(255,255,255,0.8); padding: 4px 8px; border-radius: 6px;
}

.pattern-fill, .raw-stamp-fill, .mockup-base, .mockup-mask, .mockup-shadow { position: absolute; inset: 0; width: 100%; height: 100%; z-index: 2; }
.pattern-fill.full { inset: 0; }
.mockup-base, .mockup-shadow { object-fit: contain; pointer-events: none; }
.mockup-shadow { mix-blend-mode: multiply; }

/* =========================================================
   SELEÇÃO LAÇO LIVRE, RÉGUAS E TOOLTIP
========================================================= */

.lasso-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 100; }
.lasso-polygon { fill: rgba(var(--v-theme-primary), 0.15); stroke: rgb(var(--v-theme-primary)); stroke-width: 1.5px; stroke-dasharray: 6 6; animation: marching-ants 0.4s infinite linear; }
@keyframes marching-ants { to { stroke-dashoffset: -12; } }

.lasso-ruler-h {
  position: absolute; display: flex; flex-direction: column; align-items: center; pointer-events: none; z-index: 101; animation: fadeIn 0.3s ease;
}
.ruler-line-h {
  width: 100%; height: 2px; background: rgb(var(--v-theme-primary)); position: relative;
}
.ruler-line-h::before, .ruler-line-h::after {
  content: ''; position: absolute; top: -4px; width: 2px; height: 10px; background: rgb(var(--v-theme-primary));
}
.ruler-line-h::before { left: 0; } .ruler-line-h::after { right: 0; }
.ruler-label-h {
  margin-top: 4px; background: rgba(var(--v-theme-primary), 0.9); color: white; font-size: 10px; font-weight: 800; padding: 2px 6px; border-radius: 4px;
}

.lasso-ruler-v {
  position: absolute; display: flex; flex-direction: row; align-items: center; pointer-events: none; z-index: 101; animation: fadeIn 0.3s ease;
}
.ruler-line-v {
  height: 100%; width: 2px; background: rgb(var(--v-theme-primary)); position: relative;
}
.ruler-line-v::before, .ruler-line-v::after {
  content: ''; position: absolute; left: -4px; height: 2px; width: 10px; background: rgb(var(--v-theme-primary));
}
.ruler-line-v::before { top: 0; } .ruler-line-v::after { bottom: 0; }
.ruler-label-v {
  margin-left: 4px; background: rgba(var(--v-theme-primary), 0.9); color: white; font-size: 10px; font-weight: 800; padding: 2px 6px; border-radius: 4px; writing-mode: vertical-lr; transform: rotate(180deg);
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.dimensions-tooltip {
  position: absolute; background-color: #0b0f19; color: #ffffff; padding: 8px 10px; border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3); font-size: 0.75rem; display: flex; flex-direction: column; gap: 4px;
  font-family: monospace; white-space: nowrap; z-index: 101; pointer-events: none;
}
:deep(.custom-tooltip-dark) { background-color: #0b0f19 !important; color: #ffffff !important; font-weight: 800 !important; font-size: 11px !important; padding: 6px 12px !important; border-radius: 6px !important; }

.dim-mode-badge { font-size: 8px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.05em; padding: 2px 6px; border-radius: 4px; text-align: center; color: white; margin-bottom: 2px; }
.dim-row { display: grid; grid-template-columns: 20px 60px 1fr; gap: 8px; align-items: center; }
.dim-row span:first-child { font-weight: 700; color: rgb(var(--v-theme-primary)); }
.dim-row span:nth-child(2) { text-align: right; color: #aeb5c0; }
.dim-cm { font-weight: 600; text-align: right; color: white; }

/* =========================================================
   SUBSTITUIÇÃO DE COR E TOOLBAR
========================================================= */

.color-processing-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.5); backdrop-filter: blur(4px); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 200; }
.color-picker-wrapper { width: 42px; height: 42px; border-radius: 12px; overflow: hidden; border: 2px solid white; }
.color-picker-input { width: 200%; height: 200%; transform: translate(-25%, -25%); border: none; padding: 0; }

.modern-tools-panel { display: flex; flex-direction: column; gap: 16px; }
.modern-tools-panel > .d-flex:first-child { display: grid !important; grid-template-columns: auto minmax(280px, 1fr); gap: 14px; align-items: center !important; }
.glass-toolbar, .zoom-capsule, .tool-options-bar { background: linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(248,250,252,0.95) 100%); border: 1px solid rgba(148, 163, 184, 0.18); box-shadow: 0 18px 34px rgba(15,23,42,0.08), inset 0 1px 0 rgba(255,255,255,0.82); backdrop-filter: blur(16px); }

.glass-toolbar { display: inline-flex; align-items: center; gap: 8px; padding: 8px; border-radius: 20px; width: max-content; }
.tool-btn { width: 44px; height: 44px; border: 0; background: transparent; border-radius: 14px; display: inline-flex; align-items: center; justify-content: center; color: #64748b; transition: transform 0.18s ease, background 0.18s ease, color 0.18s ease, box-shadow 0.18s ease; }
.tool-btn:hover { transform: translateY(-1px); background: rgba(var(--v-theme-primary), 0.08); color: rgb(var(--v-theme-primary)); }
.tool-btn.active { background: linear-gradient(180deg, rgba(var(--v-theme-primary), 0.96) 0%, rgba(var(--v-theme-primary), 0.86) 100%); color: white; box-shadow: 0 10px 20px rgba(var(--v-theme-primary), 0.28); }
.help-btn { color: #8b5cf6; }
.help-btn:hover { background: rgba(139, 92, 246, 0.12); color: #8b5cf6; }

.toolbar-divider, .toolbar-divider-vertical { background: linear-gradient(180deg, rgba(148,163,184,0.12) 0%, rgba(148,163,184,0.4) 50%, rgba(148,163,184,0.12) 100%); }
.toolbar-divider { width: 1px; height: 24px; margin: 0 2px; }
.toolbar-divider-vertical { width: 1px; height: 38px; }

.zoom-capsule { display: inline-flex; align-items: center; gap: 4px; min-height: 60px; border-radius: 22px; padding: 8px 10px; }
.zoom-btn { width: 42px; height: 42px; border: 0; background: rgba(255,255,255,0.6); border-radius: 12px; display: grid; place-items: center; color: var(--text-main); transition: background 0.2s ease, transform 0.2s ease; }
.zoom-btn:hover { transform: translateY(-1px); background: rgba(var(--v-theme-primary), 0.08); }
.zoom-value { min-width: 58px; text-align: center; font-size: 13px; font-weight: 900; color: rgb(var(--v-theme-primary)); font-family: monospace; }

.tool-options-bar { min-height: 76px; border-radius: 22px !important; }
.mj-slider { appearance: none; height: 7px; border-radius: 999px; background: rgba(148, 163, 184, 0.26); outline: none; }
.mj-slider::-webkit-slider-thumb { -webkit-appearance: none; width: 22px; height: 22px; border-radius: 50%; background: rgb(var(--v-theme-primary)); box-shadow: 0 4px 12px rgba(15,23,42,0.25); cursor: pointer; border: 3px solid white; }

/* =========================================================
   MOCKUPS E COMPRAS
========================================================= */

.mockup-selector { margin-top: 24px; }
.mockup-selector-title { margin-bottom: 12px; color: var(--text-main); font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; }
.mockup-carousel-wrapper { display: flex; align-items: center; gap: 12px; }

.carousel-arrow { flex-shrink: 0; width: 36px; height: 36px; border-radius: 50%; background: var(--bg-surface); border: 1px solid var(--border-color); color: var(--text-main); display: grid; place-items: center; cursor: pointer; transition: all 0.2s ease; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
.carousel-arrow:hover { background: rgba(var(--v-theme-primary), 0.1); color: rgb(var(--v-theme-primary)); border-color: rgba(var(--v-theme-primary), 0.3); transform: scale(1.05); }

.mockup-list { display: flex; flex-wrap: nowrap; gap: 16px; overflow-x: auto; scroll-snap-type: x mandatory; padding-bottom: 8px; -webkit-overflow-scrolling: touch; scrollbar-width: none; flex: 1; }
.mockup-list::-webkit-scrollbar { display: none; }
.mockup-thumb { flex: 0 0 100px; aspect-ratio: 1 / 1; padding: 8px; border-radius: 12px; background-color: var(--bg-surface-2); border: 1px solid var(--border-color); overflow: hidden; cursor: pointer; transition: all 0.2s ease; scroll-snap-align: start; display: flex; align-items: center; justify-content: center; }
.mockup-thumb.active { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 2px rgba(var(--v-theme-primary), 0.15); background-color: rgba(var(--v-theme-primary), 0.05); }
.mockup-thumb img { width: 100%; height: 100%; object-fit: contain; border-radius: 8px; }
.mockup-thumb-fallback { width: 100%; height: 100%; display: grid; place-items: center; color: var(--text-muted); }

.product-info-column { position: sticky; top: 110px; min-width: 0; }
.product-kicker { display: inline-flex; min-height: 34px; align-items: center; padding: 0 14px; border-radius: 6px; background: rgba(var(--v-theme-primary), 0.12); color: rgb(var(--v-theme-primary)); font-size: 12px; font-weight: 800; letter-spacing: 0.1em; text-transform: uppercase; }
.product-title { font-size: clamp(1.8rem, 3.5vw, 4rem); color: var(--text-main); letter-spacing: -0.04em; line-height: 1.05; }
.favorite-btn { border-radius: 14px !important; transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
.favorite-btn:active { transform: scale(0.85); }
.product-description { margin: 16px 0 0; font-size: 1.05rem; color: var(--text-soft); line-height: 1.7; }
.product-highlights { display: flex; flex-direction: column; gap: 16px; margin-top: 24px; }
.highlight-card { padding: 16px; display: flex; align-items: center; gap: 16px; border-radius: 12px; }
.highlight-label { color: var(--text-muted); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.08em; }
.highlight-value { margin-top: 4px; font-weight: 800; font-size: 1rem; }

.buy-module { margin-top: 32px; border-radius: 12px; overflow: visible; }
.buy-tabs { display: flex; border-bottom: 1px solid var(--border-color); background: var(--bg-surface); border-radius: 12px 12px 0 0; flex-wrap: wrap; }
.buy-tab { flex: 1 1 auto; min-height: 64px; background: transparent; border: 0; color: var(--text-muted); font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; transition: all 0.2s ease; padding: 8px 16px; }
.buy-tab.active { background: var(--bg-surface-2); color: var(--text-main); box-shadow: inset 0 -3px 0 rgb(var(--v-theme-primary)); }

.buy-content { padding: 28px; background: var(--bg-surface-2); border-radius: 0 0 12px 12px; }
.buy-section-title { color: var(--text-main); font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 16px; }

/* --- DROPDOWN CUSTOMIZADO DE TECIDOS --- */
.custom-select-wrapper { position: relative; width: 100%; }
.mj-custom-select { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-radius: 8px; cursor: pointer; transition: all 0.2s ease; user-select: none; }
.mj-custom-select:hover { border-color: rgba(var(--v-theme-primary), 0.4); }
.mj-custom-select.is-open { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1); }
.select-content { flex: 1; display: flex; justify-content: space-between; align-items: center; padding-right: 16px; }
.placeholder-text { color: var(--text-muted); font-size: 1.05rem; font-weight: 600; }
.fabric-info-compact { display: flex; flex-direction: column; }
.fabric-info-compact .fabric-name { font-size: 1.05rem; font-weight: 800; color: var(--text-main); }
.fabric-price-tag-compact { display: flex; align-items: baseline; background: var(--bg-surface); padding: 6px 12px; border-radius: 8px; }
.chevron-icon { color: var(--text-muted); transition: transform 0.3s ease; }
.chevron-icon.rotate { transform: rotate(180deg); color: rgb(var(--v-theme-primary)); }
.dropdown-overlay { position: fixed; inset: 0; z-index: 40; }
.mj-custom-dropdown { position: absolute; top: calc(100% + 8px); left: 0; right: 0; z-index: 50; max-height: 440px; overflow-y: auto; border-radius: 12px; padding: 16px; background: rgb(var(--v-theme-surface)); border: 1px solid var(--border-strong); box-shadow: 0 24px 54px rgba(0,0,0,0.25) !important; }
.dropdown-header { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: var(--text-muted); margin-bottom: 12px; padding-left: 4px; }
.mj-custom-dropdown::-webkit-scrollbar { width: 8px; }
.mj-custom-dropdown::-webkit-scrollbar-thumb { background: var(--border-strong); border-radius: 999px; }
.fabric-options { display: flex; flex-direction: column; gap: 12px; }
.fabric-card { display: flex; align-items: center; padding: 16px; border-radius: 8px; border: 1px solid var(--border-color); background: var(--bg-surface-2); cursor: pointer; transition: all 0.2s ease; }
.fabric-card:hover { background: var(--bg-surface); border-color: rgba(var(--v-theme-primary), 0.5); }
.fabric-card.active { border-color: rgb(var(--v-theme-primary)); background: rgba(var(--v-theme-primary), 0.05); box-shadow: 0 4px 12px rgba(var(--v-theme-primary), 0.1); }
.fabric-radio { width: 20px; height: 20px; border-radius: 50%; border: 2px solid var(--border-strong); margin-right: 16px; display: grid; place-items: center; flex-shrink: 0; }
.fabric-card.active .fabric-radio { border-color: rgb(var(--v-theme-primary)); }
.fabric-card.active .radio-inner { width: 10px; height: 10px; background: rgb(var(--v-theme-primary)); border-radius: 50%; }
.fabric-info { flex: 1; display: flex; flex-direction: column; }
.fabric-name { font-size: 1.05rem; font-weight: 800; color: var(--text-main); }
.fabric-desc { font-size: 0.85rem; color: var(--text-muted); margin-top: 4px; }
.tier-tags { margin-top: 8px; }
.tier-tag { display: inline-flex; align-items: center; font-size: 10px; font-weight: 800; text-transform: uppercase; color: #10b981; background: rgba(16, 185, 129, 0.1); padding: 4px 8px; border-radius: 6px; }
.fabric-price-tag { display: flex; align-items: baseline; background: var(--bg-surface); padding: 8px 12px; border-radius: 8px; margin-left: 12px; }
.price-val { font-weight: 800; color: var(--text-main); font-size: 1.05rem; }
.price-un { font-weight: 700; color: var(--text-muted); font-size: 0.8rem; margin-left: 2px; }
.empty-fabrics { padding: 24px; text-align: center; color: var(--text-muted); border-radius: 12px; }

/* --- SELETOR DE METRAGEM E DESCONTOS --- */
.buy-row { display: grid; grid-template-columns: minmax(180px, 1fr) minmax(200px, 1.5fr); gap: 16px; align-items: stretch; }
.elegant-qty-wrapper { display: flex; align-items: center; justify-content: space-between; min-height: 72px; border-radius: 12px; padding: 6px; background: var(--bg-surface); transition: opacity 0.3s; }
.elegant-qty-wrapper.disabled { opacity: 0.5; pointer-events: none; }
.eq-btn { width: 52px; height: 100%; border-radius: 8px; background: var(--bg-surface-2); color: var(--text-main); display: grid; place-items: center; transition: all 0.2s; cursor: pointer; }
.eq-btn:hover:not(:disabled) { background: rgba(var(--v-theme-primary), 0.12); color: rgb(var(--v-theme-primary)); }
.eq-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.eq-display { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; min-width: 60px; }
.eq-input { font-size: 1.6rem; font-weight: 900; color: var(--text-main); text-align: center; width: 100%; outline: none; background: transparent; border: none; -moz-appearance: textfield; }
.eq-input::-webkit-outer-spin-button, .eq-input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
.eq-unit { font-size: 0.75rem; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
.wholesale-info { border-radius: 12px; padding: 14px; display: flex; flex-direction: column; justify-content: center; }
.wholesale-title { font-size: 0.8rem; font-weight: 700; color: var(--text-muted); margin-bottom: 8px; }
.wholesale-tiers { display: flex; flex-wrap: wrap; gap: 8px; }
.tier-pill { font-size: 0.8rem; font-weight: 700; color: var(--text-soft); background: var(--bg-surface-2); padding: 4px 10px; border-radius: 6px; transition: all 0.2s; }
.tier-pill.active-tier { background: #10b981; color: #fff; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3); }

/* --- BREAKDOWN DIDÁTICO --- */
.price-breakdown { padding: 20px; border-radius: 12px; display: flex; flex-direction: column; gap: 12px; }
.breakdown-row { display: flex; justify-content: space-between; align-items: center; font-size: 0.95rem; color: var(--text-soft); }
.breakdown-row span:last-child { font-weight: 700; color: var(--text-main); }
.strike-through { text-decoration: line-through; opacity: 0.6; }
.discount-row { background: rgba(16, 185, 129, 0.08); padding: 8px 12px; border-radius: 6px; margin: -4px -12px; }
.breakdown-divider { height: 1px; background: var(--border-color); margin: 4px 0; }
.total-unit { font-size: 1.1rem; }
.total-unit span:last-child { font-size: 1.2rem; font-weight: 900; }
.final-total-display { display: flex; align-items: center; justify-content: space-between; padding: 0 8px; }
.total-label { font-size: 1rem; font-weight: 800; color: var(--text-main); }
.total-value { font-size: 2rem; font-weight: 900; letter-spacing: -0.02em; }

/* --- BOTÕES DE AÇÃO --- */
.action-stack { display: flex; flex-direction: column; }
.buy-btn { border-radius: 8px !important; font-weight: 800 !important; letter-spacing: 0.02em; }
.checkout-btn { background: linear-gradient(135deg, #10b981, #059669) !important; color: white !important; }
.whatsapp-pulse-btn { background-color: #25d366 !important; color: #ffffff !important; animation: pulse-green 2s infinite; border: none !important; }

@keyframes pulse-green {
  0% { box-shadow: 0 0 0 0 rgba(37, 211, 102, 0.7); }
  70% { box-shadow: 0 0 0 10px rgba(37, 211, 102, 0); }
  100% { box-shadow: 0 0 0 0 rgba(37, 211, 102, 0); }
}

.pulse-animation {
  animation: scale-pulse 1.5s infinite;
}

@keyframes scale-pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}

/* --- ESTILO ABA DIGITAL --- */
.digital-specs { display: flex; flex-direction: column; gap: 16px; margin-bottom: 24px; }
.spec-item { display: flex; align-items: center; gap: 16px; }
.spec-icon { width: 42px; height: 42px; border-radius: 8px; display: grid; place-items: center; flex-shrink: 0; }
.spec-item div { display: flex; flex-direction: column; }
.spec-item strong { color: var(--text-main); font-size: 1rem; font-weight: 800; }
.spec-item span { color: var(--text-muted); font-size: 0.85rem; margin-top: 2px; }
.digital-price-box { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-radius: 12px; background: var(--bg-surface); }
.digital-price-label { color: var(--text-muted); font-size: 13px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; }
.digital-price-value { color: var(--text-main); font-size: 2rem; font-weight: 800; letter-spacing: -0.02em; }

/* --- RELACIONADOS --- */
.related-block { padding: 56px 0 20px; }
.section-head { display: flex; align-items: end; justify-content: space-between; gap: 24px; margin-bottom: 24px; }
.eyebrow { display: inline-flex; align-items: center; min-height: 30px; padding: 0 14px; border-radius: 999px; background: rgba(var(--v-theme-primary), 0.12); color: rgb(var(--v-theme-primary)); font-weight: 800; font-size: 12px; letter-spacing: 0.12em; text-transform: uppercase; }
.section-title { margin: 14px 0 0; color: var(--text-main); letter-spacing: -0.04em; line-height: 1.02; font-size: clamp(1.8rem, 2.2vw, 2.6rem); }
.stamp-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 22px; }
.stamp-card { border-radius: 12px; transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease; overflow: hidden; cursor: pointer; }
.stamp-card:hover { transform: translateY(-4px); box-shadow: var(--hover-shadow); border-color: rgba(var(--v-theme-primary), 0.36); }
.stamp-media-wrap { aspect-ratio: 1 / 1; overflow: hidden; position: relative; background: var(--bg-surface-2); }
.stamp-media { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s ease; display: block; }
.stamp-card:hover .stamp-media { transform: scale(1.05); }
.stamp-meta { padding: 16px; }
.stamp-ref { color: var(--text-muted); font-size: 11px; font-weight: 800; letter-spacing: 0.12em; text-transform: uppercase; margin-bottom: 6px; display: block; }
.stamp-title { margin: 0; color: var(--text-main); font-weight: 800; letter-spacing: -0.02em; }

/* Transições */
.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.25s ease; }
.fade-slide-enter-from, .fade-slide-leave-to { opacity: 0; transform: translateY(-10px); }
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

/* =========================================================
   RESPONSIVIDADE GERAL
========================================================= */
@media (max-width: 1199px) { .product-grid { grid-template-columns: 1fr; } .product-info-column { position: static; } }
@media (max-width: 959px) { .product-highlights { grid-template-columns: 1fr; } .stamp-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }

@media (max-width: 767px) {
  .product-container { padding-top: 16px; padding-bottom: 32px; }
  .product-title { font-size: 1.6rem; margin-top: 12px; line-height: 1.15; letter-spacing: -0.02em; }
  .capture-wrapper { width: 100%; max-width: 100%; height: auto; border-radius: 16px; }

  .product-description { font-size: 0.9rem; line-height: 1.6; color: var(--text-soft); }
  .buy-section-title { font-size: 11px; letter-spacing: 0.08em; margin-bottom: 12px; }

  /* TOOLBAR, ZOOM E NAVEGAÇÃO */
  .modern-tools-panel > .d-flex:first-child { display: flex !important; flex-direction: column !important; gap: 10px !important; width: 100%; }
  .glass-toolbar { width: 100%; justify-content: space-between; padding: 6px 10px; border-radius: 12px; }
  .tool-btn { width: 38px; height: 38px; border-radius: 8px; }

  .zoom-capsule { width: 100%; display: flex !important; justify-content: space-between; margin: 0; min-height: 46px; border-radius: 12px; padding: 6px 12px; }
  .zoom-btn { width: 34px; height: 34px; border-radius: 8px; }
  .zoom-value { font-size: 11px; min-width: 48px; }

  /* OPÇÕES DE FERRAMENTAS */
  .tool-options-bar { flex-direction: column !important; align-items: stretch !important; width: 100%; gap: 12px !important; padding: 14px !important; border-radius: 12px !important; box-sizing: border-box; }
  .tool-options-bar .v-btn-toggle { flex-direction: column !important; height: auto !important; width: 100%; }
  .tool-options-bar .v-btn-toggle .v-btn { width: 100% !important; min-height: 42px !important; border-radius: 6px !important; font-size: 10px !important; letter-spacing: 0.03em; }
  .tool-options-bar .d-flex.flex-column[style*="max-width: 300px"] { min-width: 100% !important; max-width: 100% !important; }
  .color-picker-wrapper { width: 38px; height: 38px; border-radius: 8px; }
  .tool-options-bar .v-btn[color="error"], .tool-options-bar .bg-error { width: 100% !important; min-height: 42px !important; margin-top: 6px; font-size: 11px !important; border-radius: 8px !important; }

  /* ABAS DE COMPRA */
  .buy-tabs { flex-direction: row; gap: 6px; padding: 6px; background: transparent; border-bottom: none; border-radius: 0; }
  .buy-tab { flex: 1 1 45%; min-height: 44px; font-size: 10px; padding: 6px 4px; white-space: normal; line-height: 1.2; text-align: center; border-radius: 8px; background: var(--bg-surface-2); border: 1px solid var(--border-color); display: flex; flex-direction: column; align-items: center; justify-content: center; }
  .buy-tab.active { box-shadow: none; background: var(--bg-surface); border: 1px solid rgb(var(--v-theme-primary)); font-weight: 800; }
  .buy-content { padding: 16px 14px; margin-top: 0; border-radius: 12px; border: 1px solid var(--border-color); }

  /* FORMULÁRIOS E SELECTS */
  .mj-custom-select { padding: 12px 14px; min-height: 52px; border-radius: 8px; }
  .fabric-info-compact .fabric-name { font-size: 0.95rem; }
  .fabric-price-tag-compact .price-val { font-size: 0.95rem; }
  .mj-custom-dropdown { padding: 10px; max-height: 60vh; width: 100%; box-sizing: border-box; }

  .buy-row { grid-template-columns: 1fr; gap: 12px; }
  .elegant-qty-wrapper { min-height: 52px; padding: 4px; border-radius: 8px; }
  .eq-btn { width: 42px; border-radius: 6px; }
  .eq-input { font-size: 1.2rem; }

  .final-total-display { flex-direction: column; align-items: flex-start; gap: 2px; padding: 0 4px; }
  .total-label { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; }
  .total-value { font-size: 1.5rem; }

  /* MOCKUPS E RELACIONADOS */
  .carousel-arrow { display: none; }
  .mockup-thumb { flex: 0 0 60px; padding: 4px; border-radius: 8px; }
  .stamp-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
  .stamp-meta { padding: 10px; }
  .stamp-title { font-size: 0.85rem; }
  .stamp-ref { font-size: 9px; }
}
</style>
