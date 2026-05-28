<template>
  <div class="d-flex flex-column h-100 w-100 bg-background text-high-emphasis overflow-hidden">

    <v-toolbar density="compact" color="surface" elevation="1" class="px-2 flex-shrink-0 border-b">
      <v-btn icon size="small" variant="text" color="medium-emphasis" @click="goBack" v-if="isFromOrder">
        <v-icon>mdi-arrow-left</v-icon>
        <v-tooltip activator="parent" location="bottom">Voltar para Pedidos</v-tooltip>
      </v-btn>

      <div class="d-flex align-center text-caption text-medium-emphasis ml-2">
        <v-icon size="small" class="mr-2">mdi-store</v-icon>
        <span class="d-none d-sm-inline">Cajuia</span>
        <v-icon size="small" class="mx-2 d-none d-sm-inline">mdi-chevron-right</v-icon>
        <span class="text-high-emphasis font-weight-bold">Emissor NFe (Vendedor)</span>
      </div>

      <v-spacer></v-spacer>

      <div class="d-flex align-center mr-4" v-if="activeCompany">
          <v-chip size="small" color="indigo" variant="tonal" class="font-weight-bold text-caption">
              <v-icon start size="14">mdi-domain</v-icon>
              {{ activeCompany.name?.substring(0, 20) }}
          </v-chip>
      </div>

      <v-btn
        color="indigo"
        variant="flat"
        class="text-none font-weight-bold px-4 shadow-indigo-soft"
        height="36"
        size="small"
        prepend-icon="mdi-plus"
        @click="openNewNoteModal"
      >
        Nova NFe
      </v-btn>
    </v-toolbar>

    <div class="px-6 pt-6 pb-2 flex-shrink-0">
        <v-row dense>
            <v-col cols="12" md="4">
                <v-card class="rounded-lg pa-4 d-flex align-center justify-space-between border bg-surface" elevation="0">
                    <div>
                        <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase mb-1">Minhas Emissões (Mês)</div>
                        <div class="text-h5 font-weight-black text-indigo">{{ notes.filter(n => n.status === 'AUTORIZADA').length }}</div>
                    </div>
                    <div class="icon-box-sm bg-indigo-lighten-5 text-indigo rounded-lg d-flex align-center justify-center">
                        <v-icon>mdi-xml</v-icon>
                    </div>
                </v-card>
            </v-col>
            <v-col cols="12" md="4">
                <v-card class="rounded-lg pa-4 d-flex align-center justify-space-between border bg-surface" elevation="0">
                    <div>
                        <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase mb-1">Total Faturado (Eu)</div>
                        <div class="text-h5 font-weight-black text-success">{{ formatCompact(totalValue) }}</div>
                    </div>
                    <div class="icon-box-sm bg-green-lighten-5 text-success rounded-lg d-flex align-center justify-center">
                        <v-icon>mdi-cash-multiple</v-icon>
                    </div>
                </v-card>
            </v-col>
            <v-col cols="12" md="4">
                <v-card class="rounded-lg pa-4 d-flex align-center justify-space-between border bg-surface" elevation="0">
                    <div>
                        <div class="text-caption text-medium-emphasis font-weight-bold text-uppercase mb-1">Meus Rascunhos</div>
                        <div class="text-h5 font-weight-black text-amber-darken-2">{{ draftsCount }}</div>
                    </div>
                    <div class="icon-box-sm bg-amber-lighten-5 text-amber-darken-2 rounded-lg d-flex align-center justify-center">
                        <v-icon>mdi-file-edit</v-icon>
                    </div>
                </v-card>
            </v-col>
        </v-row>
    </div>

    <div class="d-flex flex-column flex-grow-1 overflow-hidden px-6 pb-6">
        <v-card class="flex-grow-1 d-flex flex-column overflow-hidden rounded-lg border" elevation="0">

            <div class="px-4 py-2 border-b bg-surface-light d-flex align-center gap-4">
                <v-tabs v-model="activeTab" color="indigo" density="compact" class="bg-transparent">
                    <v-tab :value="0" class="text-caption font-weight-bold text-none rounded-md px-4">Minhas Notas</v-tab>
                    <v-tab :value="1" class="text-caption font-weight-bold text-none rounded-md px-4">
                        Rascunhos <v-chip v-if="draftsCount > 0" size="x-small" color="amber" variant="flat" class="ml-2 font-weight-black text-white">{{ draftsCount }}</v-chip>
                    </v-tab>
                </v-tabs>

                <v-spacer></v-spacer>

                <div style="width: 250px;">
                    <v-text-field
                        v-model="search"
                        density="compact"
                        variant="outlined"
                        placeholder="Buscar nota..."
                        prepend-inner-icon="mdi-magnify"
                        hide-details
                        bg-color="surface"
                        class="text-caption"
                    ></v-text-field>
                </div>
            </div>

            <v-window v-model="activeTab" class="flex-grow-1 overflow-y-auto custom-scrollbar bg-surface">

                <v-window-item :value="0" class="h-100">
                     <div v-if="loading" class="d-flex flex-column align-center justify-center h-100">
                        <v-progress-circular indeterminate color="indigo" size="40"></v-progress-circular>
                     </div>
                     <div v-else-if="filteredNotes.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-60">
                        <v-icon size="64" color="medium-emphasis">mdi-file-document-outline</v-icon>
                        <span class="text-caption mt-2 font-weight-bold text-medium-emphasis">Nenhuma nota encontrada.</span>
                     </div>
                     <v-list v-else class="pa-0 bg-transparent">
                        <div v-for="note in filteredNotes" :key="note.id" class="note-row px-4 py-2 border-b d-flex align-center gap-4 transition-all hover-bg">
                             <div class="icon-box rounded-lg flex-shrink-0" :class="getStatusClass(note.status)">
                                <v-icon size="18">{{ getStatusIcon(note.status) }}</v-icon>
                             </div>

                             <div class="flex-grow-1" style="min-width: 0;">
                                <div class="d-flex align-center gap-2 mb-1">
                                    <span class="text-body-2 font-weight-bold text-high-emphasis text-truncate">{{ note.destinatario_nome || 'Consumidor Final' }}</span>
                                    <v-chip size="x-small" :color="getStatusColor(note.status)" variant="tonal" class="font-weight-bold text-uppercase border-opacity-50" label>
                                        {{ note.status }}
                                    </v-chip>
                                    <span v-if="note.numero" class="text-caption text-medium-emphasis font-mono">Nº {{ note.numero }}</span>
                                </div>
                                <div class="text-caption text-medium-emphasis d-flex align-center gap-3">
                                    <span>{{ formatDate(note.created_at) }}</span>
                                    <span v-if="note.chave" class="font-mono opacity-70">{{ formatKey(note.chave) }}</span>
                                </div>
                             </div>

                             <div class="text-right px-2" style="min-width: 100px;">
                                <div class="text-body-2 font-weight-black text-high-emphasis font-mono">{{ formatCurrency(note.valor_total) }}</div>
                             </div>

                             <div class="d-flex align-center gap-1">
                                <v-tooltip text="Ver DANFE" location="top">
                                    <template v-slot:activator="{ props }">
                                        <v-btn icon size="x-small" variant="text" color="primary" v-bind="props" @click="viewDocument(note, 'pdf')" :disabled="note.status !== 'AUTORIZADA'">
                                            <v-icon>mdi-file-pdf-box</v-icon>
                                        </v-btn>
                                    </template>
                                </v-tooltip>

                                <v-menu location="bottom end">
                                    <template v-slot:activator="{ props }">
                                        <v-btn icon size="x-small" variant="text" color="medium-emphasis" v-bind="props"><v-icon>mdi-dots-vertical</v-icon></v-btn>
                                    </template>
                                    <v-list density="compact" class="rounded-lg elevation-4">
                                        <v-list-item link @click="viewDocument(note, 'xml')" :disabled="note.status !== 'AUTORIZADA'">
                                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-xml</v-icon></template>
                                            <v-list-item-title>Baixar XML</v-list-item-title>
                                        </v-list-item>
                                        <v-divider class="my-1"></v-divider>
                                        <v-list-item link class="text-error" @click="cancelNote(note)">
                                            <template v-slot:prepend><v-icon size="small" class="mr-2">mdi-cancel</v-icon></template>
                                            <v-list-item-title>{{ note.status === 'REJEITADA' ? 'Excluir Registro' : 'Cancelar NFe' }}</v-list-item-title>
                                        </v-list-item>
                                    </v-list>
                                </v-menu>
                             </div>
                        </div>
                     </v-list>
                </v-window-item>

                <v-window-item :value="1" class="h-100">
                    <div v-if="filteredDrafts.length === 0" class="d-flex flex-column align-center justify-center h-100 opacity-60">
                        <v-icon size="64" color="medium-emphasis">mdi-file-edit-outline</v-icon>
                        <span class="text-caption mt-2 font-weight-bold text-medium-emphasis">Nenhum rascunho pendente.</span>
                     </div>
                     <v-list v-else class="pa-0 bg-transparent">
                        <div v-for="draft in filteredDrafts" :key="draft.id" class="note-row px-4 py-2 border-b d-flex align-center gap-4 transition-all hover-bg border-l-4-amber">
                             <div class="icon-box rounded-lg flex-shrink-0 bg-amber-lighten-5 text-amber-darken-3">
                                <v-icon size="18">mdi-pencil</v-icon>
                             </div>
                             <div class="flex-grow-1">
                                <div class="text-body-2 font-weight-bold text-high-emphasis">{{ draft.destinatario_nome || 'Sem Destinatário' }}</div>
                                <div class="text-caption text-medium-emphasis">Criado em: {{ formatDate(draft.created_at) }}</div>
                             </div>
                             <div class="text-right px-2 font-mono font-weight-bold text-high-emphasis">{{ formatCurrency(draft.valor_total) }}</div>
                             <div class="d-flex align-center gap-1">
                                 <v-btn icon size="x-small" variant="text" color="success" @click="emitDraft(draft)" :loading="issuing" title="Emitir"><v-icon>mdi-send</v-icon></v-btn>
                                 <v-btn icon size="x-small" variant="text" color="primary" @click="editDraft(draft)" title="Editar"><v-icon>mdi-pencil</v-icon></v-btn>
                                 <v-btn icon size="x-small" variant="text" color="error" @click="deleteDraft(draft)" title="Excluir"><v-icon>mdi-delete</v-icon></v-btn>
                             </div>
                        </div>
                     </v-list>
                </v-window-item>

            </v-window>
        </v-card>
    </div>

    <v-dialog v-model="showIssueModal" fullscreen transition="dialog-bottom-transition">
        <v-card class="bg-background d-flex flex-column overflow-hidden">
            <v-toolbar color="surface" class="border-b border-opacity-10 px-4" density="comfortable">
                <v-btn icon="mdi-close" variant="text" @click="showIssueModal = false" color="medium-emphasis"></v-btn>
                <v-toolbar-title class="text-subtitle-1 font-weight-black text-high-emphasis ml-2">
                    {{ isEditingDraft ? 'Editando Rascunho' : 'Nova NFe 55' }}
                </v-toolbar-title>
                <v-spacer></v-spacer>

                <div class="mr-4 text-caption font-weight-bold bg-indigo-lighten-5 px-3 py-1 rounded text-indigo-darken-2 border border-indigo-lighten-4 hidden-xs-only">
                    Próxima: <span class="font-mono">{{ nextNfeNumber }}</span>
                </div>

                <v-btn variant="text" color="warning" class="text-none font-weight-bold mr-2 hidden-xs-only" @click="saveDraft" :loading="savingDraft">Salvar Rascunho</v-btn>
                <v-btn variant="outlined" color="indigo" class="text-none font-weight-bold mr-2 border-dashed" @click="generatePreview">Prévia</v-btn>
                <v-btn color="indigo" variant="flat" class="text-none font-weight-bold px-6" :loading="issuing" @click="submitNfe">
                    <v-icon start>mdi-send</v-icon> Transmitir
                </v-btn>
            </v-toolbar>

            <div class="d-flex flex-grow-1 overflow-hidden">
                 <div class="bg-surface border-r border-opacity-10 d-none d-md-flex flex-column pa-6 gap-2" style="width: 250px;">
                    <div v-for="(step, i) in steps" :key="i" class="d-flex align-center gap-3 pa-3 rounded-lg cursor-pointer transition-all" :class="currentStep === i ? 'bg-indigo-lighten-5 text-indigo' : 'text-medium-emphasis hover-bg'" @click="currentStep = i">
                        <div class="step-circle font-weight-bold" :class="currentStep === i ? 'bg-indigo text-white' : 'bg-background border'">{{ i + 1 }}</div>
                        <span class="font-weight-bold text-caption">{{ step }}</span>
                    </div>
                </div>

                <div class="flex-grow-1 overflow-y-auto pa-4 pa-md-8 bg-background">
                    <div style="max-width: 900px; margin: 0 auto;">

                        <div v-show="currentStep === 0">
                            <h2 class="text-h6 font-weight-black text-high-emphasis mb-6">Dados do Destinatário</h2>
                            <v-card class="rounded-xl pa-6 border-thin shadow-sm mb-4 bg-surface" elevation="0">
                                <v-autocomplete
                                    v-model="selectedClient"
                                    :items="auxData.clients"
                                    item-title="nome"
                                    item-value="id"
                                    label="Buscar Cliente (Cajuia)"
                                    placeholder="Digite o nome..."
                                    variant="outlined" density="comfortable"
                                    prepend-inner-icon="mdi-account-search"
                                    return-object
                                    @update:model-value="onClientSelect"
                                    class="mb-4" hide-details="auto"
                                ></v-autocomplete>

                                <v-row dense>
                                    <v-col cols="12" md="4"><v-text-field v-model="form.destinatario.cnpj_cpf" label="CPF / CNPJ" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="8"><v-text-field v-model="form.destinatario.nome" label="Razão Social / Nome" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="4"><v-text-field v-model="form.destinatario.ie" label="Inscrição Estadual" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="8"><v-text-field v-model="form.destinatario.email" label="E-mail" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                </v-row>
                            </v-card>

                            <h3 class="text-subtitle-2 font-weight-bold text-high-emphasis mb-3 mt-6">Endereço</h3>
                            <v-card class="rounded-xl pa-6 border-thin shadow-sm bg-surface" elevation="0">
                                <v-row dense>
                                    <v-col cols="12" md="3"><v-text-field v-model="form.destinatario.endereco.cep" label="CEP" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="7"><v-text-field v-model="form.destinatario.endereco.logradouro" label="Logradouro" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="2"><v-text-field v-model="form.destinatario.endereco.numero" label="Número" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="5"><v-text-field v-model="form.destinatario.endereco.bairro" label="Bairro" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="5"><v-text-field v-model="form.destinatario.endereco.municipio" label="Município" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="12" md="2"><v-select v-model="form.destinatario.endereco.uf" :items="estados" label="UF" variant="outlined" density="compact" hide-details></v-select></v-col>
                                </v-row>
                            </v-card>
                        </div>

                        <div v-show="currentStep === 1">
                            <div class="d-flex justify-space-between align-center mb-6">
                                <h2 class="text-h6 font-weight-black text-high-emphasis">Itens da Nota</h2>
                                <v-btn color="indigo" variant="tonal" class="text-none font-weight-bold" prepend-icon="mdi-plus" @click="addItem">Adicionar Item</v-btn>
                            </div>

                            <div v-for="(item, idx) in form.itens" :key="idx" class="bg-surface rounded-xl pa-5 border-thin shadow-sm mb-4 position-relative">
                                <div class="position-absolute top-0 right-0 pa-2">
                                    <v-btn icon="mdi-close" size="x-small" variant="text" color="error" @click="removeItem(idx)" v-if="form.itens.length > 1"></v-btn>
                                </div>
                                <v-row dense>
                                    <v-col cols="12" md="6">
                                        <v-combobox
                                            v-model="item.descricao"
                                            :items="auxData.products"
                                            item-title="label"
                                            item-value="label"
                                            label="Descrição do Produto"
                                            variant="outlined" density="compact" hide-details
                                            @update:model-value="() => onItemSelect(item)"
                                            return-object
                                        ></v-combobox>
                                    </v-col>
                                    <v-col cols="6" md="3"><v-text-field v-model="item.ncm" label="NCM" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="6" md="3"><v-text-field v-model="item.cfop" label="CFOP" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="4" md="2"><v-text-field v-model="item.quantidade" label="Qtd" type="number" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="4" md="3"><v-text-field v-model="item.valor_unitario" label="Unitário (R$)" type="number" variant="outlined" density="compact" hide-details></v-text-field></v-col>
                                    <v-col cols="4" md="3">
                                        <div class="bg-background pa-2 rounded border border-opacity-10 text-right font-weight-bold text-high-emphasis h-100 d-flex align-center justify-end">
                                            {{ formatCurrency(item.quantidade * item.valor_unitario) }}
                                        </div>
                                    </v-col>
                                </v-row>
                            </div>
                             <div class="bg-indigo-lighten-5 pa-4 rounded-xl d-flex justify-end align-center gap-4 mt-6">
                                <span class="text-uppercase font-weight-bold text-indigo-darken-2">Total</span>
                                <span class="text-h4 font-weight-black text-indigo">{{ formatCurrency(totalFormValue) }}</span>
                            </div>
                        </div>

                        <div v-show="currentStep === 2">
                            <h2 class="text-h6 font-weight-black text-high-emphasis mb-6">Pagamento & Obs</h2>
                             <v-card class="rounded-xl pa-6 border-thin shadow-sm mb-6 bg-surface" elevation="0">
                                <v-radio-group v-model="form.pagamento.forma" inline hide-details class="mb-4">
                                    <v-radio label="À Vista" value="0" color="indigo"></v-radio>
                                    <v-radio label="À Prazo" value="1" color="indigo"></v-radio>
                                </v-radio-group>
                                <v-row dense>
                                     <v-col cols="12" md="6">
                                        <v-select v-model="form.pagamento.meio" :items="auxData.paymentMethods" item-title="name" item-value="value" label="Meio de Pagamento" variant="outlined" density="compact" hide-details></v-select>
                                     </v-col>
                                </v-row>
                            </v-card>
                            <h3 class="text-subtitle-2 font-weight-bold text-high-emphasis mb-3">Observações</h3>
                            <v-textarea v-model="form.obs" variant="outlined" density="comfortable" placeholder="Informações adicionais na nota..." rows="4" bg-color="surface"></v-textarea>
                        </div>
                    </div>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="danfeModal.show" fullscreen transition="dialog-bottom-transition">
      <v-card class="bg-background d-flex flex-row overflow-hidden">
        <div class="flex-grow-1 d-flex flex-column h-screen">
            <div class="bg-surface border-b border-opacity-10 px-6 py-3 d-flex justify-space-between align-center shadow-sm z-10">
                <div class="d-flex align-center gap-4">
                    <v-btn icon variant="text" @click="danfeModal.show = false"><v-icon>mdi-close</v-icon></v-btn>
                    <v-divider vertical class="h-24"></v-divider>
                    <div class="d-flex flex-column">
                        <div class="text-body-2 font-weight-bold text-high-emphasis">Visualização DANFE/XML</div>
                    </div>
                </div>
            </div>
            <div class="flex-grow-1 bg-background d-flex justify-center align-center relative overflow-hidden">
                <div v-if="previewLoading" class="text-center"><v-progress-circular indeterminate color="indigo" size="64"></v-progress-circular></div>
                <iframe v-else :src="danfeModal.url" class="pdf-iframe shadow-lg" frameborder="0"></iframe>
            </div>
        </div>
      </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { sefazService } from '@/api/sefazApi';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { format, parseISO } from 'date-fns';
