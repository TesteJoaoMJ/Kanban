<template>
  <section class="d-flex flex-column gap-6 position-relative h-100">

    <div class="hero-enterprise-card position-relative overflow-hidden bg-surface border shadow-sm rounded-xl pa-8 w-100">
        <div class="position-relative z-10 w-100" style="max-width: 800px;">
          <h2 class="text-h4 font-weight-black m-0 mb-3 text-high-emphasis" style="letter-spacing: -0.02em;">Gerenciador de Estampas</h2>
        </div>
        <div class="hero-watermark-icon d-none d-md-flex pointer-events-none">
           <v-icon color="primary">mdi-texture-box</v-icon>
        </div>
    </div>

    <div v-if="!selectedFolder" class="d-flex flex-column gap-5 pb-8">
      <div class="d-flex align-center justify-space-between mt-2 px-2">
        <h3 class="text-h6 font-weight-black text-high-emphasis m-0">Explorar Cofre</h3>
        <span class="text-caption font-weight-bold text-medium-emphasis text-uppercase tracking-widest">{{ props.stamps.length }} Ativos</span>
      </div>

      <div class="modern-folder-grid">
        <article class="folder-card master-folder cursor-pointer hover-elevate" @click="openFolder('all')">
          <div class="folder-icon-wrap bg-primary-lighten-5">
             <v-icon size="32" color="primary">mdi-layers-triple</v-icon>
          </div>
          <div class="folder-info">
            <h4 class="folder-title text-primary">Todo o Acervo</h4>
            <div class="folder-meta">
              <span class="folder-count bg-primary text-white">{{ props.stamps.length }}</span>
              <span class="folder-desc">Ver todas as estampas</span>
            </div>
          </div>
        </article>

        <article
          v-for="cat in props.categories"
          :key="cat.id"
          class="folder-card cursor-pointer hover-elevate bg-surface border"
          @click="openFolder(cat.id)"
        >
          <div class="folder-icon-wrap bg-background border">
             <v-icon size="28" class="text-medium-emphasis">mdi-folder-outline</v-icon>
          </div>
          <div class="folder-info">
            <h4 class="folder-title text-high-emphasis" :title="cat.name">{{ cat.name }}</h4>
            <div class="folder-meta">
              <span class="folder-count bg-background border text-medium-emphasis">{{ getStampCountByCategory(cat.id) }}</span>
              <span class="folder-desc">Arquivos vinculados</span>
            </div>
          </div>
        </article>
      </div>
    </div>

    <div v-else class="d-flex flex-column gap-6 pb-12">
      <section class="bg-surface border rounded-xl pa-6 sticky-toolbar z-10 shadow-sm">
        <div class="d-flex flex-column gap-4">

          <div class="d-flex align-center gap-2 text-caption font-weight-bold text-uppercase tracking-widest">
             <span class="cursor-pointer text-medium-emphasis hover-text-primary transition-colors" @click="selectedFolder = null">
               <v-icon size="14" start class="mb-1">mdi-folder-multiple-outline</v-icon> Acervo
             </span>
             <v-icon size="16" class="text-disabled">mdi-chevron-right</v-icon>
             <span class="text-primary">{{ selectedFolder === 'all' ? 'Todas as Estampas' : getCategoryName(selectedFolder) }}</span>
          </div>

          <div class="d-flex flex-column flex-xl-row align-xl-center justify-space-between gap-4">
            <div class="overflow-hidden pr-2">
              <h4 class="text-h5 font-weight-black lh-1 mb-2 text-high-emphasis text-truncate">{{ selectedFolder === 'all' ? 'Todo o Acervo' : getCategoryName(selectedFolder) }}</h4>
              <p class="text-body-2 text-medium-emphasis m-0 text-truncate">Gerencie, otimize e edite os arquivos desta coleção.</p>
            </div>

            <div class="d-flex flex-wrap align-center gap-3">
              <v-btn color="secondary" variant="tonal" prepend-icon="mdi-checkbox-multiple-marked-outline" @click="selectAllStamps" class="text-none font-weight-bold rounded-lg flex-grow-1 flex-xl-grow-0" size="large">
                Selecionar Tudo
              </v-btn>

              <v-btn color="warning" variant="tonal" prepend-icon="mdi-image-size-select-actual" :loading="isCompressingFolder" @click="compressFolderStamps" class="text-none font-weight-bold rounded-lg flex-grow-1 flex-xl-grow-0" size="large">
                Otimizar
                <span v-if="isCompressingFolder" class="ml-1">({{ compressionProgress.current }}/{{ compressionProgress.total }})</span>
              </v-btn>

              <v-btn color="indigo" variant="tonal" prepend-icon="mdi-auto-fix" :loading="isAutoMatching" @click="runAutoMatch" class="text-none font-weight-bold rounded-lg flex-grow-1 flex-xl-grow-0" size="large">
                Auto-Match R2
              </v-btn>

              <div class="bg-background border d-flex align-center px-4 rounded-lg flex-grow-1" style="height: 44px; min-width: 250px;">
                <v-icon size="20" class="text-medium-emphasis mr-2">mdi-magnify</v-icon>
                <input v-model="searchQuery" type="text" placeholder="Buscar estampa..." class="w-100 outline-none text-body-1 text-high-emphasis bg-transparent" />
              </div>
            </div>
          </div>
        </div>
      </section>

      <div class="modern-stamp-grid">
        <article
          v-for="stamp in paginatedStamps"
          :key="stamp.id"
          class="bg-surface border rounded-xl overflow-hidden d-flex flex-column h-100 cursor-pointer hover-elevate stamp-card enterprise-card"
          @click="openStampDrawer(stamp)"
          :class="{ 'border-primary': selectedStamps.includes(stamp.id) }"
        >
          <div class="position-absolute top-2 left-2 z-10" @click.stop>
            <input type="checkbox" :value="stamp.id" v-model="selectedStamps" class="stamp-checkbox cursor-pointer" style="width: 22px; height: 22px; background: white; border-radius: 6px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" />
          </div>

          <div class="position-relative w-100 bg-background flex-shrink-0 border-b" style="padding-top: 100%;">
            <v-img v-if="stamp.main_image_url" :src="stamp.main_image_url" class="position-absolute top-0 left-0 w-100 h-100 bg-background" cover></v-img>
            <div v-else class="position-absolute top-0 left-0 w-100 h-100 d-flex align-center justify-center text-medium-emphasis text-caption">Sem Imagem</div>
          </div>

          <div class="pa-4 d-flex flex-column flex-grow-1 bg-surface">
            <div class="d-flex justify-space-between align-start mb-2">
              <div class="overflow-hidden pr-2">
                  <span class="text-[10px] font-mono font-weight-bold text-primary bg-primary-lighten-5 border border-primary px-1 rounded lh-1">{{ stamp.ref_code || 'S/REF' }}</span>
                  <h4 class="text-body-2 font-weight-bold text-high-emphasis m-0 mt-1" style="line-height: 1.3; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">
                    {{ stamp.title }}
                  </h4>
              </div>
              <span class="text-success font-weight-black text-caption flex-shrink-0">R$ {{ formatPrice(stamp.digital_price || 599) }}</span>
            </div>

            <div class="d-flex gap-2 mb-3 mt-auto flex-wrap">
               <v-chip size="x-small" :color="stamp.is_active ? 'success' : 'grey'" variant="flat" class="font-weight-bold px-2 shadow-sm">
                   <v-icon start size="10">{{ stamp.is_active ? 'mdi-eye-outline' : 'mdi-eye-off-outline' }}</v-icon>
                   {{ stamp.is_active ? 'Ativa' : 'Oculta' }}
               </v-chip>
               <v-chip size="x-small" :color="stamp.digital_file_url ? 'indigo' : 'error'" variant="flat" class="font-weight-bold px-2 shadow-sm">
                   <v-icon start size="10">{{ stamp.digital_file_url ? 'mdi-cloud-check' : 'mdi-cloud-off-outline' }}</v-icon>
                   {{ stamp.digital_file_url ? 'R2 Linkado' : 'Sem PSD' }}
               </v-chip>
               <v-chip size="x-small" color="blue" variant="flat" class="font-weight-bold px-2 shadow-sm">
                   <v-icon start size="10">mdi-ruler</v-icon>
                   {{ stamp.width_cm || 50 }}x{{ stamp.height_cm || 50 }}cm
               </v-chip>
            </div>

            <div class="d-flex justify-space-between align-center mt-1 pt-3 border-t">
               <div class="text-caption font-weight-bold" :class="stamp.stamp_type === 'Barrado' ? 'text-warning' : 'text-primary'">
                  <v-icon size="14" start>{{ stamp.stamp_type === 'Barrado' ? 'mdi-border-bottom' : 'mdi-texture' }}</v-icon>
                  {{ stamp.stamp_type || 'Corrida' }}
               </div>
               <div class="d-flex gap-1">
                  <v-btn icon="mdi-magnify" size="small" variant="tonal" class="text-medium-emphasis rounded" @click.stop="openImageViewer(stamp.main_image_url, stamp.title)"></v-btn>
                  <v-btn icon="mdi-pencil" size="small" variant="tonal" color="primary" class="rounded" @click.stop="openStampDrawer(stamp)"></v-btn>
                  <v-btn icon="mdi-delete" size="small" variant="tonal" color="error" class="rounded" @click.stop="deleteStampDirect(stamp)"></v-btn>
               </div>
            </div>
          </div>
        </article>
      </div>

      <div v-if="filteredFolderStamps.length === 0" class="py-16 d-flex flex-column align-center justify-center bg-surface border rounded-xl shadow-sm">
         <v-icon size="64" class="text-disabled mb-4">mdi-texture-box</v-icon>
         <h3 class="text-h6 font-weight-black text-high-emphasis m-0">Nenhuma estampa encontrada</h3>
         <p class="text-body-2 text-medium-emphasis m-0 mt-2">Ajuste os filtros de busca ou adicione novos arquivos a esta pasta.</p>
      </div>

      <div class="d-flex justify-center mt-6" v-if="totalPages > 1">
        <v-pagination v-model="currentPage" :length="totalPages" :total-visible="7" color="primary" density="comfortable" rounded="circle"></v-pagination>
      </div>
    </div>

    <transition name="slide-up-fade">
      <div v-if="selectedStamps.length > 0" class="bulk-action-island">
        <div class="bulk-inner shadow-xl border">

          <div class="bulk-count">
            <span class="count-number">{{ selectedStamps.length }}</span>
            <span class="count-label">estampas selecionadas</span>
          </div>

          <div class="bulk-divider"></div>

          <button class="bulk-btn hover-primary" @click="showBulkDimensionsModal = true">
            <v-icon size="18" color="info" class="mr-2">mdi-ruler-square</v-icon> Medidas
          </button>

          <button class="bulk-btn hover-primary" @click="bulkUpdateStampType('Corrida')" :disabled="isBulkUpdating">
            <v-icon size="18" color="primary" class="mr-2">mdi-texture</v-icon> Corrida
          </button>

          <button class="bulk-btn hover-primary" @click="bulkUpdateStampType('Barrado')" :disabled="isBulkUpdating">
            <v-icon size="18" color="warning" class="mr-2">mdi-border-bottom</v-icon> Barrado
          </button>

          <div class="bulk-divider"></div>

          <div class="bulk-select-wrapper">
            <select
              @change="bulkUpdateCategory($event)"
              class="bulk-select text-body-2 font-weight-bold"
            >
              <option value="" disabled selected>Mover para pasta...</option>
              <option v-for="cat in props.categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
            </select>
            <v-icon size="16" class="select-chevron text-medium-emphasis">mdi-chevron-down</v-icon>
          </div>

          <div class="bulk-divider"></div>

          <button class="bulk-btn-icon bg-error-lighten-5 text-error ml-1" @click="selectedStamps = []" title="Cancelar seleção">
            <v-icon size="20">mdi-close</v-icon>
          </button>

        </div>
      </div>
    </transition>

    <div class="drawer-backdrop" v-if="showStampDrawer" @click.self="closeStampDrawer">
      <aside class="drawer-panel bg-surface d-flex flex-column h-100">

        <header class="drawer-header bg-surface border-b px-6 py-4 d-flex justify-space-between align-center flex-shrink-0 z-10">
          <div class="d-flex align-center gap-3">
            <div class="bg-primary-lighten-5 p-2 rounded-lg text-primary d-flex align-center justify-center">
              <v-icon size="24">{{ editStampForm.id ? 'mdi-pencil-ruler' : 'mdi-plus-box-outline' }}</v-icon>
            </div>
            <div>
              <div class="text-[10px] text-uppercase font-weight-bold text-primary tracking-widest mb-1 lh-1">Modo Estúdio</div>
              <h3 class="text-h6 font-weight-black m-0 lh-1 text-high-emphasis">{{ editStampForm.id ? 'Editar Estampa' : 'Nova Estampa' }}</h3>
            </div>
          </div>
          <v-btn icon="mdi-close" variant="tonal" size="small" class="text-medium-emphasis" @click="closeStampDrawer"></v-btn>
        </header>

        <div class="drawer-body bg-background flex-grow-1 custom-scrollbar overflow-y-auto px-6 py-6 pb-12">
          <form id="stampForm" @submit.prevent="saveStampToDb" class="d-flex flex-column gap-6">

            <section class="form-section">
              <div class="section-title">
                <v-icon size="16" color="primary" class="mr-2">mdi-image-outline</v-icon> Vitrine e Apresentação
              </div>
              <div class="bg-surface border rounded-xl pa-4">
                <div v-if="editStampForm.main_image_url" class="d-flex align-center gap-4">
                  <div class="position-relative flex-shrink-0 rounded-lg overflow-hidden border bg-background" style="width: 100px; height: 100px;">
                    <v-img :src="editStampForm.main_image_url" cover class="w-100 h-100"></v-img>
                  </div>
                  <div class="flex-grow-1">
                    <strong class="text-body-2 font-weight-black text-high-emphasis d-block mb-1">Capa do Produto</strong>
                    <div class="text-[11px] text-medium-emphasis mb-3">Recomendado: Arquivo 1:1 com rapport contínuo (Ex: 1080x1080).</div>
                    <div class="d-flex gap-2">
                      <v-btn variant="tonal" size="small" color="primary" class="text-none font-weight-bold rounded" @click="triggerRealImageUpload('stamp_main')">Alterar Capa</v-btn>
                      <v-btn variant="outlined" size="small" color="warning" class="text-none font-weight-bold rounded" @click.stop="compressSingleStamp(editStampForm)" :loading="isCompressingSingle">
                         <v-icon start size="14">mdi-auto-fix</v-icon> Otimizar WebP
                      </v-btn>
                    </div>
                  </div>
                </div>

                <div v-else class="border border-dashed rounded-lg pa-8 d-flex flex-column align-center justify-center cursor-pointer hover-bg-light transition-all" style="border-width: 2px !important;" @click="triggerRealImageUpload('stamp_main')">
                  <div class="bg-primary-lighten-5 p-3 rounded-circle mb-3">
                    <v-icon size="32" color="primary">mdi-cloud-upload</v-icon>
                  </div>
                  <strong class="text-body-1 font-weight-black text-high-emphasis">Upload da Arte de Vitrine</strong>
                  <span class="text-caption text-medium-emphasis mt-1">Formatos suportados: JPG, PNG, WEBP.</span>
                </div>
              </div>
            </section>

            <section class="form-section">
              <div class="section-title">
                <v-icon size="16" color="indigo" class="mr-2">mdi-cloud-lock-outline</v-icon> Cofre de Arquivo Fechado (Cloudflare R2)
              </div>
              <div class="bg-surface border rounded-xl pa-4">
                <div v-if="editStampForm.digital_file_url" class="bg-indigo-lighten-5 border border-indigo pa-4 rounded-lg d-flex align-center justify-space-between gap-4">
                  <div class="overflow-hidden">
                    <div class="d-flex align-center gap-2 mb-1">
                      <v-icon color="indigo" size="18">mdi-check-decagram</v-icon>
                      <strong class="text-indigo-darken-2 text-body-2 font-weight-bold">PSD Conectado com Sucesso</strong>
                    </div>
                    <div class="text-[11px] font-mono text-indigo-darken-1 text-truncate" :title="editStampForm.digital_file_url">
                      {{ editStampForm.digital_file_url.split('/').pop() || editStampForm.digital_file_url }}
                    </div>
                  </div>
                  <div class="d-flex flex-column gap-2 flex-shrink-0">
                    <v-btn size="x-small" variant="flat" color="indigo" class="text-none font-weight-bold rounded" @click="openR2Modal(editStampForm)">Trocar PSD</v-btn>
                    <v-btn size="x-small" variant="text" color="error" class="text-none font-weight-bold" @click="unlinkR2File">Remover</v-btn>
                  </div>
                </div>

                <div v-else class="d-flex align-center justify-space-between bg-background border border-dashed pa-4 rounded-lg">
                  <div>
                    <strong class="text-body-2 font-weight-bold text-high-emphasis d-block">Venda Digital Inativa</strong>
                    <span class="text-[11px] text-medium-emphasis">Vincule o arquivo em alta (.psd, .tif) para habilitar.</span>
                  </div>
                  <v-btn size="small" color="indigo" variant="flat" prepend-icon="mdi-link-variant" class="text-none font-weight-bold rounded" @click="openR2Modal(editStampForm)">
                    Vincular R2
                  </v-btn>
                </div>
              </div>
            </section>

            <section class="form-section">
              <div class="section-title">
                <v-icon size="16" class="text-high-emphasis mr-2">mdi-card-account-details-outline</v-icon> Identificação Base
              </div>
              <div class="bg-surface border rounded-xl pa-5 d-flex flex-column gap-4">

                <div class="d-flex gap-4">
                  <div style="flex: 1 1 30%;">
                    <label class="premium-label">REF</label>
                    <input type="text" v-model="editStampForm.ref_code" required class="premium-input text-primary font-weight-bold font-mono" placeholder="EX-001" />
                  </div>
                  <div style="flex: 1 1 70%;">
                    <label class="premium-label">Nome Oficial da Estampa</label>
                    <input type="text" v-model="editStampForm.title" required class="premium-input" placeholder="Ex: Floral Vintage Rose" />
                  </div>
                </div>

                <div>
                  <label class="premium-label">Descrição Conceitual</label>
                  <textarea v-model="editStampForm.description" rows="3" class="premium-input" style="resize: vertical;" placeholder="Descrição para compor a página de vendas..."></textarea>
                </div>

              </div>
            </section>

            <section class="form-section">
              <div class="section-title">
                <v-icon size="16" color="blue" class="mr-2">mdi-ruler-square</v-icon> Ficha Técnica do Design
              </div>
              <div class="bg-surface border rounded-xl pa-5">
                <div class="d-flex gap-4">
                  <div class="flex-grow-1">
                    <label class="premium-label">Estrutura do Rapport</label>
                    <select v-model="editStampForm.stamp_type" class="premium-input cursor-pointer">
                      <option value="Corrida">Corrida (Repetição Contínua)</option>
                      <option value="Barrado">Barrado (Fundo Acoplado)</option>
                    </select>
                  </div>
                  <div class="flex-grow-1">
                    <label class="premium-label">Largura Nativa (cm)</label>
                    <div class="premium-input-wrap">
                      <input type="number" step="0.1" min="1" v-model.number="editStampForm.width_cm" required class="premium-input with-unit" />
                      <span class="input-unit">cm</span>
                    </div>
                  </div>
                  <div class="flex-grow-1">
                    <label class="premium-label">Altura Nativa (cm)</label>
                    <div class="premium-input-wrap">
                      <input type="number" step="0.1" min="1" v-model.number="editStampForm.height_cm" required class="premium-input with-unit" />
                      <span class="input-unit">cm</span>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            <section class="form-section">
              <div class="section-title">
                <v-icon size="16" color="success" class="mr-2">mdi-tag-outline</v-icon> Comercial e Organização
              </div>
              <div class="bg-surface border rounded-xl pa-5 d-flex flex-column gap-4">

                <div class="d-flex gap-4">
                  <div class="flex-grow-1">
                    <label class="premium-label">Pasta / Coleção</label>
                    <select v-model="editStampForm.category_id" required class="premium-input cursor-pointer">
                      <option :value="null" disabled>Selecione uma pasta...</option>
                      <option v-for="cat in props.categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                    </select>
                  </div>
                  <div style="width: 160px;">
                    <label class="premium-label text-success">Preço Digital (R$)</label>
                    <input type="number" step="0.01" min="0" v-model.number="editStampForm.digital_price" required class="premium-input border-success text-success font-weight-black bg-green-lighten-5" />
                  </div>
                </div>

                <div class="bg-background border rounded-lg pa-4 d-flex justify-space-between align-center mt-2">
                  <div>
                    <div class="text-subtitle-2 font-weight-bold text-high-emphasis mb-1">Status de Visibilidade</div>
                    <div class="text-[11px] text-medium-emphasis">Permitir que clientes vejam esta estampa na vitrine da loja.</div>
                  </div>
                  <v-switch v-model="editStampForm.is_active" color="success" inset hide-details density="compact"></v-switch>
                </div>

              </div>
            </section>

          </form>
        </div>

        <footer class="drawer-footer bg-surface border-t px-6 py-4 d-flex justify-end gap-3 flex-shrink-0 z-10 sticky-bottom">
          <v-btn variant="outlined" size="large" class="rounded-lg text-none font-weight-bold border bg-background text-high-emphasis" @click="closeStampDrawer">Cancelar</v-btn>
          <v-btn color="primary" size="large" :loading="isSaving" @click="submitFormDirectly" elevation="0" class="font-weight-bold px-8 rounded-lg text-none shadow-soft">Salvar Estampa</v-btn>
        </footer>
      </aside>
    </div>

    <v-dialog v-model="showBulkDimensionsModal" max-width="400" persistent>
      <v-card class="rounded-xl bg-surface border" elevation="24">
        <v-card-title class="px-6 py-4 border-b d-flex justify-space-between align-center">
          <div class="d-flex align-center gap-2">
            <div class="bg-info-lighten-5 p-1 rounded text-info"><v-icon size="20">mdi-ruler-square</v-icon></div>
            <span class="text-h6 font-weight-bold text-high-emphasis lh-1">Medidas em Massa</span>
          </div>
          <v-btn icon="mdi-close" variant="tonal" size="small" @click="showBulkDimensionsModal = false"></v-btn>
        </v-card-title>

        <v-card-text class="pa-6">
          <v-alert color="info" variant="tonal" density="compact" class="mb-5 rounded-lg text-caption font-weight-medium">
            Aplicando dimensões idênticas a <strong>{{ selectedStamps.length }}</strong> estampas selecionadas.
          </v-alert>

          <div class="d-flex gap-4">
            <div class="flex-grow-1">
              <label class="premium-label">Largura Comum (cm)</label>
              <div class="premium-input-wrap">
                <input type="number" step="0.1" min="1" v-model.number="bulkWidth" class="premium-input with-unit" />
                <span class="input-unit">cm</span>
              </div>
            </div>
            <div class="flex-grow-1">
              <label class="premium-label">Altura Comum (cm)</label>
              <div class="premium-input-wrap">
                <input type="number" step="0.1" min="1" v-model.number="bulkHeight" class="premium-input with-unit" />
                <span class="input-unit">cm</span>
              </div>
            </div>
          </div>
        </v-card-text>

        <v-card-actions class="px-6 py-4 border-t d-flex justify-end gap-3 bg-background">
          <v-btn variant="text" class="text-none font-weight-bold" @click="showBulkDimensionsModal = false">Cancelar</v-btn>
          <v-btn color="info" variant="flat" class="text-none font-weight-bold px-6 rounded-lg shadow-sm" :loading="isBulkUpdating" @click="applyBulkDimensions">Gravar Medidas</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showR2ExplorerModal" max-width="700" persistent scrollable>
      <v-card class="rounded-xl bg-surface border">
        <v-card-title class="d-flex align-center px-6 py-4 bg-indigo-darken-4 text-white">
          <v-icon color="white" class="mr-3" size="24">mdi-cloud-search</v-icon>
          <span class="text-h6 font-weight-bold">Explorador R2</span>
          <v-spacer></v-spacer>
          <v-btn icon="mdi-close" variant="text" color="white" size="small" @click="showR2ExplorerModal = false"></v-btn>
        </v-card-title>

        <div class="px-6 pt-4 pb-3 bg-background border-b d-flex flex-column gap-3">
          <p class="text-body-2 text-medium-emphasis m-0">Vincule o arquivo bruto do cofre para esta estampa.</p>
          <div class="d-flex gap-2 align-center">
            <div class="bg-surface border d-flex align-center px-3 rounded-lg flex-grow-1" style="height: 40px;">
              <v-icon size="18" class="text-medium-emphasis mr-2">mdi-filter</v-icon>
              <input v-model="r2SearchFilter" type="text" placeholder="Filtrar lista do R2..." class="w-100 outline-none text-body-2 text-high-emphasis bg-transparent" />
            </div>
            <v-btn color="indigo" variant="tonal" icon="mdi-refresh" class="rounded-lg" style="height:40px; width:40px;" :loading="isLoadingR2" @click="fetchR2Files"></v-btn>
          </div>
        </div>

        <v-card-text class="pa-0 bg-surface" style="height: 50vh;">
          <div v-if="isLoadingR2" class="d-flex flex-column align-center justify-center h-100">
            <v-progress-circular indeterminate color="indigo" size="40"></v-progress-circular>
            <span class="mt-4 text-medium-emphasis text-caption">Lendo cofre via Edge Function...</span>
          </div>
          <div v-else-if="filteredR2List.length === 0" class="d-flex flex-column align-center justify-center h-100 text-medium-emphasis">
            <v-icon size="40" class="mb-2 opacity-50">mdi-file-hidden</v-icon>
            <p class="text-body-2">Nenhum arquivo encontrado.</p>
          </div>
          <v-list v-else lines="one" class="px-3 py-2 bg-transparent">
            <v-list-item
              v-for="file in filteredR2List"
              :key="file"
              class="mb-2 border rounded-lg transition-all hover-bg-light"
              :class="{ 'bg-indigo-lighten-5 border-indigo': editStampForm.digital_file_url === file }"
            >
              <template v-slot:prepend>
                <v-icon :color="editStampForm.digital_file_url === file ? 'indigo' : 'grey'">
                  {{ file.endsWith('.zip') || file.endsWith('.rar') ? 'mdi-folder-zip' : 'mdi-file-image' }}
                </v-icon>
              </template>
              <v-list-item-title class="font-weight-medium text-body-2 text-high-emphasis" style="font-family: monospace;">{{ file }}</v-list-item-title>
              <template v-slot:append>
                <v-btn v-if="editStampForm.digital_file_url !== file" color="indigo" variant="flat" size="small" class="text-none font-weight-bold rounded" @click="linkR2File(file)">Vincular</v-btn>
                <v-chip v-else color="indigo" size="small" variant="flat" class="font-weight-bold rounded">Selecionado</v-chip>
              </template>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
    </v-dialog>

    <ImageModal :show="showImageModal" :imageUrl="selectedImageSrc" :fileName="selectedImageTitle" @close="showImageModal = false" />
    <input type="file" ref="realFileInput" style="display:none" accept="image/png, image/jpeg, image/webp" @change="handleRealUpload" />
  </section>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { supabase } from '@/api/supabase'
