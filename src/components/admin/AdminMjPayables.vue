<template>
  <div class="page-wrapper h-100 bg-background-light overflow-y-auto custom-scrollbar">

    <div class="content-container mx-auto pa-6 pa-md-8" style="max-width: 1400px;">

      <div class="d-flex flex-column flex-md-row justify-space-between align-md-center gap-4 mb-8">
        <div>
          <div class="d-flex align-center gap-2 mb-1">
             <div class="icon-box-md bg-primary-transparent text-primary rounded-lg d-flex align-center justify-center" style="width: 32px; height: 32px;">
                <v-icon size="20">mdi-invoice-text-clock-outline</v-icon>
             </div>
             <h1 class="text-h5 font-weight-black text-grey-darken-4">Gestão de DFe</h1>
          </div>
          <p class="text-body-2 text-grey-darken-1">Central de notas fiscais de entrada e automação financeira.</p>
        </div>

        <div class="d-flex gap-3">
            <v-btn
              variant="outlined"
              color="grey-darken-1"
              class="text-none font-weight-bold px-4 border-dashed"
              height="44"
              rounded="lg"
              prepend-icon="mdi-shield-key-outline"
              @click="openCertModal"
            >
              Certificado Digital
            </v-btn>

            <v-btn
              color="blue-grey-lighten-5"
              variant="flat"
              class="text-none font-weight-bold text-blue-grey-darken-2"
              height="44"
              rounded="lg"
              prepend-icon="mdi-upload-outline"
              @click="triggerXmlInput"
            >
              Upload XML
            </v-btn>
            <input type="file" ref="xmlInput" class="d-none" accept=".xml" multiple @change="handleXmlUpload">

            <v-menu location="bottom end" transition="slide-y-transition" :close-on-content-click="true">
              <template v-slot:activator="{ props }">
                <v-btn
                  v-bind="props"
                  color="white"
                  variant="flat"
                  class="text-none font-weight-bold px-4 border shadow-sm"
                  height="44"
                  rounded="lg"
                  :loading="loadingCompanies"
                >
                  <v-avatar start size="22" :color="activeCompany ? 'primary' : 'grey-lighten-2'" class="mr-2">
                     <span class="text-caption text-white font-weight-bold" v-if="activeCompany">{{ activeCompany.name.substring(0,1) }}</span>
                     <v-icon v-else size="12" color="white">mdi-domain</v-icon>
                  </v-avatar>
                  <div class="d-flex flex-column align-start text-left mr-2" style="line-height: 1.1;">
                     <span class="text-caption font-weight-bold text-grey-darken-3">{{ activeCompany?.name || 'Selecione' }}</span>
                     <span class="text-[10px] text-grey">{{ activeCompany?.cnpj || '---' }}</span>
                  </div>
                  <v-icon color="grey-lighten-1" size="20">mdi-chevron-down</v-icon>
                </v-btn>
              </template>
              <v-card min-width="300" class="rounded-xl shadow-lg mt-2 border-thin">
                 <v-list density="compact" class="py-2">
                   <v-list-subheader class="text-uppercase font-weight-bold text-[10px] letter-spacing-1">Minhas Empresas</v-list-subheader>
                   <v-list-item
                     v-for="company in companies"
                     :key="company.id"
                     @click="switchCompany(company)"
                     :active="activeCompany?.id === company.id"
                     class="px-4 py-2 mb-1"
                     rounded="lg"
                     color="primary"
                   >
                     <template v-slot:prepend>
                        <v-icon :color="company.status === 'active' ? 'success' : 'grey-lighten-2'" size="10" class="mr-2">mdi-circle</v-icon>
                     </template>
                     <v-list-item-title class="font-weight-bold text-caption">{{ company.name }}</v-list-item-title>
                     <v-list-item-subtitle class="text-[10px]">{{ company.cnpj }}</v-list-item-subtitle>
                   </v-list-item>
                 </v-list>
              </v-card>
            </v-menu>
        </div>
      </div>

      <v-card class="rounded-xl border-thin shadow-sm mb-8 overflow-hidden bg-white">
         <div class="d-flex flex-column flex-md-row divide-md-x">
            <div class="flex-grow-1 pa-6 d-flex flex-column justify-center relative overflow-hidden">
               <div class="d-flex justify-space-between align-start mb-4 z-10 relative">
                  <div>
                     <div class="d-flex align-center gap-2 mb-1">
                        <div class="status-dot pulsing" :class="syncing ? 'bg-blue' : 'bg-success'"></div>
                        <span class="text-caption font-weight-bold text-uppercase text-grey-darken-1 letter-spacing-1">Sincronização</span>
                     </div>
                     <div class="text-subtitle-2 font-weight-black text-grey-darken-3">
                        {{ syncing ? 'Conectando à SEFAZ...' : 'Base Local Atualizada' }}
                     </div>
                     <div class="text-[10px] text-grey mt-1">Última verificação: {{ lastSyncTime }}</div>
                  </div>
                  <v-btn
                     color="primary"
                     variant="tonal"
                     size="small"
                     class="font-weight-bold text-none px-4"
                     :loading="syncing"
                     @click="syncNotesFromSefaz"
                     prepend-icon="mdi-refresh"
                     rounded="lg"
                  >
                     Sincronizar
                  </v-btn>
               </div>
               <div class="absolute-bg-icon">
                  <v-icon color="grey-lighten-4" size="120">mdi-cloud-sync-outline</v-icon>
               </div>
            </div>

            <div class="pa-6 d-flex align-center gap-8 bg-grey-lighten-5" style="min-width: 300px;">
               <div>
                  <div class="text-[10px] font-weight-bold text-grey text-uppercase mb-1">Notas Baixadas  </div>
                  <div class="text-h4 font-weight-black text-grey-darken-3 lh-1">{{ notes.length }}</div>
               </div>
               <v-divider vertical class="h-50 align-self-center border-grey-lighten-2"></v-divider>
               <div>
                  <div class="text-[10px] font-weight-bold text-grey text-uppercase mb-1">   Total (R$)</div>
                  <div class="text-h4 font-weight-black text-success lh-1">{{ formatCompact(totalValue) }}</div>
               </div>
            </div>
         </div>
      </v-card>

      <div v-if="notes.length > 0">
         <div class="d-flex justify-space-between align-center mb-4 px-2">
            <h3 class="text-subtitle-2 font-weight-black text-grey-darken-2 text-uppercase letter-spacing-1">Últimos Documentos</h3>
            <v-text-field
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar por Fornecedor, Valor ou Chave..."
                prepend-inner-icon="mdi-magnify"
                single-line hide-details
                style="max-width: 350px"
                bg-color="white"
                class="search-input"
            ></v-text-field>
         </div>

         <div class="d-flex flex-column gap-3">
            <div v-for="note in filteredNotes" :key="note.chave" class="note-row bg-white rounded-xl pa-4 border-thin shadow-xs d-flex align-center gap-4 transition-all group">

               <div class="icon-box rounded-lg pa-3 transition-colors" :class="getIconBoxClass(note)">
                  <v-icon :color="getIconColor(note)" size="20">mdi-file-document-outline</v-icon>
               </div>

               <div class="flex-grow-1" style="min-width: 0;">
                  <div class="d-flex align-center gap-3 mb-1">
                     <span class="text-subtitle-2 font-weight-bold text-grey-darken-4 text-truncate" :title="note.emitente_nome">
                        {{ note.emitente_nome || 'Emitente Desconhecido' }}
                     </span>

                     <v-chip
                        v-if="note.status_processamento === 'contas_a_pagar_gerado'"
                        size="x-small"
                        color="success"
                        variant="tonal"
                        class="font-weight-bold text-uppercase border-success"
                     >
                        <v-icon start size="10">mdi-check-all</v-icon> Lançado
                     </v-chip>

                     <v-chip
                        v-else
                        size="x-small"
                        :color="getManifestColor(note)"
                        variant="tonal"
                        class="font-weight-bold text-uppercase h-auto py-0.5"
                     >
                        {{ getManifestLabel(note) }}
                     </v-chip>
                  </div>

                  <div class="d-flex align-center gap-4 text-caption text-grey-darken-1 flex-wrap font-mono">
                     <div class="d-flex align-center gap-1 bg-grey-lighten-5 px-2 py-0.5 rounded">
                        <v-icon size="12" color="grey">mdi-calendar</v-icon>
                        <span>{{ formatDate(note.data_emissao) }}</span>
                     </div>
                     <div class="d-flex align-center gap-1 px-2 py-0.5">
                        <v-icon size="12" color="grey">mdi-barcode</v-icon>
                        <span class="text-[10px]">{{ formatKey(note.chave) }}</span>
                     </div>
                     <div class="d-flex align-center gap-1 px-2 py-0.5">
                        <v-icon size="12" color="grey">mdi-domain</v-icon>
                        <span class="text-[10px]">{{ note.emitente_cnpj }}</span>
                     </div>
                  </div>
               </div>

               <div class="text-right px-6 border-r border-grey-lighten-2" style="min-width: 140px;">
                  <div class="text-[9px] font-weight-bold text-grey text-uppercase mb-0.5">Valor Total</div>
                  <div class="text-subtitle-1 font-weight-black text-grey-darken-3 font-mono">
                     {{ formatCurrency(note.valor) }}
                  </div>
               </div>

               <div class="d-flex align-center gap-2 pl-3">

                <button
                    v-if="!isManifested(note)"
                    class="action-btn success-btn"
                    @click="manifestNote(note, 'confirmacao')"
                    :disabled="processingManifest === note.chave"
                >
                    <v-progress-circular
                        v-if="processingManifest === note.chave"
                        indeterminate
                        size="16"
                        width="2"
                        color="success"
                    ></v-progress-circular>

                    <v-icon v-else size="16">mdi-check-bold</v-icon>

                    <v-tooltip activator="parent" location="top" text="Confirmar Nota" content-class="custom-tooltip-white" />
                </button>

                  <button class="action-btn primary-btn" @click="openDanfe(note)" :disabled="pdfLoading === note.chave">
                     <v-progress-circular v-if="pdfLoading === note.chave" indeterminate size="16" width="2" color="primary"></v-progress-circular>
                     <v-icon v-else size="16">mdi-file-eye-outline</v-icon>
                     <v-tooltip activator="parent" location="top" text="Ver DANFE (PDF)" content-class="custom-tooltip-white" />
                  </button>

                  <button class="action-btn info-btn" :disabled="!note.xml_link && !note.xml_id" @click="downloadXml(note)">
                     <v-icon size="16">mdi-xml</v-icon>
                     <v-tooltip activator="parent" location="top" text="Baixar XML" content-class="custom-tooltip-white" />
                  </button>

                  <button class="action-btn warning-btn" @click="openPayableModal(note)">
                     <v-icon size="16">mdi-cash-register</v-icon>
                     <v-tooltip activator="parent" location="top" text="Lançar Financeiro" content-class="tooltip-custom" />
                  </button>

                  <button class="action-btn error-btn" @click="deleteNote(note)">
                     <v-icon size="16">mdi-trash-can-outline</v-icon>
                     <v-tooltip activator="parent" location="top" text="Remover" content-class="custom-tooltip-white" />
                  </button>

               </div>
            </div>
         </div>
      </div>

      <div v-else-if="!loading" class="empty-state text-center py-16">
         <div class="bg-white rounded-circle d-inline-flex pa-8 mb-6 shadow-card border-thin">
            <v-icon size="64" color="grey-lighten-2">mdi-file-search-outline</v-icon>
         </div>
         <h3 class="text-h6 font-weight-bold text-grey-darken-3">Nenhuma nota encontrada</h3>
         <div class="d-flex justify-center gap-3 mt-6">
             <v-btn color="primary" variant="flat" size="large" class="text-none px-8 font-weight-bold rounded-lg" @click="syncNotesFromSefaz">Buscar na SEFAZ</v-btn>
         </div>
      </div>

      <div v-else class="text-center py-16">
         <v-progress-circular indeterminate color="primary" size="64" width="6"></v-progress-circular>
         <p class="text-subtitle-2 text-grey-darken-1 mt-6 font-weight-bold">Carregando documentos...</p>
      </div>

    </div>

    <CertificateUploadModal
      :show="certModal.show"
      :companies="companies"
      :initial-cnpj="activeCompany?.cnpj"
      :loading="uploading"
      @update:show="certModal.show = $event"
      @close="certModal.show = false"
      @upload="handleCertUpload"
    />

    <v-dialog v-model="payableModal.show" max-width="800" persistent>
        <v-card class="rounded-xl overflow-hidden border-thin shadow-card d-flex flex-row" style="height: 500px;">
            <div class="bg-grey-lighten-4 pa-6 d-flex flex-column" style="width: 280px; border-right: 1px solid rgba(0,0,0,0.05);">
                <div class="d-flex align-center gap-2 mb-6">
                    <div class="bg-white rounded pa-2 border shadow-xs">
                        <v-icon color="primary" size="20">mdi-file-document-outline</v-icon>
                    </div>
                    <div>
                        <div class="text-[10px] font-weight-bold text-uppercase text-grey-darken-1">Documento</div>
                        <div class="text-caption font-weight-black text-grey-darken-3">Detalhes da NFe</div>
                    </div>
                </div>
                <div class="d-flex flex-column gap-4">
                    <div>
                        <label class="text-[9px] font-weight-bold text-uppercase text-grey mb-1 d-block">Chave de Acesso</label>
                        <div class="text-[10px] font-mono text-grey-darken-3 bg-white px-2 py-1 rounded border break-all lh-1-2">{{ payableModal.note?.chave || '---' }}</div>
                    </div>
                    <div>
                        <label class="text-[9px] font-weight-bold text-uppercase text-grey mb-1 d-block">Emitente</label>
                        <div class="text-caption font-weight-bold text-grey-darken-3 lh-1-2">{{ payableModal.note?.emitente_nome }}</div>
                        <div class="text-[10px] text-grey-darken-1 mt-0.5">{{ payableModal.note?.emitente_cnpj }}</div>
                    </div>
                    <div class="d-flex gap-2">
                        <div class="flex-grow-1">
                            <label class="text-[9px] font-weight-bold text-uppercase text-grey mb-1 d-block">Emissão</label>
                            <div class="text-caption font-weight-bold text-grey-darken-3 bg-white px-2 py-1 rounded border text-center">{{ formatDate(payableModal.note?.data_emissao) }}</div>
                        </div>
                        <div class="flex-grow-1">
                            <label class="text-[9px] font-weight-bold text-uppercase text-grey mb-1 d-block">Valor Original</label>
                            <div class="text-caption font-weight-bold text-grey-darken-3 bg-white px-2 py-1 rounded border text-center">{{ formatCurrency(payableModal.note?.valor) }}</div>
                        </div>
                    </div>
                </div>
                <v-spacer></v-spacer>
            </div>
            <div class="flex-grow-1 d-flex flex-column bg-white">
                <div class="pa-5 border-b d-flex justify-space-between align-center">
                    <h3 class="text-subtitle-1 font-weight-black text-grey-darken-3">Novo Lançamento Financeiro</h3>
                    <v-btn icon="mdi-close" variant="text" density="compact" color="grey" @click="payableModal.show = false"></v-btn>
                </div>
                <div class="pa-6 flex-grow-1 overflow-y-auto">
                    <v-form @submit.prevent="confirmPayableLaunch">
                        <div class="mb-4">
                            <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Descrição do Lançamento</label>
                            <v-text-field v-model="payableForm.description" variant="outlined" density="compact" placeholder="Ex: Compra de Material..." hide-details class="clean-input"></v-text-field>
                        </div>
                        <v-row dense class="mb-4">
                            <v-col cols="6">
                                <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Vencimento (1ª Parc)</label>
                                <v-text-field v-model="payableForm.dueDate" type="date" variant="outlined" density="compact" hide-details class="clean-input"></v-text-field>
                            </v-col>
                            <v-col cols="6">
                                <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Valor Total</label>
                                <v-text-field v-model="payableForm.value" type="number" prefix="R$" variant="outlined" density="compact" hide-details class="clean-input font-weight-bold"></v-text-field>
                            </v-col>
                        </v-row>
                        <v-row dense class="mb-4">
                            <v-col cols="4">
                                <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Parcelas</label>
                                <v-select v-model="payableForm.installments" :items="[1,2,3,4,5,6,10,12]" variant="outlined" density="compact" hide-details class="clean-input"></v-select>
                            </v-col>
                            <v-col cols="8">
                                <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Categoria (Plano de Contas)</label>
                                <v-combobox v-model="payableForm.category" :items="['Matéria Prima', 'Serviços', 'Impostos', 'Material de Uso', 'Combustível', 'Manutenção']" variant="outlined" density="compact" hide-details class="clean-input"></v-combobox>
                            </v-col>
                        </v-row>
                        <div class="mb-2">
                            <label class="text-caption font-weight-bold text-uppercase text-grey-darken-1 mb-1 d-block">Observações</label>
                            <v-textarea v-model="payableForm.obs" rows="2" variant="outlined" density="compact" placeholder="Informações adicionais..." hide-details class="clean-input"></v-textarea>
                        </div>
                    </v-form>
                </div>
                <div class="pa-4 border-t d-flex justify-end gap-3 bg-grey-lighten-5">
                    <v-btn variant="text" color="grey-darken-2" class="text-none font-weight-bold" @click="payableModal.show = false">Cancelar</v-btn>
                    <v-btn color="success" variant="flat" class="text-none font-weight-bold px-6" :loading="payableModal.loading" @click="confirmPayableLaunch">
                        <v-icon start>mdi-check</v-icon> Confirmar Lançamento
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>

    <v-dialog v-model="syncStatus.show" persistent max-width="400">
       <v-card class="rounded-xl text-center pa-8 border-thin shadow-card">
          <div v-if="syncStatus.state === 'loading'">
             <v-progress-circular indeterminate color="primary" size="64" width="6" class="mb-6"></v-progress-circular>
             <h3 class="text-h6 font-weight-black text-grey-darken-3">Conectando à SEFAZ</h3>
             <p class="text-body-2 text-grey mt-2">Buscando documentos fiscais...</p>
          </div>
          <div v-else-if="syncStatus.state === 'blocked'">
             <div class="bg-orange-lighten-5 rounded-circle d-inline-flex pa-4 mb-4">
                <v-icon color="orange-darken-1" size="40">mdi-timer-sand</v-icon>
             </div>
             <h3 class="text-h6 font-weight-black text-grey-darken-3">Consulta em Pausa</h3>
             <p class="text-body-2 text-grey mt-2 px-4">A Receita Federal limita consultas consecutivas.</p>
             <div class="text-h3 font-weight-black text-orange-darken-2 mt-4 font-mono">{{ formatTime(syncStatus.nextTry) }}</div>
             <p class="text-caption text-grey mt-2 font-weight-bold">~ {{ syncStatus.minutesLeft }} minutos restantes.</p>
             <v-btn block color="grey-lighten-3" variant="flat" class="mt-8 text-none font-weight-bold" @click="syncStatus.show = false">Entendido</v-btn>
          </div>
          <div v-else-if="syncStatus.state === 'success'">
             <div class="bg-green-lighten-5 rounded-circle d-inline-flex pa-4 mb-4">
                <v-icon color="success-darken-1" size="40">mdi-check-decagram</v-icon>
             </div>
             <h3 class="text-h6 font-weight-black text-grey-darken-3">Concluído</h3>
             <p class="text-body-2 text-grey mt-2">{{ syncStatus.message }}</p>
             <v-btn block color="success" class="mt-6 text-none font-weight-bold shadow-success-soft" @click="syncStatus.show = false">Ver Notas</v-btn>
          </div>
          <div v-else-if="syncStatus.state === 'error'">
             <v-icon color="error" size="50" class="mb-4">mdi-alert-circle</v-icon>
             <h3 class="text-h6 font-weight-bold">Erro</h3>
             <p class="text-body-2 text-grey mt-2">{{ syncStatus.message }}</p>
             <v-btn block color="grey-lighten-3" class="mt-6 text-none font-weight-bold" @click="syncStatus.show = false">Fechar</v-btn>
          </div>
       </v-card>
    </v-dialog>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, reactive, computed, defineAsyncComponent } from 'vue';
