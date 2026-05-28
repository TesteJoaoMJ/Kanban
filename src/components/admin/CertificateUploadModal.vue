<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('update:show', $event)"
    max-width="1024"
    transition="dialog-bottom-transition"
    scrollable
    class="certificate-modal-wrapper"
  >
    <v-card class="rounded-xl overflow-hidden d-flex flex-row h-100 bg-white shadow-card">

      <div class="sidebar d-none d-md-flex flex-column pa-8 relative overflow-hidden" style="width: 320px;">
        <div class="sidebar-bg"></div>

        <div class="z-10 relative">
          <div class="d-flex align-center gap-3 mb-8">
            <div class="icon-box-lg bg-white shadow-lg rounded-xl text-primary">
              <v-icon size="28">mdi-shield-lock-outline</v-icon>
            </div>
            <div>
              <div class="text-overline text-primary-darken-1 font-weight-black lh-1 mb-1">Ambiente Seguro</div>
              <div class="text-h6 font-weight-black text-grey-darken-3 lh-1">Certificado A1</div>
            </div>
          </div>

          <div class="d-flex flex-column gap-6">
            <div class="info-card active">
              <div class="d-flex justify-space-between align-start mb-2">
                <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">Modelo Suportado</span>
                <v-icon color="success" size="18">mdi-check-circle</v-icon>
              </div>
              <p class="text-body-2 text-grey-darken-1">
                Apenas arquivos digitais <strong>.PFX</strong> ou <strong>.P12</strong> (Modelo A1).
                <br><span class="text-[11px] text-grey mt-1 d-block">Cartões físicos (A3) e Tokens USB não são compatíveis com servidores em nuvem.</span>
              </p>
            </div>

            <div class="info-card">
              <div class="d-flex justify-space-between align-start mb-2">
                <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">Criptografia</span>
                <v-icon color="blue-grey" size="18">mdi-lock</v-icon>
              </div>
              <p class="text-body-2 text-grey-darken-1">
                Seu certificado é armazenado em cofre HSM (Hardware Security Module) e utilizado apenas para assinar os XMLs das notas.
              </p>
            </div>
          </div>
        </div>

        <div class="mt-auto z-10 relative">
          <div class="d-flex align-center gap-2 mb-3">
            <v-icon size="16" color="warning">mdi-alert-circle-outline</v-icon>
            <span class="text-caption font-weight-bold text-grey-darken-3">Dica Importante</span>
          </div>
          <div class="text-caption text-grey bg-white/50 rounded-lg pa-3 border-thin">
            Verifique a validade do arquivo antes de enviar. Certificados vencidos bloquearão a emissão de notas.
          </div>
        </div>
      </div>

      <div class="flex-grow-1 d-flex flex-column h-100 bg-white relative">

        <div class="px-8 py-6 border-b d-flex justify-space-between align-center">
          <div>
            <h2 class="text-h5 font-weight-black text-grey-darken-3">Upload de Arquivo</h2>
            <div class="d-flex align-center gap-2 mt-1">
              <span class="text-caption text-grey">Passo {{ step }}/2:</span>
              <span class="text-caption font-weight-bold text-primary">{{ step === 1 ? 'Selecionar Arquivo' : 'Validar Segurança' }}</span>
            </div>
          </div>
          <v-btn icon variant="plain" density="compact" color="grey" @click="$emit('close')">
            <v-icon size="24">mdi-close</v-icon>
          </v-btn>
        </div>

        <div class="px-8 py-6 flex-grow-1 overflow-y-auto custom-scrollbar">

          <v-slide-x-transition mode="out-in">
            <div v-if="step === 1" key="step1" class="h-100 d-flex flex-column">

              <div class="mb-6">
                <label class="input-label">Vincular à Empresa</label>
                <v-autocomplete
                  v-model="form.cnpj"
                  :items="companies"
                  item-title="name"
                  item-value="cnpj"
                  variant="outlined"
                  class="premium-input"
                  placeholder="Selecione a empresa titular"
                  hide-details
                  prepend-inner-icon="mdi-domain"
                >
                  <template v-slot:item="{ props, item }">
                    <v-list-item v-bind="props" :subtitle="item.raw.cnpj" class="py-2">
                        <template v-slot:prepend>
                            <v-avatar color="grey-lighten-4" rounded="lg" class="mr-2">
                                <span class="font-weight-bold text-primary">{{ item.title.charAt(0) }}</span>
                            </v-avatar>
                        </template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </div>

              <div
                class="upload-zone flex-grow-1 rounded-xl d-flex flex-column align-center justify-center text-center transition-all relative"
                :class="{ 'dragging': isDragging, 'has-file': !!file }"
                @dragover.prevent="isDragging = true"
                @dragleave.prevent="isDragging = false"
                @drop.prevent="handleDrop"
                @click="!file && triggerFileInput()"
              >
                <input type="file" ref="fileInput" class="d-none" accept=".pfx,.p12" @change="handleFileSelect">

                <template v-if="!file">
                  <div class="pulse-circle bg-blue-lighten-5 mb-6">
                    <v-icon color="primary" size="48">mdi-cloud-upload</v-icon>
                  </div>
                  <h3 class="text-h6 font-weight-bold text-grey-darken-3 mb-2">Arraste e solte seu certificado</h3>
                  <p class="text-body-2 text-grey mb-6">Suportamos arquivos <strong>.PFX</strong> ou <strong>.P12</strong></p>
                  <v-btn color="primary" variant="flat" rounded="lg" class="text-none font-weight-bold px-6" @click.stop="triggerFileInput">
                    Buscar no Computador
                  </v-btn>
                </template>

                <template v-else>
                  <div class="file-card-lg bg-white elevation-2 rounded-xl pa-4 d-flex align-center gap-4 border w-100 max-w-sm animate-pop">
                    <div class="bg-red-lighten-5 rounded-lg pa-3">
                      <v-icon color="red-darken-1" size="32">mdi-file-certificate</v-icon>
                    </div>
                    <div class="text-left flex-grow-1 overflow-hidden">
                      <div class="text-subtitle-2 font-weight-black text-grey-darken-3 text-truncate">{{ file.name }}</div>
                      <div class="d-flex align-center gap-2 mt-1">
                        <v-chip size="x-small" color="success" variant="flat" class="font-weight-bold">A1</v-chip>
                        <span class="text-caption text-grey font-mono">{{ formatFileSize(file.size) }}</span>
                      </div>
                    </div>
                    <v-btn icon variant="text" color="grey" @click.stop="removeFile">
                      <v-icon>mdi-close</v-icon>
                    </v-btn>
                  </div>
                  <v-btn variant="text" color="primary" class="mt-4 text-none font-weight-bold" @click.stop="triggerFileInput">
                    Trocar arquivo
                  </v-btn>
                </template>

                <div class="drag-overlay" v-if="isDragging">
                  <v-icon color="white" size="64">mdi-arrow-down-bold-circle</v-icon>
                  <div class="text-h5 font-weight-bold text-white mt-4">Solte para carregar</div>
                </div>
              </div>

            </div>
          </v-slide-x-transition>

          <v-slide-x-reverse-transition mode="out-in">
            <div v-if="step === 2" key="step2" class="h-100 d-flex flex-column justify-center px-4">

              <div class="text-center mb-8">
                <v-avatar color="blue-grey-lighten-5" size="80" class="mb-4">
                  <v-icon color="blue-grey-darken-1" size="40">mdi-lock-question</v-icon>
                </v-avatar>
                <h3 class="text-h5 font-weight-bold text-grey-darken-3">Segurança do Arquivo</h3>
                <p class="text-body-2 text-grey mt-2">Informe a senha definida na criação do certificado para descriptografá-lo.</p>
              </div>

              <v-text-field
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                variant="outlined"
                class="premium-input text-center-input"
                placeholder="Senha do Certificado"
                :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
                @click:append-inner="showPassword = !showPassword"
                @keyup.enter="confirmUpload"
                autofocus
                bg-color="grey-lighten-5"
                height="56"
              ></v-text-field>

              <div class="text-center mt-4">
                <v-chip size="small" color="warning" variant="outlined" class="bg-warning-lighten-5">
                  <v-icon start size="14">mdi-alert</v-icon>
                  A senha não será salva, apenas utilizada para extração das chaves.
                </v-chip>
              </div>

            </div>
          </v-slide-x-reverse-transition>

        </div>

        <div class="px-8 py-5 bg-grey-lighten-5 border-t d-flex justify-between align-center">
          <v-btn
            v-if="step === 2"
            variant="text"
            prepend-icon="mdi-arrow-left"
            color="grey-darken-2"
            class="text-none font-weight-bold"
            @click="step = 1"
          >
            Voltar
          </v-btn>
          <div v-else></div> <v-btn
            v-if="step === 1"
            color="primary"
            variant="flat"
            height="44"
            class="text-none font-weight-bold px-8 shadow-primary-soft"
            :disabled="!file || !form.cnpj"
            @click="step = 2"
          >
            Continuar
            <v-icon end>mdi-arrow-right</v-icon>
          </v-btn>

          <v-btn
            v-if="step === 2"
            color="success"
            variant="flat"
            height="44"
            class="text-none font-weight-bold px-8 shadow-success-soft"
            :loading="loading"
            :disabled="!form.password"
            @click="confirmUpload"
          >
            <v-icon start>mdi-check</v-icon>
            Finalizar Instalação
          </v-btn>
        </div>

      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch } from 'vue';