import { DANFe } from 'node-sped-pdf';
import { PDFDocument, rgb, degrees, StandardFonts } from 'pdf-lib';
import axios from 'axios';

const route = useRoute();
const router = useRouter();
const appStore = useAppStore();
const userStore = useUserStore();

const activeCompany = ref<any>(null); // Agora será setado automaticamente
const notes = ref<any[]>([]);
const search = ref('');
const activeTab = ref(0);

const loadingCompanies = ref(false);
const loading = ref(false);
const issuing = ref(false);
const savingDraft = ref(false);
const previewLoading = ref(false);

const showIssueModal = ref(false);
const isEditingDraft = ref(false);
const editingDraftId = ref<string | null>(null);
const nextNfeNumber = ref(0);
const sourceOrderId = ref<string | null>(null);

const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const currentStep = ref(0);
const steps = ['Destinatário', 'Produtos', 'Pagamento'];
const estados = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'PE', 'DF', 'GO', 'ES', 'CE', 'PA', 'MA', 'PB', 'AM', 'RN', 'AL', 'PI', 'MT', 'MS', 'SE', 'RO', 'TO', 'AC', 'AP', 'RR'];

const auxData = reactive({ clients: [] as any[], products: [] as any[], paymentMethods: [] as any[] });
const selectedClient = ref<any>(null);