import { sefazService } from '@/api/sefazApi';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { format, parseISO, isAfter, differenceInMinutes, addDays, addMonths } from 'date-fns';
import axios from 'axios';
// Importação do Danfe (Requer 'npm install danfe')

const CertificateUploadModal = defineAsyncComponent(() => import('@/components/admin/CertificateUploadModal.vue'));

const appStore = useAppStore();
const companies = ref<any[]>([]);
const activeCompany = ref<any>(null);
const notes = ref<any[]>([]);
const search = ref('');
const loadingCompanies = ref(false);
const loading = ref(false);
const syncing = ref(false);
const lastSyncTime = ref('--:--');
const processingManifest = ref<string | null>(null);
const pdfLoading = ref<string | null>(null);

const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const syncStatus = reactive({ show: false, state: 'idle', message: '', nextTry: '', minutesLeft: 0 });
const payableModal = reactive({ show: false, loading: false, note: null as any });
const payableForm = reactive({ description: '', value: 0, dueDate: '', obs: '', installments: 1, category: '' });
const certModal = reactive({ show: false });
const uploading = ref(false);
const xmlInput = ref<HTMLInputElement | null>(null);

const filteredNotes = computed(() => {
    if (!search.value) return notes.value;
    const term = search.value.toLowerCase();
    return notes.value.filter(n =>
        (n.emitente_nome && n.emitente_nome.toLowerCase().includes(term)) ||
        (n.chave && n.chave.includes(term)) ||
        (n.valor && n.valor.toString().includes(term))
    );
});

