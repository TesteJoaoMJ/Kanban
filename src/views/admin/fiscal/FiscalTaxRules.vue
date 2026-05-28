<template>
  <div
    class="receivables-layout font-sans fill-height d-flex flex-column relative overflow-hidden"
    :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5 text-grey-darken-4' : 'bg-glass-dark text-white'"
  >
    <div v-if="themeStore.currentMode !== 'light'" class="background-carousel-wrapper">
      <v-carousel cycle height="100%" hide-delimiters :show-arrows="false" interval="15000" class="fill-height">
        <v-carousel-item src="@/assets/1.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/2.jpg" cover></v-carousel-item>
        <v-carousel-item src="@/assets/3.jpg" cover></v-carousel-item>
      </v-carousel>
      <div class="background-overlay"></div>
    </div>

    <div class="content-wrapper d-flex flex-column fill-height z-10 relative">
      <div
        class="header-bar px-4 py-3 px-md-6 py-md-4 d-flex flex-column flex-md-row align-md-center justify-space-between flex-shrink-0"
        :class="themeStore.currentMode === 'light' ? 'bg-white border-b border-grey-lighten-2 shadow-sm' : 'bg-glass-header border-bottom-white-05'"
        style="gap: 12px;"
      >
        <div class="d-flex flex-column">
          <div class="breadcrumb text-caption d-none d-md-block">
            <span class="opacity-70">Fiscal</span>
            <span class="mx-2 opacity-50">></span>
            <span class="opacity-70">Configurações</span>
            <span class="mx-2 opacity-50">></span>
            <span class="font-weight-bold">Regras Tributárias (UF)</span>
          </div>
          <div class="d-flex align-center gap-2 mt-1">
             <div class="text-h6 font-weight-black tracking-tight leading-none" :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'">
                Regras Tributárias por Estado
             </div>
             <v-chip size="x-small" :color="companyStore.isGlobalView ? 'purple' : 'success'" class="font-weight-bold ml-2">
                {{ companyStore.isGlobalView ? 'HOLDING' : companyStore.currentCompanyName.toUpperCase() }}
             </v-chip>
          </div>
        </div>

        <div class="d-flex align-center overflow-x-auto pb-1 pb-md-0" style="gap: 10px;">
          <v-btn
            color="success"
            variant="flat"
            class="btn-3d px-3 px-md-4 font-weight-bold text-caption text-uppercase letter-spacing-1 flex-shrink-0 shadow-button"
            prepend-icon="mdi-plus"
            height="40"
            @click="openModal()"
          >
             Nova Regra
          </v-btn>
        </div>
      </div>

      <div class="px-4 px-md-6 pt-3 pb-2 flex-shrink-0">
        <div class="controls-bar d-flex flex-column flex-md-row align-center justify-space-between" :class="themeStore.currentMode === 'light' ? 'controls-light' : 'controls-dark bg-glass-dark border-white-10'" style="gap: 10px; border-radius: 8px;">
          <div class="d-flex align-center gap-2">
            <div class="text-caption font-weight-bold opacity-70 text-uppercase d-none d-md-block pl-2">
              <v-icon start size="small">mdi-scale-balance</v-icon> Gerenciamento de Alíquotas
            </div>
          </div>
          <div class="search-wrap d-flex align-center flex-grow-1 flex-md-grow-0" :class="themeStore.currentMode === 'light' ? 'search-light bg-white border rounded' : 'search-dark bg-black-20 border-white-10 rounded'">
            <v-icon :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white-70'" class="ml-2">mdi-magnify</v-icon>
            <input
              v-model="search"
              type="text"
              placeholder="Pesquisar por UF, CFOP ou CST..."
              class="clean-input flex-grow-1 font-weight-bold pa-2"
              :class="themeStore.currentMode === 'light' ? 'text-grey-darken-4' : 'text-white'"
            />
          </div>
        </div>
      </div>

      <div class="flex-grow-1 overflow-hidden d-flex flex-column transition-all px-4 px-md-6 pb-6">
        <v-card
          class="flex-grow-1 d-flex flex-column rounded-lg border-thin overflow-hidden"
          :class="themeStore.currentMode === 'light' ? 'bg-white shadow-sm' : 'glass-card border-white-05'"
          :elevation="0"
        >
          <div class="grid-scroll flex-grow-1 overflow-auto custom-scroll relative">
            <div
              class="grid-header sticky-head"
              :class="[themeStore.currentMode === 'light' ? 'grid-surface-light' : 'grid-surface-dark']"
              style="grid-template-columns: 80px 100px 100px 1fr 1fr 1fr 120px;"
            >
              <div class="cell center header-text">UF</div>
              <div class="cell center header-text">CFOP</div>
              <div class="cell center header-text">CST/CSOSN</div>
              <div class="cell center header-text">ICMS (%)</div>
              <div class="cell center header-text">Red. Base (%)</div>
              <div class="cell center header-text">PIS/COFINS (%)</div>
              <div class="cell center header-text">Ações</div>
            </div>

            <div v-if="loading" class="d-flex flex-column justify-center align-center h-100 py-10 min-w-full">
              <v-progress-circular indeterminate color="success" size="32" width="3"></v-progress-circular>
            </div>

            <div v-else-if="filteredRules.length === 0" class="d-flex flex-column justify-center align-center h-100 opacity-60 gap-2 py-10 min-w-full">
              <v-icon size="48" color="grey-lighten-1">mdi-map-marker-off-outline</v-icon>
              <span class="text-body-2 font-weight-medium text-grey">Nenhuma regra tributária encontrada.</span>
            </div>

            <div
              v-else
              v-for="(rule, index) in filteredRules"
              :key="rule.id"
              class="grid-row"
              :class="[themeStore.currentMode === 'light' ? 'grid-row-light' : 'grid-row-dark', zebraClass(index)]"
              style="grid-template-columns: 80px 100px 100px 1fr 1fr 1fr 120px;"
            >
                <div class="cell center"><v-chip size="small" color="primary" class="font-weight-black chip-3d">{{ rule.uf }}</v-chip></div>
                <div class="cell center"><span class="font-weight-black font-mono list-text-11">{{ rule.cfop }}</span></div>
                <div class="cell center"><span class="font-weight-bold list-text-11 opacity-90">{{ rule.cst_csosn }}</span></div>
                <div class="cell center"><span class="font-weight-bold list-text-11 text-teal-darken-2">{{ rule.icms_aliquot }}%</span></div>
                <div class="cell center"><span class="font-weight-bold list-text-11 text-orange-darken-3">{{ rule.icms_base_reduction }}%</span></div>
                <div class="cell center"><span class="font-weight-bold list-text-11 text-blue-darken-2">{{ rule.pis_aliquot }}% / {{ rule.cofins_aliquot }}%</span></div>

                <div class="cell center">
                    <div class="actions-inline">
                        <v-btn icon size="x-small" class="action-btn action-edit btn-3d" @click="openModal(rule)" title="Editar" variant="flat"><v-icon size="16">mdi-pencil</v-icon></v-btn>
                        <v-btn icon size="x-small" class="action-btn bg-teal-darken-2 btn-3d" @click="cloneRule(rule)" title="Clonar para outro Estado" variant="flat"><v-icon size="16">mdi-content-copy</v-icon></v-btn>
                        <v-btn icon size="x-small" class="action-btn action-del btn-3d" @click="deleteRule(rule.id)" title="Excluir" variant="flat"><v-icon size="16">mdi-trash-can-outline</v-icon></v-btn>
                    </div>
                </div>
            </div>
          </div>

          <div class="flex-shrink-0 border-t px-4 py-3 z-20" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-surface-variant border-top-white-05'">
             <div class="text-caption font-weight-bold opacity-70">Total de Regras: {{ filteredRules.length }}</div>
          </div>
        </v-card>
      </div>
    </div>

    <v-dialog
        v-model="modal.show"
        :width="mobile ? '100%' : '1000'"
        :fullscreen="mobile"
        persistent
        scrim="black opacity-80"
        transition="dialog-bottom-transition"
        class="fixed-dialog"
    >
        <v-card class="d-flex overflow-hidden rounded-0 fill-height" :class="mobile ? 'flex-column' : 'flex-row'" height="100%">
            <div class="modal-sidebar pa-6 d-flex flex-column text-white" :class="[themeStore.currentMode === 'light' ? 'bg-primary' : 'bg-grey-darken-4', mobile ? 'd-none' : '']" style="width: 280px; flex-shrink: 0; border-right: 1px solid rgba(255,255,255,0.1);">
                 <div class="d-flex align-center" style="gap: 12px;">
                    <div class="bg-white-20 p-3 rounded-0 d-flex align-center justify-center" style="width: 48px; height: 48px;">
                        <v-icon size="32" color="white">mdi-scale-balance</v-icon>
                    </div>
                    <div>
                        <h3 class="text-h6 font-weight-black leading-tight">{{ modal.form.id ? 'Editar' : 'Nova' }} Regra</h3>
                        <div class="text-caption opacity-80">Tributação Inteligente</div>
                    </div>
                </div>
                <div class="mt-6 bg-white-10 pa-4 rounded-lg border-white-10 text-caption font-weight-medium opacity-90">
                    O sistema cruza a <strong>UF de Origem</strong> com as <strong>UFs de Destino</strong> que você selecionar e preenche o ICMS e ajusta o CFOP de forma automática seguindo as diretrizes de tributação.
                </div>
                <v-spacer></v-spacer>
            </div>

            <div class="flex-grow-1 d-flex flex-column h-100 overflow-hidden relative" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4 text-white'">
                 <div class="pa-0 border-b flex-shrink-0 d-flex justify-space-between align-center px-4 pt-3 pb-3" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'">
                    <div class="font-weight-black text-uppercase text-caption opacity-70">
                        <v-icon start size="small">mdi-file-document-outline</v-icon> Dados da Regra Tributária
                    </div>
                    <v-btn icon="mdi-close" variant="text" :color="themeStore.currentMode === 'light' ? 'grey-darken-1' : 'white'" @click="modal.show = false"></v-btn>
                </div>

                <div class="flex-grow-1 overflow-y-auto custom-scroll pa-4 pa-md-6 absolute-fill" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'bg-grey-darken-4'">
                    <v-form @submit.prevent="saveRule" id="taxRuleForm">
                        <v-row class="row-gap">
                            <v-col cols="12">
                                <div class="text-subtitle-2 font-weight-black mb-2 text-primary">Matriz Interestadual</div>
                            </v-col>
                            <v-col cols="12" md="3">
                                <v-autocomplete
                                    label="Origem (Sua UF)"
                                    v-model="modal.origin_uf"
                                    :items="brazilUFs"
                                    variant="outlined"
                                    color="primary"
                                    density="comfortable"
                                    class="ui-field font-weight-bold"
                                    hint="Base para o cálculo"
                                    persistent-hint
                                ></v-autocomplete>
                            </v-col>
                            <v-col cols="12" md="4">
                                <v-autocomplete
                                    label="Estados Destino (UFs)*"
                                    v-model="modal.form.ufs"
                                    :items="brazilUFs"
                                    multiple
                                    chips
                                    closable-chips
                                    variant="outlined"
                                    color="primary"
                                    density="comfortable"
                                    class="ui-field font-weight-bold"
                                    :disabled="!!modal.form.id"
                                    hint="Pode selecionar vários"
                                    persistent-hint
                                ></v-autocomplete>
                            </v-col>
                            <v-col cols="12" md="5">
                                <v-autocomplete
                                    label="Empresa Vinculada*"
                                    v-model="modal.form.company_id"
                                    :items="companies"
                                    item-title="trade_name"
                                    item-value="id"
                                    variant="outlined"
                                    color="primary"
                                    density="comfortable"
                                    class="ui-field"
                                    :disabled="!companyStore.isGlobalView"
                                ></v-autocomplete>
                            </v-col>

                            <v-divider class="my-4 border-white-10 w-100"></v-divider>

                            <v-col cols="12">
                                <div class="text-subtitle-2 font-weight-black mb-2 text-primary">Códigos e Alíquotas Padrão</div>
                            </v-col>
                            <v-col cols="12" md="6"><v-text-field label="CFOP Padrão*" v-model="modal.form.cfop" variant="outlined" color="primary" density="comfortable" class="ui-field font-mono font-weight-bold" placeholder="Ex: 5101"></v-text-field></v-col>
                            <v-col cols="12" md="6"><v-text-field label="CST / CSOSN*" v-model="modal.form.cst_csosn" variant="outlined" color="primary" density="comfortable" class="ui-field font-mono font-weight-bold" placeholder="Ex: 0102"></v-text-field></v-col>

                            <v-col cols="12" md="6"><v-text-field label="Alíquota ICMS (%)" v-model.number="modal.form.icms_aliquot" type="number" step="0.01" variant="outlined" color="teal" density="comfortable" class="ui-field font-weight-bold"></v-text-field></v-col>
                            <v-col cols="12" md="6"><v-text-field label="Redução Base ICMS (%)" v-model.number="modal.form.icms_base_reduction" type="number" step="0.01" variant="outlined" color="orange" density="comfortable" class="ui-field"></v-text-field></v-col>

                            <v-col cols="12" md="4"><v-text-field label="Alíquota PIS (%)" v-model.number="modal.form.pis_aliquot" type="number" step="0.01" variant="outlined" color="primary" density="comfortable" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-text-field label="Alíquota COFINS (%)" v-model.number="modal.form.cofins_aliquot" type="number" step="0.01" variant="outlined" color="primary" density="comfortable" class="ui-field"></v-text-field></v-col>
                            <v-col cols="12" md="4"><v-text-field label="Alíquota IPI (%)" v-model.number="modal.form.ipi_aliquot" type="number" step="0.01" variant="outlined" color="primary" density="comfortable" class="ui-field"></v-text-field></v-col>
                        </v-row>
                    </v-form>
                </div>

                <div class="pa-4 border-t d-flex justify-end align-center flex-shrink-0" :class="themeStore.currentMode === 'light' ? 'bg-grey-lighten-5' : 'bg-grey-darken-3'" style="gap: 12px; height: 80px;">
                    <v-btn variant="outlined" class="btn-3d px-8 font-weight-bold text-body-2" height="48" @click="modal.show = false" :disabled="modal.loading">Cancelar</v-btn>
                    <v-btn color="primary" variant="flat" class="btn-3d px-8 font-weight-black text-body-1" height="48" type="submit" form="taxRuleForm" :loading="modal.loading">
                        <v-icon start>mdi-content-save-check</v-icon> Salvar Regra
                    </v-btn>
                </div>
            </div>
        </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCompanyStore } from '@/stores/company';