import imageCompression from 'browser-image-compression'
import ImageModal from '@/components/ImageModal.vue'

const props = defineProps<{
  stamps: any[],
  categories: any[]
}>()

const emit = defineEmits(['refresh'])

// ESTADOS DA ABA
const selectedFolder = ref<string | null>(null)
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = 50

// AÇÕES EM MASSA
const selectedStamps = ref<string[]>([])
const isBulkUpdating = ref(false)

// MODAL MEDIDAS EM MASSA
const showBulkDimensionsModal = ref(false)
const bulkWidth = ref<number>(50.0)
const bulkHeight = ref<number>(50.0)

// MODAL DE ESTAMPA
const showStampDrawer = ref(false)
const editStampForm = ref<any>({})
const isSaving = ref(false)

// COMPRESSÃO
const isCompressingFolder = ref(false)
const isCompressingSingle = ref(false)
const compressionProgress = ref({ current: 0, total: 0 })

// R2
const showR2ExplorerModal = ref(false)
const r2Files = ref<string[]>([])
const isLoadingR2 = ref(false)
const isAutoMatching = ref(false)
const r2SearchFilter = ref('')

// UPLOAD
const realFileInput = ref<HTMLInputElement | null>(null)
const pendingFiles = ref<Record<string, File>>({})
const currentUploadField = ref('')