const totalValue = computed(() => notes.value.reduce((acc, note) => acc + (Number(note.valor) || 0), 0));

const loadCompanies = async () => {
   loadingCompanies.value = true;
   try {
      const data = await sefazService.listarEmpresas();
      companies.value = data;
      if (data.length > 0 && !activeCompany.value) {
          activeCompany.value = data[0];
          fetchStoredNotes(data[0].cnpj);
      }
   } catch (e) { console.error(e); } finally { loadingCompanies.value = false; }
};

const switchCompany = (company: any) => {
   activeCompany.value = company;
   fetchStoredNotes(company.cnpj);
};

const fetchStoredNotes = async (cnpj: string) => {
    loading.value = true;
    try {
        const { data, error } = await supabase
            .from('dfe_entries')
            .select('*')
            .eq('cnpj_destinatario', cnpj)
            .order('data_emissao', { ascending: false });

        if (error) throw error;
        notes.value = (data || []).map(n => ({ ...n, xml_id: n.xml_link }));
    } catch (e) { console.error('Erro ao carregar notas:', e); }
    finally { loading.value = false; }
};

const syncNotesFromSefaz = async () => {
   if (!activeCompany.value) return appStore.showSnackbar('Selecione uma empresa', 'warning');
   const cnpj = activeCompany.value.cnpj;
   const storageKey = `sefaz_block_${cnpj}`;

   const savedBlock = localStorage.getItem(storageKey);
   if (savedBlock && isAfter(new Date(savedBlock), new Date())) {
       syncStatus.state = 'blocked';
       syncStatus.nextTry = savedBlock;
       syncStatus.minutesLeft = differenceInMinutes(new Date(savedBlock), new Date());
       syncStatus.show = true;
       await fetchLatestFromApi(cnpj);
       return;
   }

   syncStatus.show = true; syncStatus.state = 'loading'; syncing.value = true;

   try {
      let isBlocked = false;
      try {
          const syncRes = await sefazService.sincronizarDfe(cnpj);
          if (syncRes.status === 'blocked') {
              isBlocked = true;
              const next = syncRes.next_attempt || new Date(Date.now()+3600000).toISOString();
              localStorage.setItem(storageKey, next);
              syncStatus.nextTry = next;
              syncStatus.minutesLeft = syncRes.wait_minutes || 60;
              syncStatus.state = 'blocked';
          }
      } catch (errSync) { console.warn('Sync falhou, seguindo para consulta', errSync); }

      if (!isBlocked) await new Promise(r => setTimeout(r, 2000));

      const count = await fetchLatestFromApi(cnpj);
      lastSyncTime.value = format(new Date(), 'HH:mm');

      if (isBlocked && count > 0) {
          syncStatus.state = 'success';
          syncStatus.message = `Sync em espera, mas ${count} notas recuperadas!`;
      } else if (!isBlocked) {
          syncStatus.state = 'success';
          syncStatus.message = `${count} notas atualizadas.`;
          setTimeout(() => syncStatus.show = false, 2000);
      }
   } catch (e: any) {
      syncStatus.state = 'error';
      syncStatus.message = 'Falha na comunicação.';
   } finally { syncing.value = false; }
};