import { useDisplay } from 'vuetify';

const { mobile } = useDisplay();
const appStore = useAppStore();
const themeStore = useThemeStore();
const companyStore = useCompanyStore();
const userStore = useUserStore();

const loading = ref(false);
const allRules = ref<any[]>([]);
const search = ref('');
const companies = ref<any[]>([]);

const brazilUFs = ['AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO', 'EX'];

const modal = reactive({
    show: false,
    loading: false,
    origin_uf: 'SP', // UF PADRÃO DA SUA EMPRESA (PODE SER ALTERADO NA TELA)
    form: {
        id: null as string | null,
        company_id: null as string | null,
        ufs: [] as string[],
        cfop: '',
        cst_csosn: '',
        icms_aliquot: 0,
        icms_base_reduction: 0,
        pis_aliquot: 0,
        cofins_aliquot: 0,
        ipi_aliquot: 0
    }
});

// --- INTELIGÊNCIA FISCAL (MATRIZ ICMS AUTOMÁTICA) ---
const getTaxRules = (origin: string, dest: string) => {
    // Alíquotas Internas (Origem == Destino)
    const internalAliquots: Record<string, number> = {
        AC: 19, AL: 20.5, AM: 20, AP: 18, BA: 20.5, CE: 20, DF: 20, ES: 17,
        GO: 19, MA: 23, MG: 18, MS: 17, MT: 17, PA: 19, PB: 20, PE: 20.5,
        PI: 22.5, PR: 19.5, RJ: 20, RN: 20, RO: 19.5, RR: 20, RS: 17,
        SC: 17, SE: 19, SP: 18, TO: 20
    };

    if (dest === 'EX') {
        return { icms: 0, cfopPrefix: '7' }; // Exportação
    }

    let icms = 0;
    let cfopPrefix = '6'; // Interestadual (padrão)

    if (origin === dest) {
        icms = internalAliquots[origin] || 0;
        cfopPrefix = '5'; // Interno
    } else {
        const sulSudeste = ['PR', 'RJ', 'RS', 'SC', 'SP', 'MG'];
        const originIsSulSudeste = sulSudeste.includes(origin);
        const destIsSulSudeste = sulSudeste.includes(dest);

        // Regra geral de Partilha / Interestadual:
        // Origem S/SE para destino N/NE/CO/ES = 7%
        // Demais situações = 12%
        if (originIsSulSudeste && !destIsSulSudeste) {
            icms = 7;
        } else {
            icms = 12;
        }
    }
    return { icms, cfopPrefix };
};