// IMAGE VIEWER
const showImageModal = ref(false)
const selectedImageSrc = ref('')
const selectedImageTitle = ref('')

// COMPUTADOS
const filteredFolderStamps = computed(() => {
  let list = props.stamps
  if (selectedFolder.value && selectedFolder.value !== 'all') {
    list = list.filter(s => s.category_id === selectedFolder.value)
  }
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(s => s.title?.toLowerCase().includes(q) || s.ref_code?.toLowerCase().includes(q))
  }
  return list
})

const totalPages = computed(() => Math.ceil(filteredFolderStamps.value.length / itemsPerPage))
const paginatedStamps = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  return filteredFolderStamps.value.slice(start, start + itemsPerPage)
})

const filteredR2List = computed(() => {
  if (!r2SearchFilter.value) return r2Files.value
  const q = r2SearchFilter.value.toLowerCase()
  return r2Files.value.filter(f => f.toLowerCase().includes(q))
})

// FUNÇÕES AUXILIARES
function formatPrice(value: number) {
  return Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function getStampCountByCategory(catId: string) {
  return props.stamps.filter(s => s.category_id === catId).length
}

function getCategoryName(catId: string) {
  return props.categories.find(c => c.id === catId)?.name || ''
}

function openFolder(folderId: string) {
  selectedFolder.value = folderId
  searchQuery.value = ''
  currentPage.value = 1
  selectedStamps.value = []
}

function openImageViewer(src: string, title: string) {
  if (!src) return
  selectedImageSrc.value = src
  selectedImageTitle.value = title
  showImageModal.value = true
}

// AÇÃO DO PAI (Novo Cadastro)
function handleAction() {
  openStampDrawer(null)
}
defineExpose({ handleAction })

// ==========================================
// BULK ACTIONS (COM CHUNKING PARA EVITAR ERRO 400)
// ==========================================

function selectAllStamps() {
  if (selectedStamps.value.length === filteredFolderStamps.value.length) {
    selectedStamps.value = []
  } else {
    selectedStamps.value = filteredFolderStamps.value.map(s => s.id)
  }
}

// Função base para dividir as atualizações em lotes menores que a URL do PostgREST suporta
async function executeBulkUpdateInChunks(updatePayload: any, successMessage: string) {
  if (selectedStamps.value.length === 0) return;
  isBulkUpdating.value = true;
  try {
    const CHUNK_SIZE = 150; // Quantidade segura de UUIDs por request
    for (let i = 0; i < selectedStamps.value.length; i += CHUNK_SIZE) {
      const chunk = selectedStamps.value.slice(i, i + CHUNK_SIZE);
      const { error } = await supabase.from('catalog_stamps').update(updatePayload).in('id', chunk);
      if (error) throw error;
    }
    selectedStamps.value = [];
    emit('refresh');
    // alert(successMessage); // Opcional
  } catch (e: any) {
    alert(`Erro na atualização em massa: ${e.message}`);
  } finally {
    isBulkUpdating.value = false;
  }
}

async function bulkUpdateStampType(type: string) {
  await executeBulkUpdateInChunks({ stamp_type: type }, 'Tipos de estampa atualizados!');
}

async function bulkUpdateCategory(event: Event) {
  const catId = (event.target as HTMLSelectElement).value;
  if (!catId) return;
  await executeBulkUpdateInChunks({ category_id: catId }, 'Estampas movidas com sucesso!');
  (event.target as HTMLSelectElement).value = ""; // Reseta o select
}

async function applyBulkDimensions() {
  await executeBulkUpdateInChunks({ width_cm: bulkWidth.value, height_cm: bulkHeight.value }, 'Medidas aplicadas com sucesso!');
  showBulkDimensionsModal.value = false;
}


// GESTÃO DE ESTAMPAS (DRAWER E DB)
function openStampDrawer(s: any) {
  editStampForm.value = s ? { ...s, stamp_type: s.stamp_type || 'Corrida' } : {
    id: null, ref_code: '', title: '', description: '', main_image_url: '', digital_file_url: '',
    category_id: selectedFolder.value !== 'all' ? selectedFolder.value : null,
    stamp_type: 'Corrida', digital_price: 599.00, is_active: true,
    width_cm: 50.00, height_cm: 50.00
  }
  if (s && !s.width_cm) editStampForm.value.width_cm = 50.00;
  if (s && !s.height_cm) editStampForm.value.height_cm = 50.00;
  showStampDrawer.value = true
}

function closeStampDrawer() {
  showStampDrawer.value = false
  delete pendingFiles.value['stamp_main']
}

function submitFormDirectly() {
  const form = document.getElementById('stampForm') as HTMLFormElement;
  if (form) {
    if (form.reportValidity()) {
      saveStampToDb();
    }
  }
}

function triggerRealImageUpload(field: string) {
  currentUploadField.value = field
  realFileInput.value?.click()
}

async function handleRealUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  try {
    const compressed = await imageCompression(file, { maxSizeMB: 1, maxWidthOrHeight: 1920, useWebWorker: true, fileType: 'image/webp' })
    const localUrl = URL.createObjectURL(compressed)
    pendingFiles.value[currentUploadField.value] = compressed
    if (currentUploadField.value === 'stamp_main') {
      editStampForm.value.main_image_url = localUrl
    }
  } catch (e) {
    alert('Erro na compressão.')
  }
  target.value = ''
}