const fetchLatestFromApi = async (cnpj: string) => {
    try {
        const apiNotes = await sefazService.consultarNotas(cnpj);

        if (apiNotes?.length > 0) {
            console.log('Notas recebidas (bruto):', apiNotes.length);
            const uniqueNotes = Array.from(new Map(apiNotes.map((item: any) => [item.chave, item])).values());
            console.log(`Notas únicas para salvar: ${uniqueNotes.length}`);

            const upsertData = uniqueNotes.map((n: any) => ({
                chave: n.chave,
                cnpj_destinatario: cnpj,
                emitente_nome: n.emitente || 'Desconhecido',
                emitente_cnpj: n.cnpj_emitente,
                valor: Number(n.valor) || 0,
                data_emissao: n.emissao,
                situacao_sefaz: n.situacao_sefaz,
                situacao_manifestacao: n.situacao_manifestacao,
                xml_link: n.xml_link,
                updated_at: new Date().toISOString()
            }));

            const { error } = await supabase.from('dfe_entries').upsert(upsertData, { onConflict: 'chave' });
            if (error) throw error;

            await fetchStoredNotes(cnpj);
            return uniqueNotes.length;
        }
        return 0;
    } catch (e: any) {
        console.error('Exceção no fetchLatestFromApi:', e);
        return 0;
    }
};