// WATCHER: Assiste sempre que a UF de destino ou origem mudar para preencher automático
watch([() => modal.form.ufs, () => modal.origin_uf], ([newUfs, origin]) => {
    if (!newUfs || newUfs.length === 0 || !origin) return;

    // Calcula baseado no primeiro estado selecionado
    const firstRule = getTaxRules(origin, newUfs[0]);
    let allSameIcms = true;
    let allSameCfop = true;

    // Checa se os estados agrupados compartilham a mesma alíquota
    for (let i = 1; i < newUfs.length; i++) {
        const rule = getTaxRules(origin, newUfs[i]);
        if (rule.icms !== firstRule.icms) allSameIcms = false;
        if (rule.cfopPrefix !== firstRule.cfopPrefix) allSameCfop = false;
    }

    if (allSameIcms) {
        modal.form.icms_aliquot = firstRule.icms;
    } else {
        appStore.showSnackbar('Atenção: Você selecionou estados que possuem alíquotas de ICMS diferentes!', 'warning');
    }

    if (allSameCfop) {
        if (!modal.form.cfop) {
            modal.form.cfop = firstRule.cfopPrefix + '102'; // Sugere CFOP padrão (revenda)
        } else if (modal.form.cfop.length === 4) {
            // Se já tem CFOP, só substitui o primeiro dígito para não perder o sufixo (ex: troca 5101 pra 6101)
            modal.form.cfop = firstRule.cfopPrefix + modal.form.cfop.substring(1);
        }
    }
});
// ----------------------------------------------------