async function uploadPendingFile(field: string) {
  const f = pendingFiles.value[field]
  if (!f) return null
  const ext = f.name.split('.').pop() || 'webp'
  const path = `uploads/asset_${Date.now()}.${ext}`
  const { error } = await supabase.storage.from('catalog-assets').upload(path, f, { upsert: false })
  if (error) throw error
  delete pendingFiles.value[field]
  return supabase.storage.from('catalog-assets').getPublicUrl(path).data.publicUrl
}

async function saveStampToDb() {
  isSaving.value = true
  try {
    if (pendingFiles.value['stamp_main']) {
      editStampForm.value.main_image_url = await uploadPendingFile('stamp_main')
    }

    const payload = {
      slug: editStampForm.value.id ? editStampForm.value.slug : `${editStampForm.value.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${Date.now()}`,
      ref_code: editStampForm.value.ref_code,
      title: editStampForm.value.title,
      description: editStampForm.value.description,
      main_image_url: editStampForm.value.main_image_url,
      digital_file_url: editStampForm.value.digital_file_url || null,
      category_id: editStampForm.value.category_id,
      stamp_type: editStampForm.value.stamp_type,
      digital_price: editStampForm.value.digital_price || 599.00,
      is_active: editStampForm.value.is_active,
      width_cm: editStampForm.value.width_cm || 50.00,
      height_cm: editStampForm.value.height_cm || 50.00
    }

    if (editStampForm.value.id) {
      const { error } = await supabase.from('catalog_stamps').update(payload).eq('id', editStampForm.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('catalog_stamps').insert([payload])
      if (error) throw error
    }

    closeStampDrawer()
    emit('refresh')
  } catch(e: any) {
    alert(`Erro ao salvar estampa: ${e.message}`)
  } finally {
    isSaving.value = false
  }
}

async function deleteStampDirect(s: any) {
  if (confirm(`Excluir estampa "${s.title}"?`)) {
    await supabase.from('catalog_stamps').delete().eq('id', s.id)
    emit('refresh')
  }
}

// OTIMIZAÇÃO (COMPRESSÃO EM LOTE)
async function compressSingleStamp(stamp: any) {
  if (!stamp.main_image_url) return
  isCompressingSingle.value = true
  try {
    const success = await compressAndUpdateStamp(stamp)
    if (success) {
      alert('Imagem otimizada!')
      emit('refresh')
    } else {
      alert('Falha ao comprimir.')
    }
  } finally {
    isCompressingSingle.value = false
  }
}

async function compressFolderStamps() {
  const toCompress = filteredFolderStamps.value.filter(s => s.main_image_url && !s.main_image_url.includes('compressed_'))
  if (toCompress.length === 0) return alert('Nenhuma estampa para otimizar (já foram comprimidas ou sem imagem).')
  if (!confirm(`Comprimir ${toCompress.length} imagens antigas e re-upar?`)) return

  isCompressingFolder.value = true
  compressionProgress.value = { current: 0, total: toCompress.length }
  let ok = 0

  for (const s of toCompress) {
    if (await compressAndUpdateStamp(s)) ok++
    compressionProgress.value.current++
  }

  isCompressingFolder.value = false
  alert(`Pronto! ${ok}/${toCompress.length} imagens otimizadas.`)
  emit('refresh')
}

async function compressAndUpdateStamp(stamp: any): Promise<boolean> {
  try {
    const res = await fetch(stamp.main_image_url)
    if (!res.ok) throw new Error('Fetch failed')
    const blob = await res.blob()
    const file = new File([blob], `stamp.jpg`, { type: blob.type })
    const comp = await imageCompression(file, { maxSizeMB: 1, maxWidthOrHeight: 1920, useWebWorker: true, fileType: 'image/webp' })
    const path = `uploads/compressed_${Date.now()}_${stamp.id}.webp`
    const { error: upErr } = await supabase.storage.from('catalog-assets').upload(path, comp, { upsert: false })
    if (upErr) throw upErr
    const newUrl = supabase.storage.from('catalog-assets').getPublicUrl(path).data.publicUrl
    const { error: dbErr } = await supabase.from('catalog_stamps').update({ main_image_url: newUrl }).eq('id', stamp.id)
    if (dbErr) throw dbErr
    return true
  } catch (err) {
    console.error(`Erro stamp ${stamp.id}:`, err)
    return false
  }
}

// INTEGRAÇÃO R2
async function fetchR2Files() {
  isLoadingR2.value = true
  try {
    const { data, error } = await supabase.functions.invoke('list-r2-files', { method: 'GET' })
    if (error) throw error
    r2Files.value = data.files || []
  } catch (e) {
    console.error(e)
  } finally {
    isLoadingR2.value = false
  }
}

async function openR2Modal(ctx: any) {
  if (r2Files.value.length === 0) await fetchR2Files()
  r2SearchFilter.value = ctx.ref_code || ctx.title || ''
  showR2ExplorerModal.value = true
}

function linkR2File(file: string) {
  editStampForm.value.digital_file_url = file
  showR2ExplorerModal.value = false
}

function unlinkR2File() {
  if(confirm("Desvincular R2?")) editStampForm.value.digital_file_url = ''
}

async function runAutoMatch() {
  if (!confirm('Vincular R2 automaticamente pelos nomes/REFs?')) return
  isAutoMatching.value = true
  try {
    if (r2Files.value.length === 0) await fetchR2Files()
    let c = 0
    const ups = []

    for (const s of props.stamps) {
      if (s.digital_file_url) continue
      const ref = s.ref_code?.toLowerCase().trim() || ''
      const tit = s.title?.toLowerCase().trim() || ''
      const match = r2Files.value.find(f => {
        const nf = f.toLowerCase().replace(/\.[^/.]+$/, "")
        return (ref && nf === ref) || (tit && nf === tit) || (ref && f.toLowerCase().includes(ref))
      })
      if (match) {
        c++
        ups.push(supabase.from('catalog_stamps').update({ digital_file_url: match }).eq('id', s.id))
      }
    }
    if (ups.length) {
      await Promise.all(ups)
      emit('refresh')
      alert(`${c} estampas pareadas!`)
    } else {
      alert('Nenhum pareamento novo.')
    }
  } catch(e) {
    console.error(e)
  } finally {
    isAutoMatching.value = false
  }
}
</script>

<style scoped>
/* =========================================================
   FUNDAÇÃO E LAYOUT
========================================================= */
.hero-enterprise-card {
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.08), rgba(var(--v-theme-surface), 1) 40%);
}
.hero-watermark-icon {
  position: absolute; right: -20px; top: -20px; opacity: 0.04; transform: rotate(15deg);
}
.hero-watermark-icon .v-icon { font-size: 240px !important; }