const props = defineProps<{
  show: boolean;
  companies: any[];
  initialCnpj?: string;
  loading?: boolean;
}>();

const emit = defineEmits(['update:show', 'close', 'upload']);

const step = ref(1);
const fileInput = ref<HTMLInputElement | null>(null);
const isDragging = ref(false);
const file = ref<File | null>(null);
const showPassword = ref(false);

const form = reactive({
  cnpj: null as string | null,
  password: ''
});

// Reset ao abrir/fechar
watch(() => props.show, (val) => {
  if (val) {
    step.value = 1;
    file.value = null;
    form.password = '';
    if (props.initialCnpj) form.cnpj = props.initialCnpj;
  }
});

const triggerFileInput = () => fileInput.value?.click();

const handleFileSelect = (event: any) => {
  const selected = event.target.files[0];
  if (selected) validateAndSetFile(selected);
};

const handleDrop = (event: DragEvent) => {
  isDragging.value = false;
  const dropped = event.dataTransfer?.files[0];
  if (dropped) validateAndSetFile(dropped);
};

const validateAndSetFile = (f: File) => {
  const ext = f.name.split('.').pop()?.toLowerCase();
  if (['pfx', 'p12'].includes(ext || '')) {
    file.value = f;
  } else {
    alert('Formato inválido. Por favor, utilize apenas arquivos .pfx ou .p12');
  }
};

