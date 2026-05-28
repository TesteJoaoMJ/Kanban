<template>
  <v-dialog v-model="dialog" max-width="560" scrollable persistent transition="dialog-bottom-transition">
    <v-card class="rounded-sm overflow-hidden d-flex flex-column" :class="themeClass" max-height="85vh">

      <div class="px-6 py-5 border-b flex-shrink-0 d-flex align-center justify-space-between bg-glass-header" :class="headerBorderClass">
        <div class="d-flex align-center gap-4">
          <div class="icon-box elevation-2 rounded-sm d-flex align-center justify-center transition-all" :class="isDark ? 'bg-indigo-darken-3 text-white' : 'bg-indigo-lighten-5 text-indigo-darken-2'">
            <v-icon size="24">mdi-shield-lock-outline</v-icon>
          </div>
          <div>
            <h3
              class="text-h6 font-weight-black lh-1 letter-spacing-tight"
              @click="handleSecretClick"
              style="user-select: none;"
            >
              Fechamento Cego
            </h3>
            <div class="text-caption font-weight-medium opacity-70 mt-1">Conferência Detalhada de Saldo</div>
          </div>
        </div>
        <v-btn icon variant="text" color="grey" density="comfortable" @click="dialog = false"><v-icon>mdi-close</v-icon></v-btn>
      </div>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto custom-scrollbar" :class="isDark ? 'bg-surface' : 'bg-grey-lighten-5'">
        <div class="pa-6">

          <v-alert type="info" variant="tonal" class="mb-6 text-caption border-thin rounded-sm font-weight-medium lh-14" color="indigo">
            <template v-slot:prepend>
              <v-icon size="24" class="mr-2 opacity-80">mdi-information-outline</v-icon>
            </template>
            Informe os valores exatos conferidos na gaveta física e os subtotais apurados em maquininhas ou extratos.
          </v-alert>

          <div class="mb-6 pa-5 rounded-sm border-thin shadow-sm transition-all" :class="isDark ? 'bg-surface-light border-white-10' : 'bg-white border-grey-lighten-2'">
            <label class="d-flex align-center gap-2 mb-3">
              <span class="text-button font-weight-bold opacity-80" :class="{'text-primary': totalFisico > 0}">Dinheiro em Espécie (Gaveta) *</span>
              <v-tooltip location="top" max-width="250" text="Soma obrigatória de todas as notas e moedas físicas presentes na sua gaveta de caixa. Não inclua Pix.">
                <template v-slot:activator="{ props }">
                  <v-icon v-bind="props" size="16" color="grey-darken-1" class="cursor-help hover-primary">mdi-help-circle</v-icon>
                </template>
              </v-tooltip>
            </label>
            <v-text-field
               v-model="balances.dinheiro"
               type="number"
               variant="outlined"
               prefix="R$"
               placeholder="0,00"
               class="text-h5 font-weight-black input-highlight text-primary"
               :bg-color="inputBgColor"
               hide-details
               :disabled="isCalculating || loading"
               autofocus
            ></v-text-field>
          </div>

          <label class="text-caption font-weight-bold text-uppercase opacity-60 mb-3 d-block ml-1 tracking-wide">
            Valores Virtuais e Maquininha
          </label>

          <v-row dense class="mb-4 gx-3 gy-3">
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">PIX</label>
              <v-text-field v-model="balances.pix" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">Cartão de Crédito</label>
              <v-text-field v-model="balances.credito" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">Cartão de Débito</label>
              <v-text-field v-model="balances.debito" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">Transf. Bancária</label>
              <v-text-field v-model="balances.transferencia" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">Boleto</label>
              <v-text-field v-model="balances.boleto" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">
              <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-1">Crédito Loja / Outros</label>
              <v-text-field v-model="balances.creditoLoja" type="number" variant="outlined" prefix="R$" placeholder="0,00" density="comfortable" :bg-color="inputBgColor" hide-details :disabled="isCalculating || loading"></v-text-field>
            </v-col>
          </v-row>

          <v-divider class="my-6 opacity-20 border-dashed"></v-divider>

          <div class="mb-6">
            <div class="d-flex align-center justify-space-between mb-3">
              <label class="text-caption font-weight-bold text-uppercase opacity-60 tracking-wide">
                Formas Específicas / Adicionais
              </label>
              <v-btn variant="tonal" size="small" color="primary" class="rounded-sm text-none font-weight-bold" @click="addCustomBalance" :disabled="isCalculating || loading">
                <v-icon start size="16">mdi-plus-circle-outline</v-icon> Adicionar Linha
              </v-btn>
            </div>

            <div v-if="customBalances.length === 0" class="text-center pa-4 rounded-sm border-thin opacity-50 text-caption font-weight-medium border-dashed">
              Nenhuma forma adicional informada.
            </div>

            <v-scroll-y-transition group>
              <div v-for="(item, index) in customBalances" :key="item.id" class="d-flex align-center gap-2 mb-2">
                <v-text-field
                    v-model="item.name"
                    placeholder="Nome da Forma (Ex: Permuta)"
                    density="compact"
                    variant="outlined"
                    :bg-color="inputBgColor"
                    hide-details
                    :disabled="isCalculating || loading"
                    class="flex-grow-1 elevation-0"
                ></v-text-field>
                <v-text-field
                    v-model="item.value"
                    type="number"
                    prefix="R$"
                    placeholder="0,00"
                    density="compact"
                    variant="outlined"
                    :bg-color="inputBgColor"
                    hide-details
                    :disabled="isCalculating || loading"
                    style="max-width: 140px;"
                ></v-text-field>
                <v-btn icon color="error" variant="text" density="comfortable" class="opacity-70 hover-opacity-100" @click="removeCustomBalance(item.id)" :disabled="isCalculating || loading">
                    <v-icon>mdi-close-circle</v-icon>
                </v-btn>
              </div>
            </v-scroll-y-transition>
          </div>

          <label class="d-flex align-center gap-1 text-[11px] font-weight-bold text-uppercase opacity-70 mb-2">
            <v-icon size="14">mdi-text-box-edit-outline</v-icon> Observações de Fechamento
          </label>
          <v-textarea
             v-model="closingNotes"
             variant="outlined"
             placeholder="Relate aqui quebras de caixa, falta de troco, ou justificativas importantes..."
             :bg-color="inputBgColor"
             hide-details
             rows="2"
             auto-grow
             density="comfortable"
             :disabled="isCalculating || loading"
             class="mb-2"
          ></v-textarea>
        </div>
      </v-card-text>

      <div class="px-6 py-4 border-t flex-shrink-0 bg-glass-footer" :class="headerBorderClass">

        <div class="mb-4 px-4 py-3 rounded-sm d-flex justify-space-between align-center border-thin transition-all" :class="isDark ? 'bg-grey-darken-4 border-grey-darken-3' : 'bg-indigo-lighten-5 border-indigo-lighten-4'">
           <span class="text-caption font-weight-bold text-uppercase opacity-80 tracking-wide" :class="isDark ? 'text-white' : 'text-indigo-darken-4'">Total Apurado</span>
           <span class="text-h6 font-weight-black" :class="totalGeral > 0 ? 'text-primary' : 'opacity-50'">
             R$ {{ totalGeral.toFixed(2).replace('.', ',') }}
           </span>
        </div>

        <div class="d-flex gap-3">
          <v-btn
              v-if="isSimulateButtonVisible"
              variant="outlined"
              color="indigo"
              height="54"
              class="font-weight-black rounded-sm bg-white"
              :loading="isSimulating"
              @click="runSimulation"
              v-tooltip="'Visualiza o que será impresso vs o que foi registrado'"
          >
              <v-icon start>mdi-test-tube</v-icon>
              SIMULAR
          </v-btn>

          <v-btn
            class="flex-grow-1 font-weight-black rounded-sm shadow-soft letter-spacing-1"
            color="indigo-darken-2"
            height="54"
            :loading="loading || isCalculating"
            :disabled="balances.dinheiro === '' || isCalculating"
            @click="confirmClose"
          >
            <v-icon start size="20">mdi-lock-check</v-icon>
            ENCERRAR TURNO
          </v-btn>
        </div>
      </div>
    </v-card>
  </v-dialog>

  <v-dialog v-model="showPinModal" max-width="350" persistent>
      <v-card class="rounded-sm border-thin border-error" @contextmenu.prevent="handleRightClick">
          <v-card-title class="text-center pt-6 pb-2">
              <v-icon color="error" size="36" class="mb-2">mdi-shield-key-outline</v-icon>
              <div class="text-h6 font-weight-black">Acesso Confidencial</div>
          </v-card-title>
          <v-card-text class="pb-6">
              <div class="text-caption text-center mb-4 opacity-70">Credenciais exigidas para auditoria</div>
              <v-text-field
                  v-model="enteredPin"
                  type="password"
                  variant="outlined"
                  density="comfortable"
                  placeholder="****"
                  maxlength="4"
                  class="pin-input rounded-sm"
                  hide-details
                  @keyup.enter="validatePin"
                  autofocus
                  :error="pinAttempts > 0"
              ></v-text-field>
              <div v-if="pinAttempts > 0" class="text-error text-caption text-center mt-3 font-weight-medium">
                  PIN Incorreto. Tentativa {{ pinAttempts }} de 3.
              </div>
          </v-card-text>
          <v-card-actions class="px-6 pb-6 pt-0 justify-space-between">
              <v-btn variant="text" color="grey" @click="closePinModal">Abortar</v-btn>
              <v-btn variant="flat" color="error" class="rounded-sm font-weight-bold px-6" @click="validatePin">Validar</v-btn>
          </v-card-actions>
      </v-card>
  </v-dialog>

  <v-dialog v-model="showLockdownModal" fullscreen persistent transition="fade-transition">
      <div :class="matrixContainerClass" @contextmenu.prevent="handleRightClick">
          <div class="terminal-content">
              <pre class="matrix-text" v-html="formattedTerminalText"></pre>

              <div v-if="superAdmins.length > 0" class="d-flex flex-wrap gap-6 mt-8 pl-4">
                  <div v-for="(admin, index) in superAdmins" :key="index" class="d-flex align-center gap-3 matrix-admin-card rounded-sm">
                      <v-avatar size="50" :image="admin.avatar_url || `https://api.dicebear.com/7.x/bottts/svg?seed=${admin.username}`" class="border-matrix rounded-sm"></v-avatar>
                      <div>
                        <div class="matrix-text-small font-weight-bold text-uppercase">{{ admin.full_name || admin.username }}</div>
                        <div class="matrix-text-xs opacity-70">SUPER_ADMIN</div>
                      </div>
                  </div>
              </div>

              <div class="mt-8" v-if="lockdownComplete">
                 <span class="matrix-text text-error font-weight-black pulse-error">>> O SISTEMA ESTÁ EXPULSANDO VOCÊ AGORA.</span>
              </div>
          </div>
      </div>
  </v-dialog>

  <v-dialog v-model="showSimulator" max-width="1100" scrollable transition="dialog-bottom-transition">
      <v-card class="rounded-sm shadow-2xl border-thin overflow-hidden d-flex flex-column" :class="isDark ? 'bg-surface' : 'bg-white'">

          <div class="px-6 py-4 border-b flex-shrink-0 d-flex align-center justify-space-between" :class="isDark ? 'bg-glass-dark border-white-10' : 'bg-surface-light border-grey-lighten-2'">
              <div class="d-flex align-center gap-4">
                  <div class="icon-box-md rounded-sm elevation-1 d-flex align-center justify-center bg-indigo-lighten-5 text-indigo-darken-2">
                      <v-icon size="24">mdi-shield-search</v-icon>
                  </div>
                  <div>
                      <h3 class="text-h6 font-weight-black lh-1" :class="isDark ? 'text-white' : 'text-primary'">Auditoria de Caixa Preta</h3>
                      <div class="text-caption opacity-70 mt-1">Verificação detalhada e correção de anomalias do turno</div>
                  </div>
              </div>
              <v-btn icon variant="text" density="comfortable" @click="showSimulator = false" :color="isDark ? 'white' : 'grey-darken-2'">
                  <v-icon>mdi-close</v-icon>
              </v-btn>
          </div>

          <v-card-text class="pa-6 custom-scrollbar" :class="isDark ? 'bg-grey-darken-4' : 'bg-grey-lighten-4'">
              <v-row>
                  <v-col cols="12" md="6">
                      <div class="rounded-sm border-thin pa-5 h-100 shadow-sm transition-all" :class="isDark ? 'bg-surface border-white-10' : 'bg-white'">
                          <div class="d-flex align-center justify-space-between mb-4 border-b pb-3" :class="isDark ? 'border-white-10' : 'border-grey-lighten-3'">
                              <h3 class="text-subtitle-1 font-weight-black text-amber-darken-3 lh-1">
                                  Registros do Banco
                              </h3>
                              <v-chip size="small" variant="flat" color="amber-lighten-5" class="text-amber-darken-4 font-weight-black border border-amber-lighten-3 rounded-sm">
                                  {{ simulationData.audited.length }} itens
                              </v-chip>
                          </div>

                          <div v-if="simulationData.audited.length === 0" class="text-center py-8 opacity-50 text-caption font-weight-bold">
                              Nenhum registro rastreado neste turno.
                          </div>

                          <v-scale-transition group>
                              <div v-for="(item, i) in simulationData.audited" :key="'aud-'+item.id+'-'+i" class="pa-4 mb-3 rounded-sm border-thin d-flex align-center justify-space-between transition-all hover-elevate" :class="isDark ? 'bg-grey-darken-3 hover-bg-light' : 'bg-white hover-bg-light border-s-4 border-s-amber'">
                                  <div class="d-flex align-center gap-3">
                                      <div class="rounded-sm pa-2 d-flex align-center justify-center" :class="item.is_cash ? 'bg-green-lighten-5 text-green-darken-2' : 'bg-blue-lighten-5 text-blue-darken-2'">
                                          <v-icon size="18">{{ item.is_cash ? 'mdi-cash' : 'mdi-credit-card' }}</v-icon>
                                      </div>
                                      <div class="d-flex flex-column">
                                          <span class="font-weight-black text-body-2 lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ item.ref || item.order_ref || 'Sem Ref' }}</span>
                                          <span class="text-[11px] font-weight-bold opacity-60 text-uppercase mt-1">{{ item.origin || item.type }} • {{ item.method_name || item.method }}</span>
                                      </div>
                                  </div>
                                  <div class="d-flex align-center gap-3">
                                      <span class="font-mono font-weight-black text-body-2" :class="Number(item.amount) > 0 ? 'text-success-darken-1' : 'text-error'">R$ {{ Number(item.amount).toFixed(2).replace('.', ',') }}</span>

                                      <v-tooltip text="Excluir (Estornar) do Banco e do Fechamento" location="top" v-if="userStore.isAdmin">
                                          <template v-slot:activator="{ props }">
                                              <v-btn v-bind="props" icon="mdi-trash-can-outline" variant="text" color="error" size="small" density="comfortable" class="opacity-40 hover-opacity-100 rounded-sm" @click="requestExclusion(item)"></v-btn>
                                          </template>
                                      </v-tooltip>
                                  </div>
                              </div>
                          </v-scale-transition>
                      </div>
                  </v-col>

                  <v-col cols="12" md="6">
                      <div class="rounded-sm border-thin pa-5 h-100 shadow-sm transition-all" :class="isDark ? 'bg-surface border-white-10' : 'bg-white'">
                          <div class="d-flex align-center justify-space-between mb-4 border-b pb-3" :class="isDark ? 'border-white-10' : 'border-grey-lighten-3'">
                              <h3 class="text-subtitle-1 font-weight-black text-indigo-darken-2 lh-1">
                                  Extração (Para o Relatório)
                              </h3>
                              <v-chip size="small" variant="flat" color="indigo-lighten-5" class="text-indigo-darken-4 font-weight-black border border-indigo-lighten-3 rounded-sm">
                                  {{ simulationData.extracted.length }} itens
                              </v-chip>
                          </div>

                          <div v-if="simulationData.extracted.length === 0" class="text-center py-8 opacity-50 text-caption font-weight-bold">
                              O sistema não encontrou dados para o relatório.
                          </div>

                          <v-scale-transition group>
                              <div v-for="(item, i) in simulationData.extracted" :key="'ext-'+item.id+'-'+i" class="pa-4 mb-3 rounded-sm border-thin d-flex align-center justify-space-between transition-all hover-elevate" :class="isDark ? 'bg-grey-darken-3 hover-bg-light' : 'bg-white hover-bg-light border-s-4 border-s-indigo'">
                                  <div class="d-flex align-center gap-3">
                                      <div class="rounded-sm pa-2 d-flex align-center justify-center" :class="item.isCash ? 'bg-green-lighten-5 text-green-darken-2' : 'bg-blue-lighten-5 text-blue-darken-2'">
                                          <v-icon size="18">{{ item.isCash ? 'mdi-cash' : 'mdi-credit-card' }}</v-icon>
                                      </div>
                                      <div class="d-flex flex-column">
                                          <span class="font-weight-black text-body-2 lh-1" :class="isDark ? 'text-white' : 'text-grey-darken-4'">{{ item.ref || item.order_ref || 'S/N' }}</span>
                                          <span class="text-[11px] font-weight-bold opacity-60 text-uppercase mt-1">{{ item.source || item.type }} • {{ item.method || item.method_name }}</span>
                                      </div>
                                  </div>
                                  <div class="d-flex align-center gap-3">
                                      <span class="font-mono font-weight-black text-body-2" :class="Number(item.amount) > 0 ? 'text-success-darken-1' : 'text-error'">R$ {{ Number(item.amount).toFixed(2).replace('.', ',') }}</span>

                                      <v-tooltip text="Bloquear envio deste item para o fechamento" location="top" v-if="userStore.isAdmin">
                                          <template v-slot:activator="{ props }">
                                              <v-btn v-bind="props" icon="mdi-cancel" variant="text" color="error" size="small" density="comfortable" class="opacity-40 hover-opacity-100 rounded-sm" @click="requestExclusion(item)"></v-btn>
                                          </template>
                                      </v-tooltip>
                                  </div>
                              </div>
                          </v-scale-transition>
                      </div>
                  </v-col>
              </v-row>
          </v-card-text>
      </v-card>
  </v-dialog>

  <v-dialog v-model="confirmDialog" max-width="400" persistent>
      <v-card class="rounded-sm border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">
          <div class="pa-6 text-center">
              <div class="icon-circle-lg mx-auto mb-4 rounded-sm" :class="isDark ? 'bg-red-darken-4' : 'bg-red-lighten-5'">
                  <v-icon size="40" color="error">mdi-alert-octagon</v-icon>
              </div>
              <h3 class="text-h6 font-weight-black mb-2">Confirmar Exclusão</h3>
              <p class="text-body-2 opacity-70 mb-6">
                  Tem certeza que deseja excluir permanentemente o registro <strong>{{ itemToExclude?.ref || itemToExclude?.order_ref || 'Selecionado' }}</strong> no valor de <strong>R$ {{ Number(itemToExclude?.amount || 0).toFixed(2).replace('.', ',') }}</strong>?
                  <br><br>Esta ação removerá o item do banco de dados e do fechamento.
              </p>
              <div class="d-flex gap-3">
                  <v-btn variant="outlined" class="flex-grow-1 rounded-sm font-weight-bold" height="44" @click="confirmDialog = false" :disabled="isExcluding">Cancelar</v-btn>
                  <v-btn color="error" variant="flat" class="flex-grow-1 rounded-sm font-weight-black shadow-soft" height="44" @click="confirmExclusion" :loading="isExcluding">Excluir Registro</v-btn>
              </div>
          </div>
      </v-card>
  </v-dialog>