/* =========================================================
   PASTAS PREMIUM E GRID
========================================================= */
.modern-folder-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }

.folder-card {
  border-radius: 20px !important;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1);
}

.folder-card.master-folder {
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.08), transparent);
  border: 1px solid rgba(var(--v-theme-primary), 0.2);
}
.folder-card.master-folder:hover {
  background: linear-gradient(135deg, rgba(var(--v-theme-primary), 0.12), transparent);
  border-color: rgba(var(--v-theme-primary), 0.5);
}

.folder-icon-wrap {
  width: 54px; height: 54px; border-radius: 14px;
  display: grid; place-items: center; flex-shrink: 0;
}

.folder-info { display: flex; flex-direction: column; overflow: hidden; flex-grow: 1; }
.folder-title { font-size: 1.05rem; font-weight: 800; margin: 0 0 6px 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; line-height: 1.2; }
.folder-meta { display: flex; align-items: center; gap: 8px; }

.folder-count {
  font-size: 11px; font-weight: 900; font-family: monospace;
  padding: 2px 8px; border-radius: 6px; display: inline-block;
}
.folder-desc { font-size: 11px; color: var(--text-medium-emphasis); white-space: nowrap; }

/* =========================================================
   ESTAMPAS GRID E CARDS
========================================================= */
.modern-stamp-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 24px; align-items: stretch; }

