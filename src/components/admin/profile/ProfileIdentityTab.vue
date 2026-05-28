<template>
  <div class="tab-panel mj-surface mj-border rounded-2px animate-fade-in">
    <div class="panel-header mb-8 pb-6 border-b" style="border-color: var(--border-color) !important;">
      <h3 class="text-h5 font-weight-black uppercase tracking-wide m-0 text-primary">Ficha Cadastral Eletrônica</h3>
      <p class="text-caption opacity-60 m-0 mt-1">Dados fundamentais para emissão de logs e documentos no ecossistema PatternAtlas.</p>
    </div>

    <v-form @submit.prevent="saveProfile">
      <v-row class="form-grid-spacing">
        <v-col cols="12" md="6">
          <div class="form-group-premium">
            <label>Nome Completo Administrativo</label>
            <div class="input-wrapper">
              <v-icon size="18" class="input-icon">mdi-badge-account-outline</v-icon>
              <input
                v-model="form.full_name"
                type="text"
                class="mj-input-premium rounded-2px"
                placeholder="Insira seu nome legal"
                required
              />
              <div class="focus-ring rounded-2px"></div>
            </div>
          </div>
        </v-col>

        <v-col cols="12" md="6">
          <div class="form-group-premium locked">
            <label class="d-flex justify-space-between align-center">
              <span>Matrícula / ID Interno</span>
              <v-icon size="12" class="opacity-50">mdi-lock-outline</v-icon>
            </label>
            <div class="input-wrapper">
              <v-icon size="18" class="input-icon opacity-50">mdi-identifier</v-icon>
              <input
                :value="internalId"
                readonly
                class="mj-input-premium rounded-2px font-mono tracking-widest text-primary"
              />
            </div>
            <span class="text-[9px] opacity-40 mt-1 d-block uppercase">Identificador único no banco de dados</span>
          </div>
        </v-col>

        <v-col cols="12">
          <div class="form-group-premium locked">
            <label class="d-flex justify-space-between align-center">
              <span>E-mail Corporativo de Acesso</span>
              <v-chip size="x-small" color="success" variant="flat" class="rounded-2px font-weight-bold tracking-widest px-2" style="font-size: 8px;">VERIFICADO</v-chip>
            </label>
            <div class="input-wrapper">
              <v-icon size="18" class="input-icon opacity-50">mdi-email-outline</v-icon>
              <input
                :value="user?.email"
                readonly
                class="mj-input-premium rounded-2px font-mono opacity-60"
              />
            </div>
          </div>
        </v-col>

        <v-col cols="12">
          <div class="form-group-premium">
            <label>Bio Profissional / Competências Chave</label>
            <div class="input-wrapper textarea-wrapper">
              <textarea
                v-model="form.bio"
                class="mj-input-premium rounded-2px py-4"
                rows="4"
                placeholder="Descreva suas responsabilidades, especialidades e funções principais no PatternAtlas..."
              ></textarea>
              <div class="focus-ring rounded-2px"></div>
            </div>
          </div>
        </v-col>
      </v-row>

      <div class="status-box mj-surface-2 mj-border rounded-2px pa-6 mt-8 d-flex flex-column flex-sm-row align-start gap-5 relative overflow-hidden">
        <div class="security-mesh"></div>
        <div class="icon-shield mj-surface mj-border rounded-2px d-flex align-center justify-center flex-shrink-0 relative z-10" style="width: 48px; height: 48px;">
          <v-icon size="24" :color="isSuperAdmin ? 'warning' : 'primary'">
            {{ isSuperAdmin ? 'mdi-shield-crown-outline' : 'mdi-shield-check-outline' }}
          </v-icon>
        </div>
        <div class="relative z-10 flex-grow-1">
          <h4 class="font-weight-black mb-1 text-uppercase" :class="isSuperAdmin ? 'text-warning' : 'text-primary'" style="letter-spacing: 0.1em; font-size: 0.85rem;">
            Nível de Segurança Operacional: {{ isSuperAdmin ? 'Máxima (Global)' : 'Padrão (Restrita)' }}
          </h4>
          <p class="text-caption text-muted mb-2" style="line-height: 1.5;">
            Sua credencial atual possui flag de <strong>{{ isSuperAdmin ? 'Administração Global' : 'Acesso Operacional' }}</strong>.
            Todas as operações sensíveis (exclusões, alterações financeiras e baixas) são registradas nos logs de auditoria imutáveis associados ao seu ID.
          </p>
          <div class="d-flex gap-2 flex-wrap">
            <v-chip size="x-small" variant="outlined" color="primary" class="rounded-2px font-weight-bold">Log Ativo</v-chip>
            <v-chip size="x-small" variant="outlined" color="primary" class="rounded-2px font-weight-bold">Rastreio de IP</v-chip>
          </div>
        </div>
      </div>

      <div class="form-actions mt-10 d-flex justify-end border-t pt-6" style="border-color: var(--border-color) !important;">
        <v-btn
          type="submit"
          color="primary"
          height="48"
          :loading="saving"
          class="rounded-2px font-weight-black shadow-neon tracking-widest px-10 text-caption"
        >
          <v-icon start size="16">mdi-cloud-sync-outline</v-icon> Sincronizar Registro
        </v-btn>
      </div>
    </v-form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'