const initialFormState = {
    natureza_operacao: 'VENDA DE MERCADORIA',
    destinatario: { cnpj_cpf: '', nome: '', ie: '', email: '', endereco: { logradouro: '', numero: '', bairro: '', municipio: '', uf: 'SP', cep: '' } },
    itens: [{ descricao: '', ncm: '', cfop: '5102', quantidade: 1, valor_unitario: 0 }],
    pagamento: { forma: '0', meio: '99' },
    obs: ''
};
const form = reactive(JSON.parse(JSON.stringify(initialFormState)));
const danfeModal = reactive({ show: false, url: '', type: 'pdf' });

const isFromOrder = computed(() => !!sourceOrderId.value);

const filteredNotes = computed(() => {
    let list = notes.value.filter(n => n.status !== 'RASCUNHO');
    if (search.value) {
        const term = search.value.toLowerCase();
        list = list.filter(n => (n.destinatario_nome && String(n.destinatario_nome).toLowerCase().includes(term)) || (n.numero && String(n.numero).includes(term)));
    }
    return list;
});
const filteredDrafts = computed(() => notes.value.filter(n => n.status === 'RASCUNHO'));
const draftsCount = computed(() => notes.value.filter(n => n.status === 'RASCUNHO').length);
const totalValue = computed(() => notes.value.filter(n => n.status === 'AUTORIZADA').reduce((acc, n) => acc + (Number(n.valor_total) || 0), 0));
const totalFormValue = computed(() => form.itens.reduce((acc: number, item: any) => acc + (item.quantidade * item.valor_unitario), 0));