.stamp-card { position: relative; border-radius: 20px !important; overflow: hidden; }
.stamp-card::after { content: ''; position: absolute; inset: 0; pointer-events: none; border-radius: inherit; box-shadow: inset 0 1px 0 rgba(255,255,255,0.38); }
.stamp-card .pa-4 { padding: 18px !important; }
.stamp-card h4 { font-size: 0.95rem; line-height: 1.45 !important; letter-spacing: -0.01em; }
.stamp-card .v-chip { backdrop-filter: blur(12px); }

.stamp-checkbox { accent-color: rgb(var(--v-theme-primary)); }

/* =========================================================
   AÇÕES EM MASSA (FLUTUANTE) E TOOLBAR DA PASTA
========================================================= */
.bulk-action-island {
  position: fixed; bottom: 40px; left: 50%; transform: translateX(-50%); z-index: 999;
}
.bulk-inner {
  background: rgba(var(--v-theme-surface), 0.85); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12); border-radius: 999px;
  padding: 8px; display: flex; align-items: center; gap: 4px;
}

.bulk-count {
  display: flex; align-items: center; gap: 8px;
  background: rgb(var(--v-theme-primary)); color: white;
  padding: 6px 16px; border-radius: 999px; margin-right: 4px;
}
.count-number { font-weight: 900; font-size: 1rem; }
.count-label { font-weight: 600; font-size: 0.8rem; opacity: 0.9; }

