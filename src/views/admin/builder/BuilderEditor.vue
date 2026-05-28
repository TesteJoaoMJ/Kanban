<template>
  <div class="mj-admin-builder bg-surface">

    <div v-if="isLoading" class="loading-overlay">
      <v-progress-circular indeterminate color="primary" size="48" width="3"></v-progress-circular>
      <p class="mt-4 font-weight-bold text-primary letter-spacing-1 text-uppercase text-[12px]">Conectando ao Supabase...</p>
    </div>

    <div v-else class="w-100 h-100 d-flex flex-column">

      <header class="editor-header bg-surface border-b d-flex justify-space-between align-center px-6 flex-shrink-0">
        <div class="d-flex align-center gap-4">
          <v-btn icon="mdi-close" variant="tonal" size="small" color="error" @click="$emit('close')"></v-btn>
          <div>
            <h1 class="text-subtitle-1 font-weight-black text-primary lh-tight text-uppercase letter-spacing-1">Editor do Acervo</h1>
            <div class="text-[10px] text-success font-weight-bold letter-spacing-1 uppercase"><span class="dot-online"></span> Headless Sync</div>
          </div>
        </div>

        <div class="d-flex align-center gap-2 bg-alternate pa-1 rounded-lg border">
          <button class="tab-btn" :class="{ active: currentTab === 'hero' }" @click="currentTab = 'hero'"><v-icon size="16">mdi-image-area</v-icon> Hero</button>
          <button class="tab-btn" :class="{ active: currentTab === 'grids' }" @click="currentTab = 'grids'"><v-icon size="16">mdi-view-grid-outline</v-icon> Vitrines</button>
          <button class="tab-btn" :class="{ active: currentTab === 'parallax' }" @click="currentTab = 'parallax'"><v-icon size="16">mdi-layers-outline</v-icon> Parallax</button>
          <button class="tab-btn" :class="{ active: currentTab === 'global' }" @click="currentTab = 'global'"><v-icon size="16">mdi-cog-outline</v-icon> Global</button>
        </div>

        <div class="d-flex align-center gap-4">
          <button class="icon-btn border hover-bg-alternate" @click="previewIsDark = !previewIsDark" title="Testar Dark Mode">
            <v-icon size="18" class="text-primary">{{ previewIsDark ? 'mdi-weather-night' : 'mdi-weather-sunny' }}</v-icon>
          </button>
          <button class="btn-publish" @click="publishToDb" :disabled="isSaving">
            <v-icon size="16" class="mr-2">mdi-cloud-upload</v-icon> {{ isSaving ? 'Salvando...' : 'Publicar Loja' }}
          </button>
        </div>
      </header>

      <div class="d-flex flex-grow-1 overflow-hidden">

        <aside class="editor-sidebar bg-surface border-r custom-scrollbar flex-shrink-0 d-flex flex-column">

          <div class="pa-6 flex-grow-1 overflow-y-auto custom-scrollbar">

            <template v-if="currentTab === 'hero'">
              <h3 class="section-title">Configurações do Banner</h3>
              <div class="d-flex flex-column gap-5">
                <div class="input-group">
                  <label>Imagem de Fundo (Hero)</label>
                  <div class="upload-box" @click="triggerUpload('hero_bg_url')">
                    <div v-if="isUploading && currentUpload === 'hero_bg_url'"><v-progress-circular indeterminate size="24"></v-progress-circular></div>
                    <img v-else-if="settings.hero_bg_url" :src="settings.hero_bg_url" class="w-100 h-100 object-cover" />
                    <div v-else class="text-center text-muted"><v-icon>mdi-upload</v-icon><br><span>Upload</span></div>
                  </div>
                </div>
                <div class="input-group">
                  <label>Título (Colossal)</label>
                  <textarea v-model="settings.hero_title" rows="2" class="mj-input"></textarea>
                </div>
                <div class="input-group">
                  <label>Subtítulo (Badge Topo)</label>
                  <input type="text" v-model="settings.hero_subtitle" class="mj-input" />
                </div>
              </div>
            </template>

            <template v-if="currentTab === 'grids'">
              <div class="d-flex justify-space-between align-center border-b pb-4 mb-4">
                <h3 class="section-title mb-0">Vitrines da Home</h3>
                <button class="icon-btn-small bg-primary text-white" @click="addGrid"><v-icon size="16">mdi-plus</v-icon></button>
              </div>

              <div class="d-flex flex-column gap-4">
                <div v-for="(grid, index) in settings.grids_config" :key="index" class="mj-card-config position-relative group">
                  <button class="absolute top-2 right-2 text-error opacity-50 hover-opacity-100" @click="removeGrid(index)"><v-icon size="16">mdi-delete</v-icon></button>

                  <div class="input-group mb-3 pr-6">
                    <label>Título da Vitrine</label>
                    <input type="text" v-model="grid.title" class="mj-input py-2" />
                  </div>

                  <div class="d-flex gap-3 mb-3">
                    <div class="input-group w-50">
                      <label>Origem</label>
                      <select v-model="grid.type" class="mj-input py-2 px-2">
                        <option value="recent">Recentes</option>
                        <option value="category">Categoria</option>
                      </select>
                    </div>
                    <div class="input-group w-50">
                      <label>Limite</label>
                      <input type="number" v-model.number="grid.limit" min="4" max="20" class="mj-input py-2 px-2" />
                    </div>
                  </div>

                  <div v-if="grid.type === 'category'" class="input-group mb-3">
                    <label>Categoria Alvo</label>
                    <select v-model="grid.source_id" class="mj-input py-2 px-2">
                      <option value="" disabled>Selecione...</option>
                      <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                    </select>
                  </div>

                  <div class="d-flex justify-end gap-2 mt-2 pt-3 border-t">
                    <button class="icon-btn-small border" @click="moveGrid(index, -1)" :disabled="index === 0"><v-icon size="14">mdi-arrow-up</v-icon></button>
                    <button class="icon-btn-small border" @click="moveGrid(index, 1)" :disabled="index === settings.grids_config.length - 1"><v-icon size="14">mdi-arrow-down</v-icon></button>
                  </div>
                </div>

                <div v-if="!settings.grids_config.length" class="text-center pa-6 text-muted border border-dashed rounded-lg">
                  Nenhuma vitrine. A loja mostrará apenas banners.
                </div>
              </div>
            </template>

            <template v-if="currentTab === 'parallax'">
              <h3 class="section-title">Sessão Institucional (Parallax)</h3>
              <div class="d-flex flex-column gap-5">
                <div class="input-group">
                  <label>Imagem de Fundo</label>
                  <div class="upload-box" @click="triggerUpload('parallax_bg_url')">
                    <div v-if="isUploading && currentUpload === 'parallax_bg_url'"><v-progress-circular indeterminate size="24"></v-progress-circular></div>
                    <img v-else-if="settings.parallax_bg_url" :src="settings.parallax_bg_url" class="w-100 h-100 object-cover" />
                    <div v-else class="text-center text-muted"><v-icon>mdi-upload</v-icon><br><span>Upload</span></div>
                  </div>
                </div>
                <div class="input-group">
                  <label>Título (H2)</label>
                  <input type="text" v-model="settings.parallax_title" class="mj-input" />
                </div>
                <div class="input-group">
                  <label>Texto de Manifesto</label>
                  <textarea v-model="settings.parallax_text" rows="4" class="mj-input"></textarea>
                </div>
              </div>
            </template>

            <template v-if="currentTab === 'global'">
              <h3 class="section-title">Configurações Gerais</h3>
              <div class="d-flex flex-column gap-5">
                <div class="input-group">
                  <label>Logo Customizada (Opcional)</label>
                  <div class="upload-box" style="height: 100px;" @click="triggerUpload('logo_url')">
                    <div v-if="isUploading && currentUpload === 'logo_url'"><v-progress-circular indeterminate size="24"></v-progress-circular></div>
                    <img v-else-if="settings.logo_url" :src="settings.logo_url" class="w-100 h-100 object-contain pa-2" />
                    <div v-else class="text-center text-muted"><v-icon>mdi-upload</v-icon><br><span>Upload PNG</span></div>
                  </div>
                  <span class="text-[10px] text-muted mt-1">Se vazia, usa a logo padrão do sistema.</span>
                </div>

                <div class="input-group pt-6 border-t">
                  <label class="text-error font-weight-bold">Modo Suspensão</label>
                  <v-switch v-model="settings.maintenance_mode" color="error" label="Travar loja para clientes" hide-details density="compact"></v-switch>
                </div>
              </div>
            </template>

          </div>
        </aside>

        <main class="preview-workspace flex-grow-1 bg-alternate d-flex flex-column align-center custom-scrollbar overflow-y-auto pa-8">

          <div class="preview-browser-window w-100 max-w-1400 shadow-2xl border border-color rounded-xl overflow-hidden d-flex flex-column"
               :class="['mj-landing-wrapper', previewIsDark ? 'theme-dark' : 'theme-light']">

            <header class="glass-header position-relative">
              <div class="header-content w-100 px-6">
                <img v-if="settings.logo_url" :src="settings.logo_url" class="logo" :class="{'invert-logo': previewIsDark}" />
                <div v-else class="font-weight-black text-primary letter-spacing-1">Sua Marca</div>

                <nav class="desktop-nav d-none d-md-flex gap-8">
                  <span class="text-primary font-weight-bold uppercase text-[12px] letter-spacing-1 cursor-pointer">Início</span>
                  <span class="text-secondary font-weight-bold uppercase text-[12px] letter-spacing-1 cursor-pointer">Descobrir</span>
                </nav>

                <div class="header-actions">
                  <v-btn icon variant="text" class="text-primary"><v-icon>{{ previewIsDark ? 'mdi-weather-sunny' : 'mdi-weather-night' }}</v-icon></v-btn>
                  <v-btn color="primary" variant="flat" class="login-btn rounded-lg ml-4"><v-icon class="mr-2">mdi-palette-swatch-outline</v-icon> Moodboard</v-btn>
                </div>
              </div>
            </header>

            <div class="main-scroller flex-grow-1 overflow-y-auto bg-bg custom-scrollbar position-relative" style="height: 70vh;">

              <section class="hero-section" style="padding-top: 100px;">
                <div class="hero-glow"></div>
                <div class="hero-text-container text-center px-4 max-w-800 mx-auto position-relative z-20">
                  <div class="d-flex justify-center w-100 mb-6">
                    <div class="badge-premium">{{ settings.hero_subtitle || 'Coleção Exclusiva' }}</div>
                  </div>
                  <h1 class="colossal-title text-white"><span class="gradient-text">{{ settings.hero_title || 'Design Autêntico.' }}</span></h1>
                </div>

                <div class="absolute inset-0 z-0">
                   <img :src="settings.hero_bg_url || '/placeholder.png'" class="w-100 h-100 object-cover opacity-60 grayscale" />
                   <div class="absolute inset-0 bg-black-60 backdrop-blur-sm"></div>
                </div>
              </section>

              <section class="section-padding py-16 px-6 max-w-1400 mx-auto">
                <div v-for="(grid, index) in settings.grids_config" :key="index" class="mb-16">
                  <div class="section-header mb-10 text-left">
                    <h2 class="tracking-tight text-h4 text-primary font-weight-black">{{ grid.title || 'Vitrine' }}</h2>
                  </div>

                  <div class="stamp-grid">
                    <div v-for="stamp in getStampsForGrid(grid)" :key="stamp.id" class="mj-card pa-0 h-100 overflow-hidden group border border-color">

                      <div class="position-relative bg-alternate overflow-hidden border-b border-color" style="aspect-ratio: 1;">

                        <div v-if="stamp.main_image_url" class="absolute inset-0 z-0 transition-transform duration-700 group-hover-scale"
                             :style="{ backgroundImage: `url(${stamp.main_image_url})`, backgroundSize: 'cover', backgroundPosition: 'center' }">
                        </div>

                        <img v-if="stamp.mockup_url" :src="stamp.mockup_url" class="absolute inset-0 w-100 h-100 object-fit-contain z-10 pointer-events-none drop-shadow-mockup" style="padding: 10%;" />

                        <div v-if="!stamp.main_image_url && !stamp.mockup_url" class="w-100 h-100 d-flex align-center justify-center opacity-30"><v-icon size="32" class="text-secondary">mdi-texture-box</v-icon></div>
                      </div>

                      <div class="pa-5 bg-surface relative z-20">
                        <div class="text-[10px] font-weight-bold text-secondary letter-spacing-1 mb-1 uppercase">{{ stamp.ref_code }}</div>
                        <h4 class="text-[14px] font-weight-bold text-primary text-truncate">{{ stamp.title }}</h4>
                      </div>
                    </div>
                  </div>
                </div>
              </section>

              <div class="parallax-mid my-8 d-flex align-center justify-center text-center px-4 bg-surface border-y border-color position-relative" :style="settings.parallax_bg_url ? { backgroundImage: `url(${settings.parallax_bg_url})` } : {}">
                <div v-if="settings.parallax_bg_url" class="absolute inset-0 bg-black-70 z-0"></div>
                <div class="relative z-10 pa-10 max-w-800" :class="settings.parallax_bg_url ? 'text-white' : 'text-primary'">
                  <v-icon size="32" class="mb-4 opacity-50">mdi-star-four-points-outline</v-icon>
                  <h2 class="text-h4 font-weight-black mb-4 letter-spacing-1 uppercase">{{ settings.parallax_title || 'Sessão Informativa' }}</h2>
                  <p class="text-body-2 opacity-80 lh-relaxed">{{ settings.parallax_text || 'Texto institucional.' }}</p>
                </div>
              </div>

            </div>
          </div>

        </main>
      </div>

    </div>

    <input type="file" ref="fileInput" style="display:none" accept="image/*" @change="handleUpload" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/api/supabase';