const fetchAuxiliaryData = async () => {
    try {
        const [clientsRes, productsRes, paymentsRes] = await Promise.all([
            supabase.from('cajuia_clients').select('*').limit(500),
            // ADICIONADO NCM PARA MAPEAR AUTOMATICAMENTE
            supabase.from('cajuia_products').select('name, sku, price, ncm'),
            supabase.from('finance_payment_methods').select('id, name')
        ]);

        auxData.clients = (clientsRes.data || []).map((c:any) => ({
             id: c.id, nome: c.name, cpf: c.cpf_cnpj, email: c.email,
             endereco: '', numero: '', bairro: '', cidade: c.city, estado: c.state, cep: ''
        }));

        auxData.products = (productsRes.data || []).map((p:any) => ({
            label: p.name,
            price: p.price,
            ncm: p.ncm || '' // Mapeando NCM
        }));

        const codeMap: any = { 'Dinheiro': '01', 'Cheque': '02', 'Cartão de Crédito': '03', 'Cartão de Débito': '04', 'PIX': '17', 'Boleto': '15', 'Sem Pagamento': '90' };
        auxData.paymentMethods = (paymentsRes.data || []).map(p => ({ ...p, value: codeMap[p.name] || p.id }));
    } catch (e: any) { console.error('Erro aux data', e); }
};

