<template>
  <div class="tab-panel mj-surface mj-border rounded-2px animate-fade-in d-flex flex-column" style="min-height: 750px;">

    <div class="panel-header mb-8 pb-6 border-b" style="border-color: var(--border-color) !important;">
      <h3 class="text-h5 font-weight-black uppercase tracking-wide m-0 text-primary d-flex align-center gap-2">
        <v-icon size="24">mdi-tune-vertical-variant</v-icon> Preferências do Workspace
      </h3>
      <p class="text-caption opacity-60 m-0 mt-1">Configure o comportamento, a densidade visual e a telemetria do seu ambiente PatternAtlas.</p>
    </div>

    <v-row class="form-grid-spacing">
      <v-col cols="12">
        <div class="mj-surface-2 mj-border rounded-2px pa-6 cursor-pointer hover-card-fx transition-all relative overflow-hidden" @click="toggleTheme">
          <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between gap-4 relative z-10">
            <div class="d-flex align-center gap-4">
              <div
                class="rounded-2px d-flex align-center justify-center border flex-shrink-0 transition-colors"
                :class="isLightMode ? 'bg-orange-lighten-5 text-orange-darken-3 border-orange-lighten-3' : 'bg-indigo-darken-4 text-indigo-lighten-2 border-indigo-darken-3'"
                style="width: 56px; height: 56px;"
              >
                <v-icon size="28">{{ isLightMode ? 'mdi-white-balance-sunny' : 'mdi-moon-waning-crescent' }}</v-icon>
              </div>
              <div>
                <h4 class="text-subtitle-1 font-weight-black m-0 lh-1 text-uppercase tracking-widest">Aparência do Sistema</h4>
                <p class="text-caption opacity-60 m-0 mt-1 line-height-1-4">Modifica globalmente a paleta de cores, contraste e emissão de luz da interface.</p>
              </div>
            </div>
            <div class="align-self-start align-self-sm-center">
              <v-chip
                size="small"
                :color="isLightMode ? 'orange-darken-3' : 'indigo-lighten-1'"
                variant="tonal"
                class="rounded-2px font-weight-black text-uppercase tracking-widest border-thin px-4 shadow-sm"
              >
                {{ isLightMode ? 'Fóton (Claro)' : 'Nebula (Escuro)' }}
              </v-chip>
            </div>
          </div>
          <div class="ambient-theme-glow" :class="isLightMode ? 'glow-light' : 'glow-dark'"></div>
        </div>
      </v-col>

      <v-col cols="12" md="6">
        <v-card class="bg-surface-2 border rounded-2px pa-6 h-100 d-flex flex-column" elevation="0" style="border-color: var(--border-color) !important;">
          <div class="d-flex align-center gap-3 mb-5">
            <v-icon color="primary" size="20">mdi-view-grid-compact</v-icon>
            <h4 class="text-caption font-weight-black text-uppercase tracking-widest lh-1 text-primary">Densidade de Dados</h4>
          </div>
          <p class="text-[10px] opacity-60 mb-5 line-height-1-4">Ajusta o espaçamento de tabelas, kanbans e painéis para focar em leitura ou volume de informações.</p>

          <v-btn-toggle v-model="prefs.density" mandatory variant="outlined" class="rounded-2px w-100 flex-column flex-sm-row mt-auto" color="primary" style="border-color: var(--border-color);">
            <v-btn value="compact" class="flex-grow-1 rounded-2px">
              <div class="d-flex flex-column py-2">
                <span class="text-[10px] font-weight-black uppercase tracking-widest">Alta</span>
                <span class="text-[8px] opacity-50 mt-1">Foco em volume</span>
              </div>
            </v-btn>
            <v-btn value="comfortable" class="flex-grow-1 rounded-2px">
              <div class="d-flex flex-column py-2">
                <span class="text-[10px] font-weight-black uppercase tracking-widest">Padrão</span>
                <span class="text-[8px] opacity-50 mt-1">Equilíbrio ERP</span>
              </div>
            </v-btn>
          </v-btn-toggle>
        </v-card>
      </v-col>

      <v-col cols="12" md="6">
        <v-card class="bg-surface-2 border rounded-2px pa-6 h-100 d-flex flex-column" elevation="0" style="border-color: var(--border-color) !important;">
          <div class="d-flex align-center gap-3 mb-5">
            <v-icon color="primary" size="20">mdi-speedometer</v-icon>
            <h4 class="text-caption font-weight-black text-uppercase tracking-widest lh-1 text-primary">Motor de Renderização</h4>
          </div>
          <p class="text-[10px] opacity-60 mb-4 line-height-1-4">Otimizações para computadores de baixa performance ou conexões instáveis.</p>

          <div class="mt-auto d-flex flex-column gap-2">
            <v-list density="compact" class="bg-transparent pa-0">
              <v-list-item class="px-0 py-1">
                <template #prepend>
                  <v-switch v-model="prefs.reduceMotion" color="warning" hide-details density="compact" class="mr-3 switch-chiseled" @change="savePreferences" />
                </template>
                <v-list-item-title class="text-[10px] font-weight-black uppercase tracking-widest">Reduzir Animações</v-list-item-title>
                <v-list-item-subtitle class="text-[9px] opacity-60 line-height-1-4">Desativa efeitos glassmorphism e partículas</v-list-item-subtitle>
              </v-list-item>

              <v-list-item class="px-0 py-1">
                <template #prepend>
                  <v-switch v-model="prefs.hardwareAccel" color="success" hide-details density="compact" class="mr-3 switch-chiseled" @change="savePreferences" />
                </template>
                <v-list-item-title class="text-[10px] font-weight-black uppercase tracking-widest">Aceleração de Hardware</v-list-item-title>
                <v-list-item-subtitle class="text-[9px] opacity-60 line-height-1-4">Usa GPU para renderizar dashboards pesados</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </div>
        </v-card>
      </v-col>

      <v-col cols="12">
        <v-card class="bg-surface-2 border rounded-2px pa-6 d-flex flex-column flex-md-row gap-6 align-md-center justify-space-between" elevation="0" style="border-color: var(--border-color) !important;">
          <div class="flex-grow-1">
            <div class="d-flex align-center gap-3 mb-2">
              <v-icon color="primary" size="20">mdi-satellite-uplink</v-icon>
              <h4 class="text-caption font-weight-black text-uppercase tracking-widest lh-1 text-primary">Telemetria de Alertas</h4>
            </div>
            <p class="text-[10px] opacity-60 mb-0 line-height-1-4 max-w-md">
              Define como o PatternAtlas notifica você sobre atualizações no Kanban, fechamentos de caixa e alertas fiscais urgentes.
            </p>
          </div>

          <div class="d-flex flex-wrap gap-4 align-center flex-shrink-0 border-l pl-md-6" style="border-color: var(--border-color) !important;">
            <div class="d-flex align-center gap-2">
              <v-switch v-model="prefs.notifyPush" color="primary" hide-details density="compact" class="switch-chiseled" @change="savePreferences" />
              <span class="text-[10px] font-weight-bold uppercase opacity-80">Push (Sistema)</span>
            </div>
            <div class="d-flex align-center gap-2">
              <v-switch v-model="prefs.notifyEmail" color="primary" hide-details density="compact" class="switch-chiseled" @change="savePreferences" />
              <span class="text-[10px] font-weight-bold uppercase opacity-80">E-mail Diário</span>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useThemeStore } from '@/stores/theme'