const filteredRules = computed(() => {
    let result = allRules.value;
    if (search.value) {
        const term = search.value.toLowerCase();
        result = result.filter(r =>
            r.uf.toLowerCase().includes(term) ||
            r.cfop.toLowerCase().includes(term) ||
            r.cst_csosn.toLowerCase().includes(term)
        );
    }
    return result;
});

const fetchCompanies = async () => {
    const { data } = await supabase.from('companies').select('id, trade_name');
    if (data) companies.value = data;
};

const fetchRules = async () => {
    loading.value = true;
    try {
        let query = supabase.from('fiscal_tax_rules').select('*').order('uf', { ascending: true });
        if (!companyStore.isGlobalView && companyStore.context) {
            query = query.eq('company_id', companyStore.context);
        }
        const { data, error } = await query;
        if (error) throw error;
        allRules.value = data || [];
    } catch (e: any) {
        appStore.showSnackbar('Erro ao carregar regras: ' + e.message, 'error');
    } finally {
        loading.value = false;
    }
};

const openModal = (rule: any = null) => {
    if (rule) {
        Object.assign(modal.form, rule);
        modal.form.ufs = [rule.uf];
    } else {
        modal.form = {
            id: null,
            company_id: !companyStore.isGlobalView ? companyStore.context : null,
            ufs: [],
            cfop: '',
            cst_csosn: '',
            icms_aliquot: 0,
            icms_base_reduction: 0,
            pis_aliquot: 0,
            cofins_aliquot: 0,
            ipi_aliquot: 0
        };
    }
    modal.show = true;
};

