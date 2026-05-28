<template>
  <div class="fill-height d-flex flex-column bg-grey-lighten-5">

    <div class="px-8 py-6 bg-white border-b">
        <div class="d-flex align-center gap-2 mb-2">
            <v-icon color="primary">mdi-bank-transfer</v-icon>
            <span class="text-subtitle-2 font-weight-bold text-uppercase letter-spacing-1 text-medium-emphasis">Financeiro</span>
        </div>
        <h1 class="text-h4 font-weight-black text-high-emphasis">Integrações Bancárias</h1>
        <p class="text-body-1 text-medium-emphasis mt-1">Conecte sua conta bancária para emissão automática de boletos e Pix.</p>
    </div>

    <div class="pa-8 flex-grow-1 overflow-y-auto">
        <v-row>
            <v-col cols="12" md="6" lg="4">
                <v-card class="rounded-xl elevation-2 h-100 d-flex flex-column border-t-lg border-primary" style="border-top-width: 6px !important;">
                    <div class="pa-6 d-flex align-start justify-space-between">
                        <v-avatar rounded="lg" size="64" class="elevation-1 pa-2 bg-white">
                            <v-img src="https://logospng.org/download/cora/logo-cora-icon-1024.png"></v-img>
                        </v-avatar>
                        <v-chip :color="coraIntegration?.is_active ? 'success' : 'grey'" class="font-weight-bold" label>
                            {{ coraIntegration?.is_active ? 'CONECTADO' : 'DESCONECTADO' }}
                        </v-chip>
                    </div>
                    <div class="px-6 pb-4 flex-grow-1">
                        <h3 class="text-h6 font-weight-bold mb-2">Cora Bank</h3>
                        <p class="text-caption text-medium-emphasis">
                            Emissão de Pix e Boletos com baixa automática. Necessário Certificado e Chave PEM.
                        </p>
                    </div>
                    <div class="pa-4 border-t bg-grey-lighten-5">
                        <v-btn block color="primary" variant="flat" class="font-weight-bold" @click="openConfig">
                            Configurar
                        </v-btn>
                    </div>
                </v-card>
            </v-col>

            <v-col cols="12" md="6" lg="4" v-for="bank in mockedBanks" :key="bank.name">
                <v-card class="rounded-xl elevation-0 h-100 d-flex flex-column border opacity-60 grayscale">
                    <div class="pa-6 d-flex align-start justify-space-between">
                        <v-avatar rounded="lg" size="64" class="bg-grey-lighten-4 pa-2">
                            <v-icon size="40" :color="bank.color">{{ bank.icon }}</v-icon>
                        </v-avatar>
                        <v-chip size="small" variant="outlined" label>EM BREVE</v-chip>
                    </div>
                    <div class="px-6 pb-4">
                        <h3 class="text-h6 font-weight-bold mb-2">{{ bank.name }}</h3>
                        <p class="text-caption text-medium-emphasis">{{ bank.desc }}</p>
                    </div>
                    <div class="pa-4 border-t mt-auto">
                        <v-btn block variant="tonal" disabled>Indisponível</v-btn>
                    </div>
                </v-card>
            </v-col>
        </v-row>
    </div>

    <v-dialog v-model="showModal" max-width="600" persistent>
        <v-card class="rounded-xl">
            <v-toolbar color="surface" class="border-b pl-4 pr-2">
                <span class="text-h6 font-weight-bold">Configurar Cora</span>
                <v-spacer></v-spacer>
                <v-btn icon="mdi-close" variant="text" @click="showModal = false"></v-btn>
            </v-toolbar>

            <div class="pa-6 bg-grey-lighten-5">
                <v-alert type="info" variant="tonal" class="mb-4 text-caption border-info" density="compact">
                    Para obter esses arquivos, acesse o Internet Banking da Cora em "Integrações > API".
                </v-alert>

                <div class="d-flex flex-column gap-4">
                    <v-text-field
                        v-model="form.clientId"
                        label="Client ID (Produção)"
                        variant="outlined"
                        bg-color="white"
                        placeholder="Ex: 12345678-abcd..."
                        hide-details="auto"
                    ></v-text-field>

                    <div class="pa-4 bg-white rounded border border-dashed">
                        <div class="d-flex align-center justify-space-between mb-2">
                            <span class="text-caption font-weight-bold uppercase">Certificado (.pem)</span>
                            <v-icon v-if="form.certContent" color="success" size="20">mdi-check-circle</v-icon>
                        </div>
                        <v-file-input
                            accept=".pem"
                            label="Selecionar Arquivo"
                            density="compact"
                            variant="outlined"
                            prepend-icon=""
                            prepend-inner-icon="mdi-certificate"
                            hide-details
                            @change="(e) => readFile(e, 'certContent')"
                        ></v-file-input>
                    </div>

                    <div class="pa-4 bg-white rounded border border-dashed">
                        <div class="d-flex align-center justify-space-between mb-2">
                            <span class="text-caption font-weight-bold uppercase">Chave Privada (.key / .pem)</span>
                            <v-icon v-if="form.keyContent" color="success" size="20">mdi-check-circle</v-icon>
                        </div>
                        <v-file-input
                            accept=".key,.pem"
                            label="Selecionar Arquivo"
                            density="compact"
                            variant="outlined"
                            prepend-icon=""
                            prepend-inner-icon="mdi-key"
                            hide-details
                            @change="(e) => readFile(e, 'keyContent')"
                        ></v-file-input>
                    </div>
                </div>
            </div>

            <div class="pa-4 d-flex align-center justify-space-between border-t">
                <v-switch v-model="form.isActive" color="success" label="Ativar Integração" hide-details density="compact" inset class="ml-2"></v-switch>
                <v-btn color="primary" variant="flat" class="font-weight-bold px-6" :loading="saving" @click="saveConfig">
                    Salvar Conexão
                </v-btn>
            </div>
        </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'