const onClientSelect = (client: any) => {
    if (!client) return;
    form.destinatario.cnpj_cpf = client.cpf || '';
    form.destinatario.nome = client.nome || '';
    form.destinatario.email = client.email || '';
    form.destinatario.endereco.municipio = client.cidade || '';
    form.destinatario.endereco.uf = client.estado || 'SP';
};

const onItemSelect = (item: any) => {
    const selectedValue = typeof item.descricao === 'string' ? item.descricao : item.descricao?.label;
    if (typeof item.descricao === 'object' && item.descricao !== null) item.descricao = item.descricao.label;
    const selectedProd = auxData.products.find(p => p.label === selectedValue);
    if(selectedProd) {
        if(selectedProd.price) item.valor_unitario = Number(selectedProd.price);
        if(selectedProd.ncm) item.ncm = selectedProd.ncm;
    }
};

const loadCompanies = async () => {
   loadingCompanies.value = true;
   try {
      const nuvemResponse = await sefazService.listarEmpresas();
      const nuvemCompanies = nuvemResponse.data || (Array.isArray(nuvemResponse) ? nuvemResponse : []);
      const { data: dbCompanies } = await supabase.from('companies').select('*');

      const allCompanies = nuvemCompanies.map((nc: any) => {
          const dbConfig = (dbCompanies || []).find((dbc: any) => dbc.cnpj.replace(/\D/g, '') === nc.cnpj.replace(/\D/g, ''));
          return { ...nc, id: dbConfig?.id || nc.id, nfe_environment: dbConfig?.nfe_environment || 'homologacao', nfe_series: dbConfig?.nfe_series || 1, nfe_next_number: parseInt(dbConfig?.nfe_next_number) || 0, nfe_info_complementar: dbConfig?.nfe_info_complementar || '', ie: dbConfig?.ie || nc.inscricao_estadual, crt: dbConfig?.crt || '3' };
      });

      // LÓGICA RÍGIDA CORRIGIDA: Acha a Santos e Lopes pelo CNPJ exato
      // CNPJ alvo: 53.756.096/0001-89
      const cajuia = allCompanies.find((c: any) => c.cnpj.replace(/\D/g, '') === '53756096000189');

      if (cajuia) {
          activeCompany.value = cajuia;
          fetchHistory(cajuia.cnpj);
      } else {
          appStore.showSnackbar('Empresa Santos & Lopes não encontrada na SEFAZ.', 'error');
      }

   } catch (e: any) { console.error(e); } finally { loadingCompanies.value = false; }
};