const cloneRule = (rule: any) => {
    openModal(rule);
    modal.form.id = null;
    modal.form.ufs = [];
    appStore.showSnackbar('Regra copiada! Selecione os novos estados (UFs) e salve.', 'info');
};

const saveRule = async () => {
    if (modal.form.ufs.length === 0 || !modal.form.cfop || !modal.form.cst_csosn || !modal.form.company_id) {
        appStore.showSnackbar('Preencha os campos obrigatórios (UFs, Empresa, CFOP e CST).', 'warning');
        return;
    }

    modal.loading = true;
    try {
        const basePayload = {
            company_id: modal.form.company_id,
            cfop: modal.form.cfop,
            cst_csosn: modal.form.cst_csosn,
            icms_aliquot: modal.form.icms_aliquot,
            icms_base_reduction: modal.form.icms_base_reduction,
            pis_aliquot: modal.form.pis_aliquot,
            cofins_aliquot: modal.form.cofins_aliquot,
            ipi_aliquot: modal.form.ipi_aliquot
        };

        if (modal.form.id) {
            const payload = { ...basePayload, uf: modal.form.ufs[0] };
            const { error } = await supabase.from('fiscal_tax_rules').update(payload).eq('id', modal.form.id);
            if (error) throw error;
            appStore.showSnackbar('Regra atualizada com sucesso!', 'success');
        } else {
            const payloads = modal.form.ufs.map(uf => ({ ...basePayload, uf }));
            const { error } = await supabase.from('fiscal_tax_rules').insert(payloads);
            if (error) {
                if (error.code === '23505') throw new Error('Conflito: Um dos estados selecionados já possui regra cadastrada nesta empresa.');
                throw error;
            }
            appStore.showSnackbar(`${payloads.length} regra(s) cadastrada(s)!`, 'success');
        }

        modal.show = false;
        fetchRules();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao salvar: ' + e.message, 'error');
    } finally {
        modal.loading = false;
    }
};