const emit = defineEmits(['close']);

// ESTADO
const isLoading = ref(true);
const isSaving = ref(false);
const currentTab = ref<'hero'|'grids'|'parallax'|'global'>('hero');
const previewIsDark = ref(false);

const dbSettingsId = ref<string | null>(null);
const categories = ref<any[]>([]);
const allStamps = ref<any[]>([]);

// SCHEMA FIXO
const settings = ref<any>({
  logo_url: '',
  hero_bg_url: '',
  hero_title: 'Design Autêntico.',
  hero_subtitle: 'Coleção Exclusiva',
  parallax_bg_url: '',
  parallax_title: 'Visão & Arte',
  parallax_text: 'Sessão institucional.',
  maintenance_mode: false,
  grids_config: [
    { title: 'Destaques', type: 'recent', limit: 4, source_id: null }
  ]
});

// PLACEHOLDERS (Caso banco vazio)
const placeholderStamps = Array.from({ length: 8 }).map((_, i) => ({
  id: `mock-${i}`, ref_code: `REF-00${i+1}`, title: `Estampa Placeholder ${i+1}`,
  main_image_url: '', mockup_url: ''
}));

onMounted(async () => {
  isLoading.value = true;
  try {
    // Categorias
    const { data: catData } = await supabase.from('catalog_categories').select('id, name').eq('is_active', true);
    categories.value = catData || [];

    // Estampas
    const { data: stampData } = await supabase.from('catalog_stamps').select('*').eq('is_active', true);
    allStamps.value = stampData || [];

    // Configurações
    const { data: configData } = await supabase.from('storefront_settings').select('*').single();
    if (configData) {
      dbSettingsId.value = configData.id;
      settings.value = { ...settings.value, ...configData };
      if(!settings.value.grids_config) settings.value.grids_config = [];
    }
  } catch (error) {
    console.error("Iniciando limpo", error);
  } finally {
    isLoading.value = false;
  }
});