const removeFile = () => {
  file.value = null;
  if (fileInput.value) fileInput.value.value = '';
};

const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

const confirmUpload = () => {
  if (!file.value || !form.password || !form.cnpj) return;
  emit('upload', {
    file: file.value,
    password: form.password,
    cnpj: form.cnpj
  });
};
</script>

<style scoped lang="scss">
.certificate-modal-wrapper {
  backdrop-filter: blur(8px);
}

.shadow-card {
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25) !important;
}

/* Sidebar Styling */
.sidebar {
  background: #F8FAFC;
  border-right: 1px solid #E2E8F0;
  position: relative;
}

.sidebar-bg {
  position: absolute;
  top: 0; right: 0; bottom: 0; left: 0;
  background-image: radial-gradient(#CBD5E1 1px, transparent 1px);
  background-size: 24px 24px;
  opacity: 0.4;
  z-index: 0;
}

.icon-box-lg {
  width: 56px; height: 56px;
  display: flex; align-items: center; justify-content: center;
}

.info-card {
  background: white;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  padding: 16px;
  transition: all 0.2s;

  &.active {
    border-color: rgb(var(--v-theme-primary));
    box-shadow: 0 4px 6px -1px rgba(var(--v-theme-primary), 0.1);
  }
}

/* Upload Zone */
.upload-zone {
  border: 2px dashed #CBD5E1;
  background: #F8FAFC;
  cursor: pointer;
  min-height: 280px;

  &:hover {
    border-color: rgb(var(--v-theme-primary));
    background: #F1F5F9;
    .pulse-circle { transform: scale(1.1); }
  }

  &.dragging {
    border-color: rgb(var(--v-theme-primary));
    background: rgb(var(--v-theme-primary));
    border-style: solid;
  }

  &.has-file {
    background: #F8FAFC;
    border-color: #E2E8F0;
    border-style: solid;
  }
}

.drag-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(var(--v-theme-primary), 0.9);
  z-index: 50;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
}

.pulse-circle {
  width: 80px; height: 80px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.file-card-lg {
  animation: popIn 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes popIn {
  0% { opacity: 0; transform: scale(0.9); }
  100% { opacity: 1; transform: scale(1); }
}

/* Inputs Premium */
.input-label {
  display: block;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  color: #64748B;
  margin-bottom: 6px;
  letter-spacing: 0.5px;
}

.premium-input :deep(.v-field) {
  border-radius: 12px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  background: white;
  transition: all 0.2s;
}

.premium-input :deep(.v-field--focused) {
  border-color: rgb(var(--v-theme-primary));
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.1);
}

.shadow-primary-soft { box-shadow: 0 8px 16px -4px rgba(var(--v-theme-primary), 0.4); }
.shadow-success-soft { box-shadow: 0 8px 16px -4px rgba(var(--v-theme-success), 0.4); }

.bg-warning-lighten-5 { background-color: #FFFBEB !important; border-color: #FCD34D !important; }
.lh-1 { line-height: 1.2; }
</style>