const fetchHistory = async (cnpj: string) => {
    loading.value = true;
    try {
        let query = supabase
            .from('nfe_outbound')
            .select('*')
            .eq('emitente_cnpj', cnpj)
            .order('created_at', { ascending: false });

        // Removemos temporariamente o filtro created_by se a coluna não existir para evitar Erro 400
        // Se sua tabela nfe_outbound tiver user_id ou vendedor_id, altere aqui.
        if (userStore.user?.id) {
             // query = query.eq('created_by', userStore.user.id);
        }

        const { data } = await query;
        notes.value = data || [];
    } catch (e) { console.error(e); } finally { loading.value = false; }
};

const getNextNumber = async () => {
    if (!activeCompany.value) return 1;
    let configNum = Number(activeCompany.value.nfe_next_number) || 0;
    const { data } = await supabase.from('nfe_outbound').select('numero').eq('emitente_cnpj', activeCompany.value.cnpj).eq('status', 'AUTORIZADA').order('numero', { ascending: false }).limit(1).maybeSingle();
    return Math.max(configNum, (data?.numero ? Number(data.numero) : 0) + 1);
};

const openNewNoteModal = async () => {
    Object.assign(form, JSON.parse(JSON.stringify(initialFormState)));
    selectedClient.value = null;
    currentStep.value = 0;
    isEditingDraft.value = false;
    editingDraftId.value = null;
    showIssueModal.value = true;
    nextNfeNumber.value = await getNextNumber();
};

const loadOrderData = async (orderId: string) => {
    try {
        // CORREÇÃO CRÍTICA: Abrir e resetar o modal ANTES de preencher
        await openNewNoteModal();

        const { data: order } = await supabase.from('cajuia_orders').select('*').eq('id', orderId).single();
        const { data: items } = await supabase.from('cajuia_order_items').select('*').eq('order_id', orderId);

        if (order) {
            sourceOrderId.value = orderId;
            form.destinatario.nome = order.customer_name || '';

            // Tenta encontrar o cliente para preencher endereço e CPF
            const clientMatch = auxData.clients.find(c => c.nome.toLowerCase() === order.customer_name?.toLowerCase());
            if(clientMatch) {
                 selectedClient.value = clientMatch; // Atualiza o componente visual
                 onClientSelect(clientMatch); // Preenche campos do form
            }

            // Preenche itens
            if (items && items.length > 0) {
                form.itens = items.map((i: any) => {
                    // Tenta achar o produto na lista auxiliar para pegar o NCM
                    const prodMatch = auxData.products.find(p => p.label === i.product_name);
                    return {
                        descricao: i.product_name,
                        ncm: prodMatch?.ncm || '',
                        cfop: '5102',
                        quantidade: i.quantity,
                        valor_unitario: i.unit_price
                    };
                });
            }
        }
    } catch(e) { console.error("Erro ao carregar pedido", e); }
};

const addItem = () => form.itens.push({ descricao: '', ncm: '', cfop: '5102', quantidade: 1, valor_unitario: 0 });
const removeItem = (idx: number) => form.itens.splice(idx, 1);