const manifestNote = async (note: any, tipo: 'ciencia' | 'confirmacao') => {
    // Confirmação do usuário
    const acao = tipo === 'confirmacao' ? 'Confirmar recebimento' : 'Dar ciência';
    if (!confirm(`${acao} da nota final ${note.chave.substring(40)}?`)) return;

    if (!activeCompany.value?.cnpj) {
        appStore.showSnackbar('Erro: Nenhuma empresa selecionada.', 'error');
        return;
    }

    // Trava a UI para esta nota específica
    processingManifest.value = note.chave; // Usar a chave é mais seguro que ID se ID for nulo

    try {
        // 1. Chama a API (agora usando o service)
        await sefazService.manifestarNota(note.chave, activeCompany.value.cnpj, tipo);

        // 2. Atualiza o objeto LOCALMENTE para feedback instantâneo
        const novoStatus = tipo === 'confirmacao' ? 'Confirmada' : 'Ciencia';
        note.situacao_manifestacao = novoStatus;

        // 3. Atualiza o Supabase (Banco Local) sem depender de retorno da SEFAZ
        // Isso garante que a nota vá para "Base Local" imediatamente
        await supabase.from('dfe_entries')
            .update({
                situacao_manifestacao: novoStatus,
                updated_at: new Date().toISOString()
            })
            .eq('chave', note.chave);

        appStore.showSnackbar(`Sucesso! ${novoStatus} registrada. O XML será baixado na próxima sincronização.`, 'success');

    } catch (e: any) {
        console.error('Erro Manifestação:', e);
        appStore.showSnackbar('Erro ao manifestar: ' + e.message, 'error');
    } finally {
        processingManifest.value = null;
    }
};