const props = defineProps<{
  profile: any;
  user: any;
  isSuperAdmin: boolean;
}>()

const emit = defineEmits(['refresh-profile'])
const appStore = useAppStore()

const saving = ref(false)
const form = ref({
  full_name: '',
  bio: ''
})

// Gera um ID visual estilo ERP (ex: PAT-A1B2C3) baseado no UUID real
const internalId = computed(() => {
  if (!props.profile?.id) return 'PAT-PENDING'
  return 'PAT-' + props.profile.id.split('-')[0].toUpperCase()
})

// Sincroniza props locais
watch(() => props.profile, (newVal) => {
  if (newVal) {
    form.value.full_name = newVal.full_name || ''
    form.value.bio = newVal.bio || '' // Assumindo que você adicione 'bio' na tabela profiles depois
  }
}, { immediate: true })

const saveProfile = async () => {
  saving.value = true
  try {
    const { error } = await supabase
      .from('profiles')
      .update({
        full_name: form.value.full_name,
        // bio: form.value.bio // Descomente quando adicionar a coluna 'bio' no banco
      })
      .eq('id', props.profile?.id)

    if (error) throw error

    appStore.showSnackbar('Ficha cadastral sincronizada com sucesso.', 'success')
    emit('refresh-profile') // Notifica o pai para recarregar
  } catch (error) {
    console.error(error)
    appStore.showSnackbar('Falha ao sincronizar registro.', 'error')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
/* =========================================================
   FORMULÁRIOS ERP PREMIUM E STRICT 2PX
========================================================= */
.rounded-2px { border-radius: 2px !important; }
.tracking-wide { letter-spacing: 0.02em !important; }
.tracking-widest { letter-spacing: 0.1em !important; }
.shadow-neon { box-shadow: 0 4px 20px rgba(var(--v-theme-primary), 0.25) !important; }

.tab-panel { padding: 36px; min-height: 600px; }

/* Grid Spacing */
.form-grid-spacing { margin-top: -12px; margin-bottom: -12px; }
.form-grid-spacing > .v-col { padding-top: 12px; padding-bottom: 12px; }

/* Formulário Premium PatternAtlas */
.form-group-premium { margin-bottom: 8px; position: relative; }
.form-group-premium label {
  display: flex; font-size: 10px; font-weight: 900; text-transform: uppercase;
  letter-spacing: 0.15em; margin-bottom: 8px; opacity: 0.5;
}

.input-wrapper { position: relative; width: 100%; }
.input-icon { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); opacity: 0.4; transition: 0.3s; z-index: 2; pointer-events: none; }
.textarea-wrapper .input-icon { top: 24px; transform: none; }

.mj-input-premium {
  width: 100%; background: var(--bg-surface-2); border: 1px solid var(--border-color);
  padding: 0 16px 0 48px; height: 52px; color: var(--text-main); font-size: 0.95rem; font-weight: 500;
  transition: all 0.3s ease; outline: none; position: relative; z-index: 1;
}

textarea.mj-input-premium { padding-left: 16px; min-height: 120px; resize: vertical; line-height: 1.5; }

.focus-ring {
  position: absolute; inset: -1px; border: 1px solid rgb(var(--v-theme-primary));
  opacity: 0; transform: scale(0.99); transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1); pointer-events: none; z-index: 0;
}

.mj-input-premium:focus { border-color: transparent !important; background: transparent; }
.mj-input-premium:focus + .focus-ring { opacity: 1; transform: scale(1); box-shadow: inset 0 0 15px rgba(var(--v-theme-primary), 0.08); background: var(--bg-surface-2); }
.mj-input-premium:focus ~ .input-icon { opacity: 1; color: rgb(var(--v-theme-primary)); }

/* Campos Bloqueados (Locked) */
.form-group-premium.locked .mj-input-premium { background: rgba(0,0,0,0.03); cursor: not-allowed; border-style: dashed; }
.theme-dark .form-group-premium.locked .mj-input-premium { background: rgba(255,255,255,0.02); }

/* Security Status Box */
.security-mesh {
  position: absolute; inset: 0; opacity: 0.03; pointer-events: none;
  background-image: linear-gradient(rgba(var(--v-theme-primary), 1) 1px, transparent 1px), linear-gradient(90deg, rgba(var(--v-theme-primary), 1) 1px, transparent 1px);
  background-size: 20px 20px;
}
.icon-shield { box-shadow: 0 4px 12px rgba(0,0,0,0.05); }

/* Animações */
.animate-fade-in { animation: fadeIn 0.4s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* Mobile */
@media (max-width: 599px) {
  .tab-panel { padding: 24px; }
  .mj-input-premium { height: 48px; }
}
</style>