const userStore = useUserStore()
const appStore = useAppStore()

const showModal = ref(false)
const saving = ref(false)
const coraIntegration = ref<any>(null)

const form = ref({
    clientId: '',
    certContent: '',
    keyContent: '',
    isActive: false
})

const mockedBanks = [
    { name: 'Banco Inter', desc: 'Emissão de boletos via API v2.', icon: 'mdi-bank', color: 'orange' },
    { name: 'Itaú Empresas', desc: 'Integração direta com o Itaú Shopline.', icon: 'mdi-alpha-i-box', color: 'blue-darken-4' },
    { name: 'Nubank', desc: 'API Corporativa para PJ.', icon: 'mdi-nu', color: 'purple' }
]

// Função para ler o conteúdo do arquivo de texto
const readFile = (event: any, targetField: 'certContent' | 'keyContent') => {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
        form.value[targetField] = e.target?.result as string
    }
    reader.readAsText(file)
}

const fetchIntegration = async () => {
    if (!userStore.activeStoreId) return

    const { data } = await supabase
        .from('company_integrations')
        .select('*')
        .eq('store_id', userStore.activeStoreId)
        .eq('provider', 'cora')
        .maybeSingle()

    if (data) {
        coraIntegration.value = data
        form.value.clientId = data.credentials.clientId
        form.value.certContent = data.credentials.cert
        form.value.keyContent = data.credentials.key
        form.value.isActive = data.is_active
    }
}

const openConfig = () => {
    fetchIntegration()
    showModal.value = true
}

const saveConfig = async () => {
    if (!userStore.activeStoreId) return appStore.showSnackbar('Selecione uma loja primeiro.', 'error')

    saving.value = true
    try {
        const payload = {
            store_id: userStore.activeStoreId,
            provider: 'cora',
            is_active: form.value.isActive,
            credentials: {
                clientId: form.value.clientId,
                cert: form.value.certContent,
                key: form.value.keyContent
            },
            updated_at: new Date()
        }

        const { error } = await supabase
            .from('company_integrations')
            .upsert(payload, { onConflict: 'store_id, provider' })

        if (error) throw error

        appStore.showSnackbar('Configurações da Cora salvas!', 'success')
        showModal.value = false
        fetchIntegration()
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error')
    } finally {
        saving.value = false
    }
}

onMounted(() => {
    fetchIntegration()
})
</script>

<style scoped>
.grayscale { filter: grayscale(100%); }
.border-t-lg { border-top-width: 6px !important; }
</style>