</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { supabase } from '@/api/supabase';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useCashReport } from '@/composables/useCashReport';
import { useAppStore } from '@/stores/app'; // Store para notificações

const props = defineProps(['modelValue']);
const emit = defineEmits(['update:modelValue', 'session-closed']);

const cashStore = useMjCashSessionStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const appStore = useAppStore();
const { generateClosingReport } = useCashReport();

const balances = ref({ dinheiro: '', pix: '', credito: '', debito: '', transferencia: '', boleto: '', creditoLoja: '' });
const customBalances = ref<{ id: number, name: string, value: string }[]>([]);
let customIdCounter = 0;

const addCustomBalance = () => { customBalances.value.push({ id: customIdCounter++, name: '', value: '' }); };
const removeCustomBalance = (id: number) => { customBalances.value = customBalances.value.filter(c => c.id !== id); };

const closingNotes = ref('');
const loading = ref(false);
const isCalculating = ref(false);

const dialog = computed({ get: () => props.modelValue, set: (val) => emit('update:modelValue', val) });
const isDark = computed(() => themeStore.currentMode !== 'light');
const themeClass = computed(() => isDark.value ? 'bg-surface border-white-10' : 'bg-white');
const headerBorderClass = computed(() => isDark.value ? 'border-white-10' : 'border-grey-lighten-3');
const inputBgColor = computed(() => isDark.value ? 'rgba(0,0,0,0.2)' : 'white');