const isManifested = (note: any) => {
    return note.situacao_manifestacao === 'Confirmada' || note.situacao_manifestacao === 'Ciencia';
};

const getManifestLabel = (note: any) => {
    if (note.situacao_manifestacao === 'Confirmada') return 'Confirmada';
    if (note.situacao_manifestacao === 'Ciencia') return 'Ciência';
    return 'Pendente';
};

const getManifestColor = (note: any) => {
    if (note.situacao_manifestacao === 'Confirmada') return 'success';
    if (note.situacao_manifestacao === 'Ciencia') return 'info';
    return 'warning';
};

const openCertModal = () => certModal.show = true;

const handleCertUpload = async (payload: any) => {
  uploading.value = true;
  try {
    await sefazService.uploadCertificado(payload.cnpj, payload.file, payload.password);
    appStore.showSnackbar('Certificado instalado com sucesso!', 'success');
    certModal.show = false;
    await loadCompanies();
  } catch (e: any) {
    appStore.showSnackbar(e.toString(), 'error');
  } finally {
    uploading.value = false;
  }
};

const triggerXmlInput = () => xmlInput.value?.click();

const handleXmlUpload = async (event: any) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    let processed = 0;
    loading.value = true;

    for (const file of files) {
        try {
            const text = await file.text();
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(text, "text/xml");

            const chave = xmlDoc.getElementsByTagName('chNFe')[0]?.textContent || '';
            const emitNome = xmlDoc.getElementsByTagName('xNome')[0]?.textContent || 'XML Importado';
            const emitCnpj = xmlDoc.getElementsByTagName('CNPJ')[0]?.textContent || '';
            const val = xmlDoc.getElementsByTagName('vNF')[0]?.textContent || '0';
            const dataEmissao = xmlDoc.getElementsByTagName('dhEmi')[0]?.textContent || new Date().toISOString();

            if (chave) {
                await supabase.from('dfe_entries').upsert({
                    chave,
                    cnpj_destinatario: activeCompany.value?.cnpj || 'manual_import',
                    emitente_nome: emitNome,
                    emitente_cnpj: emitCnpj,
                    valor: parseFloat(val),
                    data_emissao: dataEmissao,
                    situacao_sefaz: 'Importada',
                    situacao_manifestacao: 'Confirmada',
                    xml_link: null, // XML Importado Manualmente não tem link no storage
                    updated_at: new Date().toISOString()
                }, { onConflict: 'chave' });
                processed++;
            }
        } catch (err) { console.error('Erro ao ler XML', err); }
    }

    if (processed > 0) {
        appStore.showSnackbar(`${processed} notas importadas com sucesso!`, 'success');
        if (activeCompany.value) fetchStoredNotes(activeCompany.value.cnpj);
    } else {
        appStore.showSnackbar('Nenhuma nota válida encontrada nos arquivos.', 'warning');
    }
    loading.value = false;
    event.target.value = '';
};