.bulk-divider { width: 1px; height: 24px; background: rgba(var(--v-theme-on-surface), 0.12); margin: 0 4px; }

.bulk-btn {
  display: flex; align-items: center; font-size: 0.85rem; font-weight: 800; color: var(--text-high-emphasis);
  padding: 8px 16px; border-radius: 999px; border: none; background: transparent; cursor: pointer; transition: all 0.2s;
}
.bulk-btn:hover:not(:disabled) { background: rgba(var(--v-theme-on-surface), 0.05); }
.bulk-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.bulk-btn-icon {
  width: 36px; height: 36px; border-radius: 50%; display: grid; place-items: center;
  border: none; cursor: pointer; transition: all 0.2s;
}

.bulk-select-wrapper { position: relative; display: flex; align-items: center; background: rgba(var(--v-theme-on-surface), 0.04); border-radius: 999px; padding: 4px 16px; transition: all 0.2s; height: 36px;}
.bulk-select-wrapper:hover { background: rgba(var(--v-theme-on-surface), 0.08); }
.bulk-select { appearance: none; outline: none; background: transparent; padding-right: 24px; cursor: pointer; color: var(--text-high-emphasis); width: 150px;}
.select-chevron { position: absolute; right: 12px; pointer-events: none; }

.sticky-toolbar { position: sticky; top: 0; z-index: 10; backdrop-filter: blur(20px); background: rgba(var(--v-theme-surface), 0.9) !important; }