const totalFisico = computed(() => parseFloat(balances.value.dinheiro || '0'));
const totalGeral = computed(() => {
    let sum = totalFisico.value +
           parseFloat(balances.value.pix || '0') + parseFloat(balances.value.credito || '0') +
           parseFloat(balances.value.debito || '0') + parseFloat(balances.value.transferencia || '0') +
           parseFloat(balances.value.boleto || '0') + parseFloat(balances.value.creditoLoja || '0');
    customBalances.value.forEach(c => { sum += parseFloat(c.value || '0'); });
    return sum;
});

// ESTADO DO SIMULADOR E EASTER EGG (CAIXA PRETA)
const showSimulator = ref(false);
const simulationData = ref({ extracted: [] as any[], audited: [] as any[] });
const isSimulating = ref(false);
const isExcluding = ref(false);

// ESTADO DO MODAL DE CONFIRMAÇÃO DO SISTEMA
const confirmDialog = ref(false);
const itemToExclude = ref<any>(null);

const isSimulateButtonVisible = ref(false);
const secretClickCount = ref(0);
let secretClickTimeout: any = null;

const showPinModal = ref(false);
const enteredPin = ref('');
const pinAttempts = ref(0);

// MATRIX LOCKDOWN STATE
const showLockdownModal = ref(false);
const terminalText = ref('');
const superAdmins = ref<any[]>([]);
const lockdownComplete = ref(false);
const matrixContainerClass = ref('matrix-container custom-scrollbar');