const deleteRule = async (id: string) => {
    if (!confirm('Tem certeza que deseja excluir esta regra tributária?')) return;
    try {
        const { error } = await supabase.from('fiscal_tax_rules').delete().eq('id', id);
        if (error) throw error;
        appStore.showSnackbar('Regra excluída.', 'success');
        fetchRules();
    } catch (e: any) {
        appStore.showSnackbar('Erro ao excluir: ' + e.message, 'error');
    }
};

const zebraClass = (i: number) => themeStore.currentMode !== 'light' ? (i % 2 === 0 ? 'zebra-dark-a' : 'zebra-dark-b') : (i % 2 === 0 ? 'zebra-light-a' : 'zebra-light-b');

watch(() => companyStore.context, () => { fetchRules(); });

onMounted(() => {
    fetchCompanies();
    fetchRules();
});
</script>

<style scoped lang="scss">
/* Mantenha todo o seu CSS original intocado aqui. Removi da exibição apenas para encurtar a mensagem,
   mas você não precisa alterar nenhuma linha do seu bloco <style> */
.receivables-layout { position: relative; }
.bg-glass-dark { background: rgba(10,10,12,0.85); }
.bg-glass-header { background: rgba(20,20,24,0.55); backdrop-filter: blur(14px); }
.border-bottom-white-05 { border-bottom: 1px solid rgba(255,255,255,0.08); }
.border-top-white-05 { border-top: 1px solid rgba(255,255,255,0.08); }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1) !important; }
.controls-bar { border: 1px solid rgba(0,0,0,0.08); padding: 10px; }
.search-wrap { height: 40px; display: flex; align-items: center; min-width: 300px; }