/* =========================================================
   SIDEBAR DE EDIÇÃO (DRAWER) E INPUTS PREMIUM
========================================================= */
.drawer-backdrop {
  position: fixed; inset: 0; z-index: 9999; background: rgba(3, 7, 18, 0.52);
  backdrop-filter: blur(8px); display: flex; justify-content: flex-end;
}
.drawer-panel { width: min(720px, 100vw); box-shadow: -18px 0 44px rgba(15,23,42,0.18); }
.drawer-header { background: rgba(var(--v-theme-surface), 0.96) !important; backdrop-filter: blur(12px); }
.drawer-footer { background: rgba(var(--v-theme-surface), 0.96) !important; backdrop-filter: blur(12px); }

.form-section { display: flex; flex-direction: column; gap: 12px; }
.section-title { font-size: 13px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-medium-emphasis); display: flex; align-items: center; }

.premium-label { font-size: 12px; font-weight: 800; color: var(--text-high-emphasis); margin-bottom: 6px; display: block; }

.premium-input, select.premium-input {
  width: 100%; min-height: 44px; padding: 10px 14px;
  background: var(--bg-background); border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 12px; color: var(--text-high-emphasis); font-size: 0.9rem;
  transition: all 0.2s ease; outline: none; box-shadow: inset 0 2px 4px rgba(0,0,0,0.02);
}
.premium-input:focus { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.15); background: var(--bg-surface); }
select.premium-input { appearance: auto; }

.premium-input-wrap { position: relative; display: flex; align-items: center; }
.premium-input.with-unit { padding-right: 42px; font-family: monospace; font-weight: bold; font-size: 1rem; }
.input-unit { position: absolute; right: 14px; font-size: 12px; font-weight: 800; color: var(--text-medium-emphasis); pointer-events: none; }

.hover-bg-light:hover { background: rgba(var(--v-theme-on-surface), 0.04); }

.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--v-theme-on-surface), 0.14); border-radius: 999px; }

.hover-elevate { transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease; }
.hover-elevate:hover {
  transform: translateY(-4px);
  box-shadow: 0 1px 0 rgba(255,255,255,0.4) inset, 0 22px 44px rgba(15, 23, 42, 0.10) !important;
  border-color: rgba(var(--v-theme-primary), 0.24) !important;
}

/* Transições e Helpers */
.slide-up-fade-enter-active,
.slide-up-fade-leave-active { transition: all 0.3s cubic-bezier(0.25, 1, 0.5, 1); }
.slide-up-fade-enter-from,
.slide-up-fade-leave-to { transform: translate(-50%, 100%) scale(0.9); opacity: 0; }
</style>