const formattedTerminalText = computed(() => {
    return terminalText.value + '<span class="matrix-cursor">_</span>';
});

const handleRightClick = (e: Event) => {
    e.preventDefault();
    if (showLockdownModal.value) {
        matrixContainerClass.value = 'matrix-container error-flash';
        typeMatrixText("\n[!!!] TENTATIVA DE INSPEÇÃO BLOQUEADA. O SISTEMA SABE EXATAMENTE O QUE VOCÊ ESTÁ TENTANDO FAZER.", 10);
        setTimeout(() => {
            matrixContainerClass.value = 'matrix-container custom-scrollbar';
        }, 500);
    }
};

const handleSecretClick = async () => {
    const userId = userStore.profile?.id;
    if (userId && localStorage.getItem(`matrix_lockdown_${userId}`) === 'true') {
        if (!showLockdownModal.value) {
            showLockdownModal.value = true;
            terminalText.value = '';
            await typeMatrixText("\n>> TENTATIVA REINCIDENTE DETECTADA <<\n", 20);
            await typeMatrixText("O AVISO FOI DADO ANTERIORMENTE.\n", 30);
            await typeMatrixText("TENTATIVAS CONSECUTIVAS IMPLICARÃO EM BLOQUEIO PERMANENTE DO SEU USUÁRIO.\n", 30);
            await typeMatrixText("DESLOGANDO IMEDIATAMENTE...", 40);

            setTimeout(async () => {
                await userStore.signOut();
                window.location.reload();
            }, 3000);
        }
        return;
    }

    secretClickCount.value++;

    if (secretClickTimeout) clearTimeout(secretClickTimeout);

    if (secretClickCount.value >= 7) {
        secretClickCount.value = 0;
        if (!isSimulateButtonVisible.value) {
            showPinModal.value = true;
            enteredPin.value = '';
            pinAttempts.value = 0;
        }
    } else {
        secretClickTimeout = setTimeout(() => {
            secretClickCount.value = 0;
        }, 1500);
    }
};