const saveDraft = async () => {
    if (!activeCompany.value) return;
    savingDraft.value = true;
    try {
        const payload = { emitente_cnpj: activeCompany.value.cnpj, destinatario_nome: form.destinatario.nome || 'Rascunho', valor_total: totalFormValue.value, status: 'RASCUNHO', created_by: userStore.user?.id, retorno_sefaz: { payload: JSON.parse(JSON.stringify(form)) } };
        if (isEditingDraft.value && editingDraftId.value) await supabase.from('nfe_outbound').update(payload).eq('id', editingDraftId.value);
        else await supabase.from('nfe_outbound').insert(payload);
        appStore.showSnackbar('Rascunho salvo!', 'success'); showIssueModal.value = false; fetchHistory(activeCompany.value.cnpj);
    } catch (e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { savingDraft.value = false; }
};

const editDraft = (draft: any) => {
    let draftData = draft.retorno_sefaz?.payload || draft.retorno_sefaz;
    if (draftData) Object.assign(form, draftData);
    isEditingDraft.value = true; editingDraftId.value = draft.id; showIssueModal.value = true; currentStep.value = 0;
};

const emitDraft = async (draft: any) => {
    let draftData = draft.retorno_sefaz?.payload || draft.retorno_sefaz;
    if (!draftData) return;
    if(!confirm(`Emitir NFe para ${draft.destinatario_nome}?`)) return;
    issuing.value = true;
    try {
        const draftForm = draftData;
        const numeroNota = await getNextNumber();
        const payload = { natureza_operacao: draftForm.natureza_operacao, destinatario: draftForm.destinatario, itens: draftForm.itens, pagamentos: [{ meio_pagamento: (typeof draftForm.pagamento.meio === 'string' && draftForm.pagamento.meio.length === 2) ? draftForm.pagamento.meio : '99', valor: draft.valor_total, forma_pagamento: draftForm.pagamento.forma }], ambiente: activeCompany.value.nfe_environment || 'homologacao', serie: activeCompany.value.nfe_series || 1, crt: activeCompany.value.crt, numero: numeroNota, informacoes_adicionais: `${draftForm.obs || ''} ${activeCompany.value.nfe_info_complementar || ''}`.trim() };

        const result = await sefazService.emitirNFe(payload, draft.emitente_cnpj, activeCompany.value.ie);
        const isSuccess = result.status === 'autorizado' || result.status === 'success';
        if (isSuccess) await supabase.from('companies').update({ nfe_next_number: numeroNota + 1 }).eq('id', activeCompany.value.id);

        const dbPayload = { status: isSuccess ? 'AUTORIZADA' : 'REJEITADA', chave: result.chave, numero: result.numero, xml_link: result.xml_url, pdf_link: result.pdf_url, retorno_sefaz: { ...result, payload: draftForm } };
        await supabase.from('nfe_outbound').update(dbPayload).eq('id', draft.id);

        appStore.showSnackbar(isSuccess ? 'NFe emitida!' : 'Rejeitada pela SEFAZ.', isSuccess ? 'success' : 'error');
        fetchHistory(activeCompany.value.cnpj);
    } catch (e: any) { appStore.showSnackbar('Erro emissão: ' + e.message, 'error'); } finally { issuing.value = false; }
};

const deleteDraft = async (draft: any) => { if(confirm('Excluir?')) { await supabase.from('nfe_outbound').delete().eq('id', draft.id); fetchHistory(activeCompany.value.cnpj); } };

const viewDocument = async (note: any, docType: 'pdf' | 'xml') => {
    if (danfeModal.url) URL.revokeObjectURL(danfeModal.url);
    danfeModal.url = ''; danfeModal.show = true; danfeModal.type = docType; previewLoading.value = true;
    try {
        const cnpj = activeCompany.value?.cnpj?.replace(/\D/g, '');
        const nuvemId = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
        let url = nuvemId ? `${SEFAZ_PROXY_URL}/api/nfe/download/${docType}/${nuvemId}?cnpj=${cnpj}` : `${SEFAZ_PROXY_URL}/api/${docType === 'pdf' ? 'danfe' : 'baixar-xml'}/${note.chave}?cnpj=${cnpj}`;
        const response = await axios.get(url, { responseType: 'blob' });
        danfeModal.url = URL.createObjectURL(new Blob([response.data], { type: docType === 'pdf' ? 'application/pdf' : 'text/xml' }));
    } catch (e) { appStore.showSnackbar('Erro ao carregar documento.', 'error'); } finally { previewLoading.value = false; }
};

const cancelNote = async (note: any) => {
    const just = prompt("Justificativa (mín 15 chars):");
    if (!just || just.length < 15) return;
    try {
        const idParaCancelar = note.retorno_sefaz?.id_nuvem || note.retorno_sefaz?.id;
        await sefazService.cancelarNFe(idParaCancelar, just);
        await supabase.from('nfe_outbound').update({ status: 'CANCELADA' }).eq('id', note.id);
        appStore.showSnackbar('Cancelada!', 'success'); fetchHistory(activeCompany.value.cnpj);
    } catch (e: any) { appStore.showSnackbar('Erro ao cancelar: ' + e.message, 'error'); }
};

const submitNfe = async () => {
    if (!activeCompany.value) return appStore.showSnackbar('Erro: Empresa não carregada.', 'error');
    issuing.value = true;
    const numeroNota = await getNextNumber();
    const payload = { natureza_operacao: form.natureza_operacao, destinatario: form.destinatario, itens: form.itens, pagamentos: [{ meio_pagamento: (typeof form.pagamento.meio === 'string' && form.pagamento.meio.length === 2) ? form.pagamento.meio : '99', valor: totalFormValue.value, forma_pagamento: form.pagamento.forma }], ambiente: activeCompany.value.nfe_environment || 'homologacao', serie: activeCompany.value.nfe_series || 1, crt: activeCompany.value.crt, numero: numeroNota, informacoes_adicionais: `${form.obs || ''} ${activeCompany.value.nfe_info_complementar || ''}`.trim() };

    try {
        const result = await sefazService.emitirNFe(payload, activeCompany.value.cnpj, activeCompany.value.ie);
        const isSuccess = result.status === 'autorizado' || result.status === 'success';
        if (isSuccess) await supabase.from('companies').update({ nfe_next_number: numeroNota + 1 }).eq('id', activeCompany.value.id);

        const dbPayload = {
            emitente_cnpj: activeCompany.value.cnpj,
            destinatario_nome: form.destinatario.nome,
            valor_total: totalFormValue.value,
            status: isSuccess ? 'AUTORIZADA' : 'REJEITADA',
            chave: result.chave,
            numero: result.numero,
            xml_link: result.xml_url,
            pdf_link: result.pdf_url,
            created_by: userStore.user?.id,
            retorno_sefaz: { ...result, payload: payload }
        };
        await supabase.from('nfe_outbound').insert(dbPayload);

        if (isSuccess && sourceOrderId.value) {
            await supabase.from('cajuia_orders').update({
                nfe_key: result.chave,
                sales_order_pdf_url: result.pdf_url
            }).eq('id', sourceOrderId.value);
            appStore.showSnackbar('Nota autorizada e vinculada ao pedido!', 'success');
        } else {
            appStore.showSnackbar(isSuccess ? 'Autorizada!' : 'Rejeitada.', isSuccess ? 'success' : 'error');
        }

        showIssueModal.value = false; fetchHistory(activeCompany.value.cnpj);
    } catch (e: any) { appStore.showSnackbar('Erro: ' + e.message, 'error'); } finally { issuing.value = false; }
};

const generatePreview = async () => {
    previewLoading.value = true; danfeModal.show = true; danfeModal.type = 'pdf';
    try {
        const xml = `<nfeProc>...</nfeProc>`;
        const pdfResult = await DANFe({ xml });
        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage();
        page.drawText('PREVIEW DA NOTA FISCAL (Simulação)', { x: 50, y: 700, size: 20 });
        const pdfBytes = await pdfDoc.save();
        danfeModal.url = URL.createObjectURL(new Blob([pdfBytes], { type: 'application/pdf' }));
    } catch { danfeModal.show = false; } finally { previewLoading.value = false; }
};

const goBack = () => router.back();

const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCompact = (val: any) => new Intl.NumberFormat('pt-BR', { notation: "compact", style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy HH:mm') : '-';
const formatKey = (k: string) => k ? `${k.substring(0,4)}...${k.substring(k.length-4)}` : '';
const getStatusColor = (s: any) => { if (s === 'AUTORIZADA') return 'success'; if (s === 'RASCUNHO') return 'amber'; return 'error'; }
const getStatusIcon = (s: any) => { if (s === 'AUTORIZADA') return 'mdi-check'; if (s === 'RASCUNHO') return 'mdi-pencil'; return 'mdi-alert'; }
const getStatusClass = (s: any) => { if (s === 'AUTORIZADA') return 'bg-green-lighten-5 text-success'; if (s === 'RASCUNHO') return 'bg-amber-lighten-5 text-amber-darken-3'; return 'bg-red-lighten-5 text-red'; }

onMounted(async () => {
    // 1. Carrega dados auxiliares (clientes, produtos) PRIMEIRO
    await fetchAuxiliaryData();
    // 2. Carrega empresa e histórico
    await loadCompanies();
    // 3. Se tiver ID na URL, carrega o pedido (agora já temos clientes para fazer o match)
    if (route.query.orderId) {
        await loadOrderData(route.query.orderId as string);
    }
});
</script>

<style scoped>
.icon-box-sm { width: 36px; height: 36px; }
.hover-bg:hover { background-color: rgba(var(--v-theme-on-surface), 0.04); }
.border-l-4-amber { border-left: 4px solid #FFC107 !important; }
.step-circle { width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; border-radius: 50%; font-size: 12px; }
.shadow-indigo-soft { box-shadow: 0 4px 12px rgba(63, 81, 181, 0.3); }
.pdf-iframe { width: 100%; height: 100%; border: none; background: white; }
</style>