@media (max-width: 600px) { .search-wrap { min-width: 100%; } }

.clean-input { border: none; outline: none; flex: 1; font-size: 13px; }
.bg-black-20 { background: rgba(0,0,0,0.2) !important; }

.grid-scroll { scrollbar-gutter: stable; -webkit-overflow-scrolling: touch; }
.custom-scroll::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.35); border-radius: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }

.grid-header, .grid-row { display: grid; align-items: stretch; width: 100%; min-width: 800px; }
.cell { padding: 6px 12px; display: flex; align-items: center; border-right: 1px solid rgba(0,0,0,0.08); border-bottom: 1px solid rgba(0,0,0,0.08); min-height: 54px; overflow: hidden; transition: background-color 0.2s ease; }
.header-text { font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; line-height: 1.2; font-size: 12px; }
.center { justify-content: center; text-align: center; }
.grid-header .cell { min-height: 44px; }
.list-text-11 { font-size: 13px !important; line-height: 1.2 !important; }

.background-carousel-wrapper { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; opacity: 0.6; pointer-events: none; }
.background-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1; background: radial-gradient(circle at center, rgba(15, 15, 19, 0.4), rgba(15, 15, 19, 0.98)); backdrop-filter: blur(8px); }

.grid-surface-light .cell { background: #f5f7fa; color: rgba(0,0,0,0.9); border-color: rgba(0,0,0,0.12) !important; }
.grid-row-light .cell { border-color: rgba(0,0,0,0.08) !important; }
.zebra-light-a .cell { background: #ffffff; }
.zebra-light-b .cell { background: #f0f4f8; }
.grid-row-light:hover .cell { background: #e3f2fd !important; }

.grid-surface-dark .cell { background: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.80) !important; border-color: rgba(255,255,255,0.10) !important; }
.grid-row-dark .cell { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08) !important; color: rgba(255,255,255,0.85); }
.zebra-dark-a .cell { background: rgba(255,255,255,0.04) !important; }
.zebra-dark-b .cell { background: rgba(255,255,255,0.015) !important; }
.grid-row-dark:hover .cell { background: rgba(255,255,255,0.07) !important; }

.v-theme--dark { .text-grey-darken-4, .text-grey-darken-3, .text-grey-darken-2, .text-grey-darken-1, .text-grey { color: rgba(255,255,255,0.9) !important; } }

.actions-inline { display: flex; gap: 4px; justify-content: center; }
.action-btn { width: 28px !important; height: 28px !important; color: #fff !important; }
.action-edit { background: #1976d2 !important; }
.action-del { background: #c62828 !important; }

.btn-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important; transition: transform 0.1s ease, box-shadow 0.1s ease; text-transform: none !important; }
.btn-3d:active { transform: translateY(2px); box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important; }
.chip-3d { border-radius: 6px !important; box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important; text-shadow: 0 1px 2px rgba(0,0,0,0.25); }

.ui-field :deep(.v-field) { border-radius: 0 !important; }
.row-gap { row-gap: 14px; }
.fixed-dialog { overflow: hidden !important; }
.absolute-fill { height: 100%; overflow-y: auto; }

.flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(0,0,0,0.12) !important; }
.bg-glass-dark .flex-grow-1.overflow-hidden > .v-card.flex-grow-1 { border: 1px solid rgba(255,255,255,0.12) !important; }

.sticky-head { position: sticky; top: 0; z-index: 20; box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.12); }
.bg-glass-dark .sticky-head { box-shadow: 0 8px 20px -4px rgba(0, 0, 0, 0.4); }
</style>