const closePinModal = () => {
    showPinModal.value = false;
    enteredPin.value = '';
    pinAttempts.value = 0;
};

const typeMatrixText = async (text: string, delay = 25) => {
    terminalText.value += '\n> ';
    for (let char of text) {
        terminalText.value += char;
        await new Promise(r => setTimeout(r, delay));
    }
};

const executeMatrixLockdown = async () => {
    showLockdownModal.value = true;
    terminalText.value = '';
    superAdmins.value = [];
    lockdownComplete.value = false;

    await new Promise(r => setTimeout(r, 500));
    await typeMatrixText("INICIANDO PROTOCOLO DE DEFESA DE NÍVEL 4...", 30);
    await new Promise(r => setTimeout(r, 400));
    await typeMatrixText("RASTREANDO ORIGEM DA TENTATIVA...", 20);
    await new Promise(r => setTimeout(r, 300));
    await typeMatrixText(`[ CRÍTICO ] VIOLAÇÃO DE ACESSO DETECTADA NO PERFIL: ${userStore.profile?.username?.toUpperCase() || 'UNKNOWN'}`, 40);

    await typeMatrixText("CAPTURANDO DADOS DA MÁQUINA LOCAL... [OK]", 15);
    await typeMatrixText("ENVIANDO LOGS DE AUDITORIA... [OK]", 15);

    await new Promise(r => setTimeout(r, 600));
    await typeMatrixText("BUSCANDO AUTORIDADES SUPERIORES...", 30);

    try {
        const { data } = await supabase
            .from('profiles')
            .select('username, avatar_url, full_name')
            .eq('role', 'super_admin');
        if (data) superAdmins.value = data;
    } catch(e) {}

    await new Promise(r => setTimeout(r, 800));

    if (superAdmins.value.length > 0) {
        await typeMatrixText("NOTIFICANDO SUPER ADMINISTRADORES EXIBIDOS ABAIXO:", 20);
        await new Promise(r => setTimeout(r, 2000));
    }

    await typeMatrixText("\n!!! AVISO FINAL !!!", 50);
    await typeMatrixText("TENTATIVAS CONSECUTIVAS IMPLICARÃO EM BLOQUEIO PERMANENTE DO SEU USUÁRIO.", 40);
    await typeMatrixText("EXPULSANDO INVASOR E ENCERRANDO SESSÃO...", 60);

    if (userStore.profile?.id) {
        localStorage.setItem(`matrix_lockdown_${userStore.profile.id}`, 'true');
    }

    lockdownComplete.value = true;

    setTimeout(async () => {
        await userStore.signOut();
        window.location.reload();
    }, 4500);
};