// --- CONTAS A PAGAR ---
const openPayableModal = (note: any) => {
    payableModal.note = note;
    payableForm.description = note.emitente_nome;
    payableForm.value = note.valor;
    payableForm.installments = 1;
    payableForm.category = 'Compra de Mercadoria';
    payableForm.dueDate = format(addDays(parseISO(note.data_emissao || new Date().toISOString()), 30), 'yyyy-MM-dd');
    payableForm.obs = `Ref. NFe ${note.numero || note.chave.substring(25, 34)}`;
    payableModal.show = true;
};

const confirmPayableLaunch = async () => {
    payableModal.loading = true;
    try {
        const note = payableModal.note;
        const recurrenceId = crypto.randomUUID();
        const installmentValue = payableForm.value / payableForm.installments;
        const payloads = [];

        for (let i = 0; i < payableForm.installments; i++) {
            const dueDate = addMonths(parseISO(payableForm.dueDate), i);
            payloads.push({
                description: payableForm.description,
                value: installmentValue,
                due_date: format(dueDate, 'yyyy-MM-dd'),
                status: 'pendente',
                origin_nfe_key: note.chave,
                notes: payableForm.obs,
                installment_number: i + 1,
                total_installments: payableForm.installments,
                recurrence_id: recurrenceId,
                category: payableForm.category
            });
        }

        const { error: errFin } = await supabase.from('finance_payables').insert(payloads);
        if (errFin) throw errFin;

        await supabase.from('dfe_entries').update({ status_processamento: 'contas_a_pagar_gerado' }).eq('chave', note.chave);
        note.status_processamento = 'contas_a_pagar_gerado';
        appStore.showSnackbar(`${payableForm.installments} parcelas lançadas com sucesso!`, 'success');
        payableModal.show = false;

    } catch (e: any) {
        console.error(e);
        appStore.showSnackbar('Erro ao lançar financeiro: ' + e.message, 'error');
    } finally {
        payableModal.loading = false;
    }
};

const downloadXml = (note: any) => {
    if (note.xml_link || note.xml_id) {
        const id = note.xml_link || note.xml_id;
        const url = id.includes('http') ? id : `${SEFAZ_PROXY_URL}/api/baixar-xml/${id}`;
        window.open(url, '_blank');
    } else { appStore.showSnackbar('XML indisponível.', 'warning'); }
};

// === NOVA FUNÇÃO DE GERAÇÃO DE PDF/DANFE ===
const openDanfe = async (note: any) => {
    pdfLoading.value = note.chave;
    try {
        let xmlContent = '';

        // 1. Tentar pegar o XML do Storage ou do Link (mesma lógica anterior)
        if (note.xml_link && note.xml_link.startsWith('http')) {
             const { data } = await axios.get(note.xml_link, { responseType: 'text' });
             xmlContent = data;
        } else if (note.xml_id || note.xml_link) {
             const id = note.xml_id || note.xml_link;
             const { data } = await axios.get(`${SEFAZ_PROXY_URL}/api/baixar-xml/${id}`, { responseType: 'text' });
             xmlContent = data;
        } else if (note.chave) {
             const { data } = await axios.get(`${SEFAZ_PROXY_URL}/api/baixar-xml/${note.chave}`, { responseType: 'text' });
             xmlContent = data;
        }

        if (!xmlContent || !xmlContent.includes('infNFe')) {
            throw new Error('Conteúdo XML inválido ou indisponível.');
        }

        // 2. Gerar DANFE (HTML) usando danfe-simplificada
        const danfe = Danfe.fromXML(xmlContent);

        // Gera o HTML com o layout da nota
        const htmlContent = danfe.toHtml();

        // Abre uma nova janela/aba com o DANFE renderizado
        const win = window.open('', '_blank');
        if (win) {
            win.document.write(htmlContent);
            win.document.close();
            // Opcional: Chama a impressão automaticamente
            // win.print();
        } else {
            throw new Error('O navegador bloqueou a abertura da janela (Pop-up).');
        }

    } catch (e: any) {
        console.error('Erro ao gerar DANFE:', e);
        appStore.showSnackbar('Erro ao visualizar nota: ' + (e.message || 'XML inacessível'), 'error');
    } finally {
        pdfLoading.value = null;
    }
};