// FUNÇÕES DE GRIDS
function getStampsForGrid(gridConfig: any) {
  if(allStamps.value.length === 0) return placeholderStamps.slice(0, gridConfig.limit || 4);
  let list = [...allStamps.value];
  if(gridConfig.type === 'category' && gridConfig.source_id) {
    list = list.filter(s => s.category_id === gridConfig.source_id);
  } else {
    list.sort((a,b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  }
  return list.slice(0, gridConfig.limit || 4);
}

function addGrid() {
  settings.value.grids_config.push({ title: 'Nova Vitrine', type: 'recent', limit: 4, source_id: null });
}
function removeGrid(index: number) { settings.value.grids_config.splice(index, 1); }
function moveGrid(index: number, dir: number) {
  const list = settings.value.grids_config;
  const target = index + dir;
  if (target < 0 || target >= list.length) return;
  const temp = list[index]; list[index] = list[target]; list[target] = temp;
}

// UPLOAD REAL SUPABASE
const fileInput = ref<HTMLInputElement | null>(null);
const isUploading = ref(false);
const currentUpload = ref('');

function triggerUpload(field: string) {
  currentUpload.value = field;
  fileInput.value?.click();
}

async function handleUpload(event: Event) {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) return;

  isUploading.value = true;
  try {
    const fileExt = file.name.split('.').pop();
    const filePath = `storefront/asset_${Date.now()}.${fileExt}`;
    const { error } = await supabase.storage.from('catalog-assets').upload(filePath, file);
    if (error) throw error;

    const { data: publicUrlData } = supabase.storage.from('catalog-assets').getPublicUrl(filePath);
    settings.value[currentUpload.value] = publicUrlData.publicUrl;

  } catch (error: any) { alert(`Erro: ${error.message}`); }
  finally { isUploading.value = false; if (target) target.value = ''; }
}

// SALVAR NO BANCO
async function publishToDb() {
  isSaving.value = true;
  try {
    const payload = { ...settings.value, updated_at: new Date().toISOString() };
    let result;
    if (dbSettingsId.value) result = await supabase.from('storefront_settings').update(payload).eq('id', dbSettingsId.value);
    else {
      result = await supabase.from('storefront_settings').insert([payload]).select().single();
      if(result.data) dbSettingsId.value = result.data.id;
    }
    if(result.error) throw result.error;
    alert('✅ Sucesso! A Loja Pública foi atualizada.');
  } catch (error: any) { alert(`Erro: ${error.message}`); }
  finally { isSaving.value = false; }
}
</script>

<style scoped>
/* ==========================================================================
   CSS DO EDITOR DE CONFIGURAÇÃO
============================================================================= */
.mj-admin-builder {
  position: fixed; inset: 0; z-index: 99999;
  font-family: system-ui, -apple-system, sans-serif;
  background-color: #f5f5f7; color: #111; display: flex; flex-direction: column;
}

.loading-overlay { position: absolute; inset: 0; background: #f5f5f7; z-index: 10; display: flex; flex-direction: column; align-items: center; justify-content: center; }

/* UTILS BÁSICOS EDITOR */
.bg-surface { background-color: #ffffff; }
.bg-alternate { background-color: #f9f9fb; }
.border-color { border-color: #e5e5ea !important; }
.text-primary { color: #111; }
.text-secondary { color: #888; }
.text-error { color: #ef4444; }
.border-b { border-bottom: 1px solid #e5e5ea; }
.border-r { border-right: 1px solid #e5e5ea; }
.border-t { border-top: 1px solid #e5e5ea; }
.shadow-2xl { box-shadow: 0 25px 50px -12px rgba(0,0,0,0.15); }
.rounded-xl { border-radius: 16px; }

/* HEADER */
.editor-header { height: 72px; box-shadow: 0 4px 12px rgba(0,0,0,0.02); }
.dot-online { display: inline-block; width: 6px; height: 6px; background: #10b981; border-radius: 50%; margin-right: 4px; animation: pulse 2s infinite; }
@keyframes pulse { 0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); } 70% { transform: scale(1); box-shadow: 0 0 0 4px rgba(16, 185, 129, 0); } 100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); } }

.tab-btn { padding: 8px 16px; font-size: 12px; font-weight: 700; color: #888; border-radius: 6px; cursor: pointer; transition: 0.2s; display: flex; align-items: center; gap: 6px; text-transform: uppercase; letter-spacing: 0.05em; border: none; background: transparent; }
.tab-btn:hover { background: #eee; color: #111; }
.tab-btn.active { background: #111; color: #fff; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }

.icon-btn { width: 36px; height: 36px; border-radius: 8px; background: #fff; cursor: pointer; transition: 0.2s; display: flex; align-items: center; justify-content: center; }
.btn-publish { background: #111; color: #fff; padding: 0 24px; height: 36px; border-radius: 8px; font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; border: none; cursor: pointer; transition: 0.2s; }
.btn-publish:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
.btn-publish:disabled { opacity: 0.6; cursor: not-allowed; }

/* SIDEBAR ESQUERDA */
.editor-sidebar { width: 360px; }
.section-title { font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: #888; margin-bottom: 24px; }
.input-group { display: flex; flex-direction: column; gap: 8px; }
.input-group label { font-size: 11px; font-weight: 700; text-transform: uppercase; color: #555; letter-spacing: 0.05em; }
.mj-input { width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e5e5ea; background: #fff; font-size: 13px; outline: none; transition: 0.3s; font-family: inherit; }
.mj-input:focus { border-color: #111; box-shadow: 0 0 0 2px rgba(0,0,0,0.05); }
.upload-box { height: 140px; border-radius: 12px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; overflow: hidden; }
.upload-box:hover { border-color: #111 !important; background: #f0f0f0; }

.mj-card-config { border-radius: 12px; transition: 0.2s; }
.icon-btn-small { width: 24px; height: 24px; border-radius: 4px; display: flex; align-items: center; justify-content: center; background: transparent; border: none; cursor: pointer; }
.icon-btn-small:hover { background: #eee; }

/* ==========================================================================
   CSS DO PREVIEW (COPIA DO MARKETPLACEPORTAL.VUE)
   Isolado dentro de .preview-browser-window
============================================================================= */
.preview-browser-window {
  --bg-main: #f8fafc; --bg-surface: #ffffff; --bg-alternate: #ffffff;
  --border-card: #e2e8f0; --text-main: #0f172a; --text-muted: #64748b;
  --glow-hero: radial-gradient(circle at 50% 0%, rgba(226, 232, 240, 0.8), transparent 70%);
  --gradient-text: linear-gradient(135deg, #2563eb 0%, #0f172a 100%);
}

.preview-browser-window.theme-dark {
  --bg-main: #09090b; --bg-surface: #18181b; --bg-alternate: #0f0f13;
  --border-card: rgba(255, 255, 255, 0.08); --text-main: #ffffff; --text-muted: #a1a1aa;
  --glow-hero: radial-gradient(circle at 50% -20%, rgba(139, 92, 246, 0.15), transparent 60%);
  --gradient-text: linear-gradient(135deg, #a855f7 0%, #3b82f6 100%);
}

.preview-browser-window .bg-bg { background-color: var(--bg-main); color: var(--text-main); }
.preview-browser-window .bg-surface { background-color: var(--bg-surface); }
.preview-browser-window .bg-alternate { background-color: var(--bg-alternate); }
.preview-browser-window .border-color { border-color: var(--border-card) !important; }
.preview-browser-window .text-primary { color: var(--text-main) !important; }
.preview-browser-window .text-secondary { color: var(--text-muted) !important; }

/* PREVIEW HEADER E COMPONENTES */
.glass-header { height: 70px; display: flex; align-items: center; border-bottom: 1px solid var(--border-card); background: var(--bg-header); }
.logo { height: 28px; object-fit: contain; }
.invert-logo { filter: brightness(0) invert(1); }
.login-btn { font-weight: 800; text-transform: uppercase; font-size: 11px; }
.badge-premium { display: inline-block; padding: 4px 12px; border-radius: 20px; background: rgba(255,255,255, 0.2); color: #fff; font-weight: 800; font-size: 0.75rem; letter-spacing: 0.1em; text-transform: uppercase; border: 1px solid rgba(255,255,255, 0.4); }

.colossal-title { font-size: clamp(2rem, 5vw, 4rem); font-weight: 900; line-height: 1.05; letter-spacing: -0.04em; margin-bottom: 12px; text-align: center; }
.gradient-text { background: var(--gradient-text); -webkit-background-clip: text; color: transparent; }

/* GRIDS E SANDUÍCHE NO PREVIEW */
.stamp-grid { display: grid; gap: 24px; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }
.mj-card { background: var(--bg-surface); border-radius: 16px; transition: 0.3s; }
.drop-shadow-mockup { filter: drop-shadow(0 15px 25px rgba(0, 0, 0, 0.6)); }

.group-hover-scale { transform: scale(1); transition: transform 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); }
.group:hover .group-hover-scale { transform: scale(1.05); }
.pointer-events-none { pointer-events: none; }

.parallax-mid { min-height: 350px; background-size: cover; background-position: center; background-attachment: scroll; } /* no preview tiramos o fixed por bug do iframe */

/* UTILS PREVIEW */
.absolute { position: absolute; } .relative, .position-relative { position: relative; }
.inset-0 { top: 0; left: 0; right: 0; bottom: 0; }
.z-0 { z-index: 0; } .z-10 { z-index: 10; } .z-20 { z-index: 20; }
.w-100 { width: 100%; } .h-100 { height: 100%; }
.object-cover { object-fit: cover; } .object-fit-contain { object-fit: contain; }

/* SCROLLBARS */
.custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
</style>