const validatePin = () => {
    const correctPin = userStore.profile?.security_pin || '0000';

    if (enteredPin.value === correctPin) {
        isSimulateButtonVisible.value = true;
        closePinModal();
    } else {
        pinAttempts.value++;
        enteredPin.value = '';
        if (pinAttempts.value >= 3) {
            closePinModal();
            executeMatrixLockdown();
        }
    }
};

const runSimulation = async () => {
    isSimulating.value = true;
    try {
        simulationData.value = await cashStore.simulateExtraction();
        showSimulator.value = true;
    } catch (e) {
        console.error("Erro na simulação", e);
    } finally {
        isSimulating.value = false;
    }
};

const requestExclusion = (item: any) => {
    if (!userStore.isAdmin) {
        appStore.showSnackbar('Apenas administradores podem excluir registros.', 'error');
        return;
    }
    itemToExclude.value = item;
    confirmDialog.value = true;
};

const confirmExclusion = async () => {
    if (!itemToExclude.value) return;
    isExcluding.value = true;
    try {
        const item = itemToExclude.value;
        const refTarget = item.ref || item.order_ref;

        // Tenta remover por ID se disponível
        if (item.id) {
            await supabase.from('mj_cash_movements').delete().eq('id', item.id);
            await supabase.from('finance_receivables').delete().eq('id', item.id);
        } else if (refTarget) {
            // Fallback: Varre a tabela para limpar pela referência caso o ID seja virtual
            await supabase.from('mj_cash_movements').delete().ilike('description', `%${refTarget}%`);
            await supabase.from('finance_receivables').delete().ilike('description', `%${refTarget}%`);
        }

        // Filtra instantaneamente o item de ambas as listas para sumir da tela
        simulationData.value.audited = simulationData.value.audited.filter(x => x !== item && x.id !== item.id);
        simulationData.value.extracted = simulationData.value.extracted.filter(x => x !== item && x.id !== item.id);

        appStore.showSnackbar('Registro excluído com sucesso do banco e do relatório.', 'success');

        confirmDialog.value = false;
        itemToExclude.value = null;

    } catch (e: any) {
        console.error("Erro ao excluir registro:", e);
        appStore.showSnackbar('Erro ao excluir o registro do banco de dados.', 'error');
    } finally {
        isExcluding.value = false;
    }
};