const deleteNote = async (note: any) => {
    if(!confirm('Remover da lista?')) return;
    await supabase.from('dfe_entries').delete().eq('chave', note.chave);
    notes.value = notes.value.filter(n => n.chave !== note.chave);
};

// Utils
const formatCurrency = (val: any) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatCompact = (val: any) => new Intl.NumberFormat('pt-BR', { notation: "compact", compactDisplay: "short", style: 'currency', currency: 'BRL' }).format(Number(val)||0);
const formatDate = (d: string) => d ? format(parseISO(d), 'dd/MM/yy') : '-';
const formatTime = (iso: string) => iso ? format(parseISO(iso), 'HH:mm') : '--:--';
const formatKey = (k: string) => k ? `${k.substring(0,4)}...${k.substring(k.length-4)}` : '';
const getStatusColor = (s: string) => s?.toLowerCase().includes('autorizada') ? 'success' : 'warning';
const getIconBoxClass = (n: any) => n.situacao_sefaz?.toLowerCase().includes('cancelada') ? 'bg-red-lighten-5' : 'bg-green-lighten-5';
const getIconColor = (n: any) => n.situacao_sefaz?.toLowerCase().includes('cancelada') ? 'red-darken-1' : 'green-darken-1';

onMounted(() => { loadCompanies(); });
</script>

<style scoped lang="scss">
:global(.tooltip-custom) {
  background-color: #1a1a1a !important; color: #ffffff !important;
  font-weight: bold !important; font-size: 11px !important;
  border: 1px solid #333 !important; z-index: 9999;
}
:global(.custom-tooltip-white) {
  background-color: #ffffff !important;
  color: #424242 !important;
  font-weight: bold !important;
  font-size: 11px !important;
  border: 1px solid #e0e0e0 !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
  z-index: 9999;
}
.bg-background-light { background-color: #F5F7FA; }
.border-thin { border-width: 1px !important; border-style: solid; border-color: rgba(0,0,0,0.08) !important; }
.divide-md-x > div:not(:last-child) { border-right: 1px solid rgba(0,0,0,0.06); }
.lh-1 { line-height: 1; }
.lh-1-2 { line-height: 1.2; }
.break-all { word-break: break-all; }
.gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; } .gap-6 { gap: 24px; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; &.pulsing { animation: pulse 2s infinite; } }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.5; } 100% { opacity: 1; } }
.note-row {
    border-color: transparent !important;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    &:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 24px -8px rgba(0,0,0,0.08) !important;
        border-color: rgba(var(--v-theme-primary), 0.2) !important;
        .icon-box { background-color: rgb(var(--v-theme-primary)); i { color: white !important; } }
    }
}
.icon-circle { width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.absolute-bg-icon { position: absolute; right: -20px; bottom: -30px; opacity: 0.05; pointer-events: none; }
.clean-input :deep(.v-field) {
    border-radius: 8px; border-color: #E0E0E0;
    transition: all 0.2s ease;
    &.v-field--focused { border-color: rgb(var(--v-theme-primary)); box-shadow: 0 0 0 3px rgba(var(--v-theme-primary), 0.1); }
}
.search-input :deep(.v-field) { border-radius: 8px; border: 1px solid #E0E0E0; box-shadow: none; }
.shadow-primary-soft { box-shadow: 0 4px 12px rgba(var(--v-theme-primary), 0.3); }
.shadow-success-soft { box-shadow: 0 4px 12px rgba(var(--v-theme-success), 0.3); }
.shadow-card { box-shadow: 0 10px 30px -10px rgba(0,0,0,0.08) !important; }
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #d1d5db; border-radius: 3px; }
.action-btn {
    width: 32px; height: 32px; border-radius: 6px;
    display: flex; align-items: center; justify-content: center;
    border: 1px solid rgba(128,128,128,0.2); cursor: pointer;
    transition: all 0.2s ease;
}
.action-btn:hover { transform: translateY(-2px); }
.action-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }
.info-btn { background: rgba(33, 150, 243, 0.1); color: #2196F3; }
.info-btn:hover:not(:disabled) { background: #2196F3; color: white; }
.success-btn { background: rgba(76, 175, 80, 0.1); color: #4CAF50; }
.success-btn:hover:not(:disabled) { background: #4CAF50; color: white; }
.warning-btn { background: rgba(255, 152, 0, 0.1); color: #FF9800; }
.warning-btn:hover:not(:disabled) { background: #FF9800; color: white; }
.primary-btn { background: rgba(103, 58, 183, 0.1); color: #673AB7; }
.primary-btn:hover:not(:disabled) { background: #673AB7; color: white; }
.error-btn { background: rgba(244, 67, 54, 0.1); color: #F44336; }
.error-btn:hover:not(:disabled) { background: #F44336; color: white; }
.bg-primary-transparent { background-color: rgba(var(--v-theme-primary), 0.1); }
</style>