import { useAppStore } from '@/stores/app'

const themeStore = useThemeStore()
const appStore = useAppStore()

const isLightMode = computed(() => themeStore.currentMode === 'light')

// Estado das preferências locais do usuário (Pode ser salvo no Supabase futuramente)
const prefs = ref({
  density: 'comfortable',
  reduceMotion: false,
  hardwareAccel: true,
  notifyPush: true,
  notifyEmail: false
})

// Simulando carregamento de preferências locais
const loadPreferences = () => {
  const saved = localStorage.getItem('patternatlas_prefs')
  if (saved) {
    Object.assign(prefs.value, JSON.parse(saved))
  }
}
loadPreferences()

// Salva as preferências no localStorage ou dispara um snackbar
const savePreferences = () => {
  localStorage.setItem('patternatlas_prefs', JSON.stringify(prefs.value))
  // Se tivéssemos um backend para prefs:
  // await supabase.from('profiles').update({ preferences: prefs.value }).eq('id', user.id)

  appStore.showSnackbar('Configurações de Workspace salvas localmente.', 'success')
}

// Watcher específico para salvar a densidade quando o v-btn-toggle mudar
watch(() => prefs.value.density, () => {
  savePreferences()
})

const toggleTheme = () => {
  themeStore.setMode(isLightMode.value ? 'dark' : 'light')
  appStore.showSnackbar(`Tema ${isLightMode.value ? 'Nebula (Escuro)' : 'Fóton (Claro)'} ativado.`, 'success')
}
</script>

<style scoped>
/* =========================================================
   PREFERENCES TAB - ERP CHISELED STYLE
========================================================= */
.rounded-2px { border-radius: 2px !important; }
.tracking-widest { letter-spacing: 0.1em !important; }
.lh-1 { line-height: 1; }
.line-height-1-4 { line-height: 1.4; }
.max-w-md { max-width: 450px; }

.tab-panel { padding: 36px; }

/* Grid Spacing */
.form-grid-spacing { margin-top: -12px; margin-bottom: -12px; }
.form-grid-spacing > .v-col { padding-top: 12px; padding-bottom: 12px; }

/* Theme Card FX */
.hover-card-fx { border: 1px solid var(--border-color) !important; transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease; }
.hover-card-fx:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 30px rgba(0,0,0,0.08);
  border-color: rgba(var(--v-theme-primary), 0.3) !important;
}

.ambient-theme-glow { position: absolute; inset: 0; pointer-events: none; opacity: 0; transition: opacity 0.4s ease; }
.hover-card-fx:hover .ambient-theme-glow { opacity: 1; }
.glow-light { background: radial-gradient(circle at right center, rgba(251, 140, 0, 0.05) 0%, transparent 60%); }
.glow-dark { background: radial-gradient(circle at right center, rgba(63, 81, 181, 0.1) 0%, transparent 60%); }

/* Chiseled Switches */
.switch-chiseled :deep(.v-switch__track) { border-radius: 2px !important; }
.switch-chiseled :deep(.v-switch__thumb) { border-radius: 2px !important; }

/* Densidade Btn Toggle */
.v-btn-group--divided .v-btn { border-right-color: var(--border-color) !important; }

/* Animações */
.animate-fade-in { animation: fadeIn 0.4s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* Mobile */
@media (max-width: 959px) {
  .border-l { border-left: none !important; border-top: 1px solid var(--border-color); padding-top: 20px; padding-left: 0 !important; }
}
@media (max-width: 599px) {
  .tab-panel { padding: 24px; }
}
</style>