watch(dialog, async (val) => {
    if (val) {
        balances.value = { dinheiro: '', pix: '', credito: '', debito: '', transferencia: '', boleto: '', creditoLoja: '' };
        customBalances.value = [];
        closingNotes.value = '';

        isSimulateButtonVisible.value = false;
        secretClickCount.value = 0;
        pinAttempts.value = 0;
        showLockdownModal.value = false;
        terminalText.value = '';

        isCalculating.value = true;
        try { await cashStore.recalculateSessionBalance(); }
        catch (e) { console.error("Erro ao recálculo do saldo:", e); }
        finally { isCalculating.value = false; }
    }
});

const confirmClose = async () => {
    if (balances.value.dinheiro === '') return;
    loading.value = true;
    try {
        const finalVal = totalFisico.value;
        const notesToSave = closingNotes.value.trim() || 'Fechamento Cego Individual';
        const result = await cashStore.closeSession(finalVal, notesToSave);

        if (result && result.session) {
            result.session.closing_notes = closingNotes.value.trim();
            result.session.user_breakdown = {
                ...balances.value,
                custom: customBalances.value.filter(c => c.name.trim() !== ''),
                total_geral: totalGeral.value
            };
        }

        await generateClosingReport(result.session, result.movements, userStore.activeStoreName, userStore.profile?.full_name || 'Operador', result.detailedSales);
        emit('session-closed', result);
        dialog.value = false;
    } catch (e) { console.error("Erro ao fechar sessão:", e); }
    finally { loading.value = false; }
};
</script>

<style scoped>
.rounded-sm { border-radius: 2px !important; }

.icon-box { width: 44px; height: 44px; }
.icon-box-md { width: 48px; height: 48px; }
.lh-1 { line-height: 1.2; }
.lh-14 { line-height: 1.4; }
.gap-1 { gap: 4px; } .gap-2 { gap: 8px; } .gap-3 { gap: 12px; } .gap-4 { gap: 16px; }
.tracking-wide { letter-spacing: 0.05em; }
.letter-spacing-1 { letter-spacing: 1px; }

/* Scrollbar Customizada (Padrão Mac/Shopify) */
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(150, 150, 150, 0.3); border-radius: 2px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(150, 150, 150, 0.5); }

/* Inputs e Sombras */
.input-highlight :deep(.v-field__outline) { --v-field-border-width: 2px; }
.input-highlight :deep(.v-field__input) { text-align: center; }
.shadow-soft { box-shadow: 0 4px 14px rgba(0,0,0,0.1) !important; }
.shadow-sm { box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.shadow-2xl { box-shadow: 0 20px 40px rgba(0,0,0,0.15); }

/* Estilo do input de PIN */
.pin-input :deep(.v-field__input) {
    text-align: center;
    letter-spacing: 0.5em;
    font-size: 1.5rem;
    font-weight: bold;
}

/* === TEMA MATRIX LOCKDOWN === */
.matrix-container {
    background-color: #030303;
    width: 100vw;
    height: 100vh;
    padding: 3rem 2rem;
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    font-family: 'Courier New', Courier, monospace;
    transition: background-color 0.1s ease;
}
.error-flash {
    animation: flashRed 0.5s;
}
@keyframes flashRed {
    0% { background-color: #030303; }
    50% { background-color: #4a0000; }
    100% { background-color: #030303; }
}

.terminal-content {
    max-width: 900px;
    margin: 0 auto;
    width: 100%;
}
.matrix-text {
    color: #00ff41;
    font-size: 1.2rem;
    text-shadow: 0 0 8px rgba(0, 255, 65, 0.6);
    white-space: pre-wrap;
    line-height: 1.6;
    margin: 0;
}
.text-error {
    color: #ff3333 !important;
    text-shadow: 0 0 12px rgba(255, 51, 51, 0.8) !important;
}
.pulse-error {
    animation: pulseError 1.5s infinite;
}
@keyframes pulseError {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}
.matrix-text-small {
    color: #00ff41;
    font-size: 1rem;
    text-shadow: 0 0 5px rgba(0, 255, 65, 0.5);
}
.matrix-text-xs {
    color: #00ff41;
    font-size: 0.75rem;
}
.matrix-cursor {
    animation: blink-matrix 1s step-end infinite;
}
@keyframes blink-matrix {
    0%, 100% { opacity: 1; }
    50% { opacity: 0; }
}
.border-matrix {
    border: 2px solid #ff3333 !important;
    box-shadow: 0 0 12px rgba(255, 51, 51, 0.8);
}
.matrix-admin-card {
    background: rgba(255, 51, 51, 0.05);
    padding: 10px 24px 10px 10px;
    border-radius: 2px;
    border: 1px solid rgba(255, 51, 51, 0.2);
    animation: glitch-in 0.4s ease-out forwards;
}
@keyframes glitch-in {
    0% { transform: scale(0.9) translateX(-20px); opacity: 0; filter: blur(4px); }
    50% { transform: scale(1.02) translateX(5px); opacity: 0.8; filter: hue-rotate(-50deg); }
    100% { transform: scale(1) translateX(0); opacity: 1; filter: blur(0); }
}
/* ========================== */

/* Borders e Backgrounds (Glassmorphism sutil) */
.border-white-10 { border-color: rgba(255,255,255,0.1) !important; }
.border-thin { border-width: 1px !important; border-style: solid; border-color: rgba(var(--v-border-color), 0.1) !important; }
.border-dashed { border-style: dashed !important; border-width: 1px !important; }
.bg-glass-header { background: rgba(var(--v-theme-surface), 0.95); backdrop-filter: blur(8px); z-index: 10; }
.bg-glass-footer { background: rgba(var(--v-theme-surface), 0.95); backdrop-filter: blur(8px); z-index: 10; }
.bg-glass-dark { background: rgba(30,30,35,0.95); backdrop-filter: blur(8px); }

.hover-opacity-100 { transition: opacity 0.2s; }
.hover-opacity-100:hover { opacity: 1 !important; }
.cursor-help { cursor: help; }
.hover-primary:hover { color: rgb(var(--v-theme-primary)) !important; }
.transition-all { transition: all 0.3s ease; }
.hover-elevate:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.08); background-color: #fafafa !important; }
.hover-bg-light:hover { background-color: rgba(0,0,0,0.02); cursor: default; }
.icon-circle-lg { width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; }

.v-theme--dark .hover-elevate:hover { background-color: rgba(255,255,255,0.05) !important; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
</style>
