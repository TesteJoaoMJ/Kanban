<template>
  <v-dialog
    :model-value="show"
    @update:model-value="$emit('close')"
    max-width="95%"
    width="1600px"
    height="90vh"
    persistent
    class="launch-detail-modal"
  >
    <v-card :class="['modal-root', themeStore.currentMode === 'light' ? 'light-mode' : 'glass-mode']">

      <v-toolbar color="transparent" density="comfortable" class="modal-header border-b pr-2">
        <v-toolbar-title class="font-weight-bold text-h6 d-flex align-center">
           <v-icon start color="primary" class="mr-3">mdi-rocket-launch-outline</v-icon>
           Gerenciar Lançamento
        </v-toolbar-title>

        <v-spacer></v-spacer>

        <div v-if="order" class="d-none d-md-flex align-center mr-6 text-caption meta-group">
           <div class="meta-item">
              <v-icon size="small" class="mr-1 text-medium-emphasis">mdi-account</v-icon>
              <span class="text-medium-emphasis mr-1">Cliente:</span>
              <span class="font-weight-bold">{{ order.customer_name }}</span>
           </div>
           <div class="meta-divider mx-3"></div>
           <div class="meta-item">
              <v-icon size="small" class="mr-1 text-medium-emphasis">mdi-badge-account-horizontal</v-icon>
              <span class="text-medium-emphasis mr-1">Vendedor:</span>
              <span class="font-weight-bold">{{ order.created_by?.full_name || 'N/A' }}</span>
           </div>
           <div class="meta-divider mx-3"></div>
           <div class="meta-item">
              <v-icon size="small" class="mr-1 text-medium-emphasis">mdi-identifier</v-icon>
              <span class="text-medium-emphasis mr-1">Pedido:</span>
              <span class="font-weight-bold">#{{ order.order_number }}</span>
           </div>
        </div>

        <v-btn icon variant="text" @click="$emit('close')">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-toolbar>

      <div v-if="loading" class="loading-container">
         <v-progress-circular indeterminate color="primary" size="64"></v-progress-circular>
         <span class="mt-4 text-caption text-medium-emphasis">Carregando detalhes...</span>
      </div>

      <div v-else-if="activeItem" class="content-body d-flex flex-row">

         <div class="sidebar-area width-sidebar border-r d-flex flex-column">
            <div class="sidebar-section pa-4 border-b">
               <div class="text-overline font-weight-bold mb-3 text-medium-emphasis">Ficha Técnica</div>

               <v-alert v-if="activeItem.status === 'customer_approval'" type="warning" variant="tonal" density="compact" class="mb-4 text-caption border-radius-sm">
                  <strong>Atenção:</strong> Aguardando aprovação do cliente.
               </v-alert>

               <v-alert v-if="!activeItem.is_op_generated && isReadyForPCPRelease(activeItem)" type="info" variant="tonal" density="compact" class="mb-4 text-caption border-radius-sm">
                  <strong>Ação Necessária:</strong> Gere a OP para liberar.
               </v-alert>

               <div class="info-grid">
                  <div class="info-item">
                     <span class="label">Tecido Base</span>
                     <span class="value">{{ activeItem.fabric_type }}</span>
                  </div>
                  <div class="info-item">
                     <span class="label">Quantidade</span>
                     <span class="value font-weight-bold text-primary">{{ activeItem.quantity_meters }}m</span>
                  </div>
                  <div class="info-item">
                     <span class="label">Status Atual</span>
                     <v-chip size="x-small" :color="statusColor(activeItem.status)" label class="mt-1 font-weight-bold">{{ formatStatus(activeItem.status) }}</v-chip>
                  </div>
                  <div class="info-item full-width">
                     <span class="label">Etapa Design</span>
                     <v-chip size="x-small" :color="getTagColor(activeItem.design_tag)" label class="mt-1">{{ activeItem.design_tag }}</v-chip>
                  </div>
               </div>

               <div class="mt-4">
                  <span class="text-caption text-medium-emphasis font-weight-bold">Notas do Item</span>
                  <div class="notes-box mt-1 pa-2 rounded border text-caption bg-surface-variant-light">
                     {{ activeItem.notes || 'Sem observações cadastradas.' }}
                  </div>
               </div>
            </div>

            <div class="flex-grow-1 d-flex flex-column overflow-hidden">
               <div class="pa-3 border-b bg-surface-variant-light">
                  <div class="text-overline font-weight-bold text-medium-emphasis">Itens no Pedido ({{ editableItems.length }})</div>
               </div>

               <v-list class="flex-grow-1 overflow-y-auto pa-0 bg-transparent item-nav-list" density="compact">
                  <v-list-item
                     v-for="(item, index) in editableItems"
                     :key="item.id"
                     :active="item.id === activeItem.id"
                     @click="selectItem(item.id)"
                     class="nav-item py-2 border-b"
                     :class="{'bg-primary-lighten-5': item.id === activeItem.id && themeStore.currentMode === 'light'}"
                  >
                     <template #prepend>
                        <v-avatar size="36" rounded class="mr-3 icon-3d">
                           <v-icon color="primary-darken-1" size="20">mdi-layers</v-icon>
                        </v-avatar>
                     </template>

                     <v-list-item-title class="font-weight-medium text-body-2">{{ item.stamp_ref }}</v-list-item-title>
                     <v-list-item-subtitle class="text-caption text-medium-emphasis">
                        {{ item.fabric_type }}
                     </v-list-item-subtitle>

                     <template #append>
                        <v-icon v-if="item.is_op_generated" color="info" size="x-small" class="mr-1" title="OP Gerada">mdi-file-document-check</v-icon>
                        <v-icon v-if="['design_released', 'waiting_print', 'printing', 'printed', 'in_production', 'completed'].includes(item.status)" color="purple" size="small" title="No PCP">mdi-factory</v-icon>
                        <v-icon v-else-if="item.status === 'approved_by_seller'" color="success" size="small">mdi-check</v-icon>
                        <v-icon v-else-if="item.status === 'customer_approval'" color="warning" size="small">mdi-clock</v-icon>
                     </template>
                  </v-list-item>
               </v-list>
            </div>
         </div>

         <div class="main-stage flex-grow-1 pa-6 d-flex flex-column bg-stage">

            <div class="d-flex align-center justify-center mb-4 nav-bar-container">
               <div class="nav-controls d-flex align-center gap-4 pa-2 rounded-pill bg-surface-variant-light border elevation-1">
                   <v-btn
                     size="small"
                     variant="text"
                     prepend-icon="mdi-chevron-left"
                     @click="selectPreviousItem"
                     :disabled="!hasPreviousItem"
                     class="nav-btn"
                   >
                     Anterior
                   </v-btn>

                   <v-divider vertical class="mx-2"></v-divider>

                   <span class="text-caption font-weight-bold text-medium-emphasis mx-2">
                     Item {{ currentItemIndex + 1 }} de {{ editableItems.length }}
                   </span>

                   <v-divider vertical class="mx-2"></v-divider>

                   <v-btn
                     size="small"
                     variant="text"
                     append-icon="mdi-chevron-right"
                     @click="selectNextItem"
                     :disabled="!hasNextItem"
                     class="nav-btn"
                   >
                     Próximo
                   </v-btn>
               </div>
            </div>

            <div class="flipper-container flex-grow-1 d-flex justify-center align-center">
                <div class="card-flipper" :class="{ 'is-flipped': activeItem.isEditMode }">

                    <div class="flipper-face face-front">
                      <v-card class="item-card h-100 d-flex flex-column elevation-4">
                         <div class="pa-4 border-b d-flex align-center bg-surface-variant-light">
                            <div class="d-flex align-center flex-grow-1 overflow-hidden">
                                <v-avatar color="primary" variant="tonal" size="40" class="mr-3">
                                    <v-icon>mdi-image-frame</v-icon>
                                </v-avatar>
                                <div class="d-flex flex-column overflow-hidden">
                                    <span class="text-h6 font-weight-bold text-truncate">
                                       {{ activeItem.stamp_ref }}
                                    </span>
                                    <span class="text-caption text-medium-emphasis">Visualização da Arte</span>
                                </div>
                            </div>

                            <div class="d-flex align-center gap-2 ml-4">
                                <v-tooltip text="Alternar Liberação OP" location="top" content-class="tooltip-contrast">
                                   <template #activator="{ props }">
                                      <v-btn
                                        v-if="isReadyForProductionFlow(activeItem)"
                                        v-bind="props"
                                        icon
                                        variant="text"
                                        :color="activeItem.is_op_generated ? 'success' : 'grey-lighten-1'"
                                        @click.stop="toggleOpGenerated(activeItem)"
                                      >
                                         <v-icon size="large">{{ activeItem.is_op_generated ? 'mdi-checkbox-marked-circle' : 'mdi-checkbox-blank-circle-outline' }}</v-icon>
                                      </v-btn>
                                   </template>
                                </v-tooltip>

                                <v-tooltip text="Editar Item" location="top" content-class="tooltip-contrast">
                                  <template #activator="{ props }">
                                    <v-btn
                                      v-bind="props"
                                      icon="mdi-pencil"
                                      variant="tonal"
                                      color="info"
                                      @click="toggleEditMode(activeItem)"
                                    ></v-btn>
                                  </template>
                                </v-tooltip>

                                <v-menu location="bottom end">
                                   <template #activator="{ props }">
                                      <v-btn icon="mdi-dots-vertical" variant="text" v-bind="props"></v-btn>
                                   </template>
                                   <v-list density="compact" nav>
                                      <v-list-item prepend-icon="mdi-delete" title="Excluir Item" base-color="error" @click="confirmDeleteItem(activeItem)"></v-list-item>
                                   </v-list>
                                </v-menu>
                            </div>
                         </div>

                         <div class="image-wrapper flex-grow-1 d-flex align-center justify-center pa-6 bg-striped">

                            <v-img
                               v-if="getImagePreview(activeItem)"
                               :key="activeItem.id"
                               :src="getImagePreview(activeItem)"
                               max-height="100%"
                               max-width="100%"
                               contain
                               class="preview-image elevation-6 rounded-lg"
                               @click="openImageModal(getImagePreview(activeItem), activeItem.stamp_ref)"
                            >
                               <template #placeholder>
                                  <div class="d-flex align-center justify-center fill-height bg-grey-lighten-3">
                                     <v-progress-circular indeterminate color="primary"></v-progress-circular>
                                  </div>
                                </template>
                            </v-img>

                            <div v-else class="d-flex flex-column align-center justify-center text-center">
                                <div class="icon-circle-lg mb-3 bg-surface border elevation-1 text-medium-emphasis">
                                    <v-icon size="48">mdi-image-off-outline</v-icon>
                                </div>
                                <div class="text-subtitle-2 font-weight-bold text-medium-emphasis">Imagem não anexada</div>
                                <div class="text-caption text-disabled mb-4">O arquivo pode ter sido perdido no upload.</div>

                                <v-btn
                                    v-if="canEdit"
                                    color="primary"
                                    variant="flat"
                                    prepend-icon="mdi-image-search"
                                    @click="searchForMissingImage(activeItem)"
                                    :loading="isSearchingImage"
                                    class="font-weight-bold pulse-subtle"
                                >
                                    Auto-Recuperar Imagem
                                </v-btn>
                            </div>
                         </div>

                         <div class="pa-3 border-t bg-surface position-relative">

                            <v-progress-linear
                                v-if="isGeneratingPdf"
                                indeterminate
                                color="info"
                                height="4"
                                absolute
                                location="top"
                                style="z-index: 5;"
                            ></v-progress-linear>

                            <div class="d-flex justify-space-between align-center">
                                <div class="text-caption text-medium-emphasis font-weight-bold d-flex align-center gap-2">
                                    <v-icon v-if="isGeneratingPdf" size="small" class="spin">mdi-loading</v-icon>
                                    {{ isGeneratingPdf ? 'Gerando documento...' : 'Ações Disponíveis' }}
                                </div>

                                <div class="d-flex gap-3">
                                   <v-tooltip v-if="!isLeaderOrRightHand && requiresApproval && activeItem.design_tag !== 'Aprovação Líder' && activeItem.design_tag !== 'Aprovado'" text="Enviar p/ Avaliação do Líder" location="top" content-class="tooltip-contrast">
                                      <template #activator="{ props }">
                                         <v-btn
                                           v-bind="props"
                                           icon
                                           variant="tonal"
                                           color="deep-purple-accent-4"
                                           @click="sendToLeaderApproval(activeItem)"
                                           :disabled="isItemLocked(activeItem.status) || isGeneratingPdf"
                                         >
                                            <v-icon>mdi-account-eye</v-icon>
                                         </v-btn>
                                      </template>
                                   </v-tooltip>

                                   <v-tooltip v-if="(!requiresApproval || activeItem.design_tag === 'Aprovado') && !isLeaderOrRightHand" :text="activeItem.status === 'customer_approval' ? 'Reenviar Aprovação' : 'Enviar p/ Aprovação (Vendedor)'" location="top" content-class="tooltip-contrast">
                                      <template #activator="{ props }">
                                         <v-btn
                                           v-bind="props"
                                           icon
                                           variant="tonal"
                                           color="primary"
                                           @click="emit('sendToSeller', activeItem)"
                                           :disabled="isItemLocked(activeItem.status) || isGeneratingPdf"
                                         >
                                            <v-icon>mdi-send</v-icon>
                                         </v-btn>
                                      </template>
                                   </v-tooltip>

                                   <v-tooltip v-if="isLeaderOrRightHand" :text="activeItem.design_tag === 'Aprovação Líder' ? 'Aprovar Arte e Enviar Vendedor' : (activeItem.status === 'customer_approval' ? 'Reenviar Aprovação' : 'Enviar p/ Aprovação (Vendedor)')" location="top" content-class="tooltip-contrast">
                                      <template #activator="{ props }">
                                         <v-btn
                                           v-bind="props"
                                           icon
                                           variant="tonal"
                                           :color="activeItem.design_tag === 'Aprovação Líder' ? 'success' : 'primary'"
                                           @click="emit('sendToSeller', activeItem)"
                                           :disabled="isItemLocked(activeItem.status) || isGeneratingPdf"
                                         >
                                            <v-icon>{{ activeItem.design_tag === 'Aprovação Líder' ? 'mdi-check-decagram' : 'mdi-send' }}</v-icon>
                                         </v-btn>
                                      </template>
                                   </v-tooltip>

                                   <v-tooltip :text="activeItem.is_op_generated ? 'Reimprimir OP' : 'Gerar OP (Obrigatório)'" location="top" content-class="tooltip-contrast">
                                      <template #activator="{ props }">
                                         <v-btn
                                           v-bind="props"
                                           icon
                                           variant="tonal"
                                           :color="activeItem.is_op_generated ? 'info' : 'warning'"
                                           @click="generateOpPdf(activeItem)"
                                           :disabled="isGeneratingPdf"
                                           :class="{'pulse-btn': !activeItem.is_op_generated && isReadyForPCPRelease(activeItem)}"
                                         >
                                            <v-icon>{{ activeItem.is_op_generated ? 'mdi-printer-check' : 'mdi-printer-alert' }}</v-icon>
                                         </v-btn>
                                      </template>
                                   </v-tooltip>

                                   <v-tooltip :text="getReleaseButtonLabel(activeItem)" location="top" content-class="tooltip-contrast">
                                      <template #activator="{ props }">
                                         <v-btn
                                           v-bind="props"
                                           icon
                                           variant="flat"
                                           color="indigo-darken-3"
                                           @click="directReleaseToPCP(activeItem)"
                                           :loading="isSaving[activeItem.id]"
                                           :disabled="isItemLocked(activeItem.status) || !activeItem.is_op_generated || isGeneratingPdf || !isReadyForPCPRelease(activeItem)"
                                         >
                                            <v-icon>mdi-rocket-launch</v-icon>
                                         </v-btn>
                                      </template>
                                   </v-tooltip>

                                </div>
                            </div>
                         </div>
                      </v-card>
                   </div>

                   <div class="flipper-face face-back">
                      <v-card class="item-card h-100 d-flex flex-column elevation-4">
                         <div class="pa-4 border-b d-flex align-center bg-info-subtle text-info-darken-4">
                            <v-icon start color="inherit">mdi-pencil-box-outline</v-icon>
                            <h3 class="text-h6 font-weight-bold">Editar Item</h3>
                            <v-spacer></v-spacer>
                            <v-btn icon="mdi-close" variant="text" @click="toggleEditMode(activeItem)"></v-btn>
                         </div>

                         <div class="pa-6 flex-grow-1 overflow-y-auto">
                            <v-row dense>
                               <v-col cols="12">
                                  <v-text-field
                                    v-model="activeItem.stamp_ref"
                                    label="Nome da Referência"
                                    variant="outlined"
                                    density="comfortable"
                                    :readonly="!canEdit"
                                    prepend-inner-icon="mdi-tag-text-outline"
                                  ></v-text-field>
                               </v-col>
                               <v-col cols="12" sm="6">
                                  <v-autocomplete
                                    v-model="activeItem.fabric_type"
                                    :items="gestaoClickProducts"
                                    item-title="nome"
                                    item-value="nome"
                                    label="Base / Tecido"
                                    variant="outlined"
                                    density="comfortable"
                                    :readonly="!isAdmin"
                                  ></v-autocomplete>
                               </v-col>
                               <v-col cols="12" sm="6">
                                  <v-text-field
                                    v-model.number="activeItem.quantity_meters"
                                    label="Metragem (m)"
                                    type="number"
                                    variant="outlined"
                                    density="comfortable"
                                    :readonly="!isAdmin"
                                    suffix="m"
                                  ></v-text-field>
                               </v-col>
                               <v-col cols="12">
                                  <v-textarea
                                    v-model="activeItem.notes"
                                    label="Observações Técnicas"
                                    rows="4"
                                    variant="outlined"
                                    density="comfortable"
                                    auto-grow
                                    :readonly="!isAdmin"
                                  ></v-textarea>
                               </v-col>
                               <v-col cols="12">
                                  <v-file-input
                                    label="Substituir Imagem"
                                    prepend-icon="mdi-camera"
                                    variant="outlined"
                                    density="comfortable"
                                    @change="(e) => handleFileChange(e, activeItem)"
                                    accept="image/*"
                                    show-size
                                  ></v-file-input>
                               </v-col>
                            </v-row>
                         </div>

                         <div class="pa-4 border-t d-flex justify-end gap-3 bg-surface">
                            <v-btn variant="text" color="grey" @click="toggleEditMode(activeItem)">Cancelar</v-btn>
                            <v-btn color="success" variant="flat" width="150" @click="saveItem(activeItem)" :loading="isSaving[activeItem.id]">Salvar</v-btn>
                         </div>
                      </v-card>
                   </div>
                </div>
            </div>
         </div>

      </div>
    </v-card>
  </v-dialog>

  <VariationConfirmationModal
    :show="showVariationModal"
    :new-item-name="itemToProcess?.stamp_ref || ''"
    @decision="handleVariationDecision"
  />

  <ImageModal
    :show="showImageModal"
    :image-url="selectedImageUrl"
    :file-name="selectedImageName"
    @close="showImageModal = false"
  />

  <v-dialog v-model="showRecoveryModal" max-width="800" persistent>
      <v-card class="rounded-xl overflow-hidden" :class="themeStore.currentMode === 'light' ? 'bg-white' : 'glass-mode'">
          <div class="pa-4 border-b d-flex align-center justify-space-between bg-primary-lighten-5 text-primary-darken-3">
              <div class="d-flex align-center gap-3">
                  <v-icon>mdi-image-search</v-icon>
                  <div>
                      <div class="text-subtitle-1 font-weight-bold">Recuperação de Imagem</div>
                      <div class="text-caption">Busca por: <strong>"{{ recoverySearchTerm }}"</strong></div>
                  </div>
              </div>
              <v-btn icon variant="text" @click="showRecoveryModal = false"><v-icon>mdi-close</v-icon></v-btn>
          </div>

          <div class="pa-4 bg-surface-variant-light" style="max-height: 500px; overflow-y: auto;">
              <v-alert type="info" variant="tonal" density="compact" class="mb-4 text-caption border-radius-sm">
                  Encontramos as seguintes imagens no banco de estampas com nome similar. Clique na correta para vincular ao pedido.
              </v-alert>

              <v-row dense>
                  <v-col v-for="match in recoveryMatches" :key="match.id" cols="6" sm="4" md="3">
                      <v-card
                          class="cursor-pointer hover-elevation border transition-all"
                          @click="applyRecoveredImage(match)"
                          elevation="0"
                      >
                          <v-img :src="match.image_url" aspect-ratio="1" cover class="bg-grey-lighten-2">
                              <template #placeholder><v-progress-circular indeterminate size="20" color="primary"></v-progress-circular></template>
                          </v-img>
                          <div class="pa-2 text-caption text-truncate font-weight-bold text-center">
                              {{ match.name }}
                          </div>
                      </v-card>
                  </v-col>
              </v-row>

              <div v-if="recoveryMatches.length === 0" class="text-center pa-8 opacity-60">
                  <v-icon size="40" class="mb-2">mdi-file-find-outline</v-icon>
                  <div>Nenhuma imagem encontrada com esse nome.</div>
              </div>
          </div>
      </v-card>
  </v-dialog>

  <v-snackbar v-model="snackbar.show" :color="snackbar.color" :timeout="4000" location="top right">
    {{ snackbar.text }}
  </v-snackbar>
</template>

<script setup lang="ts">
import { computed, ref, watch, reactive, nextTick, onMounted } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import ImageModal from './ImageModal.vue';
import { gestaoApi } from '@/api/gestaoClick';
import VariationConfirmationModal from './design/VariationConfirmationModal.vue';
import { format, addDays, parseISO, differenceInCalendarDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const props = defineProps({
  show: Boolean,
  orderId: String,
  itemId: String,
});
const emit = defineEmits(['close', 'sendToSeller', 'releaseItem', 'itemUpdated']);

const userStore = useUserStore();
const themeStore = useThemeStore();

type OrderItemEditable = {
    id: string; stamp_ref: string; fabric_type: string; quantity_meters: number; notes: string | null; stamp_image_url: string;
    status: string; design_tag: string; is_op_generated: boolean; isEditMode: boolean; new_stamp_file?: File | null; local_image_preview?: string | null; [key: string]: any;
};

const activeItemId = ref<string | null>(null);

const order = ref<any | null>(null);
const loading = ref(false);
const editableItems = ref<OrderItemEditable[]>([]);
const isSaving = ref<Record<string, boolean>>({});
const snackbar = reactive({ show: false, text: '', color: '' });
const gestaoClickProducts = ref<{ id: string; nome: string; }[]>([]);
const showVariationModal = ref(false);
const itemToProcess = ref<OrderItemEditable | null>(null);
const originalItemState = ref<OrderItemEditable | null>(null);
const showImageModal = ref(false);
const selectedImageUrl = ref<string | undefined>('');
const selectedImageName = ref<string | undefined>('');

const isSearchingImage = ref(false);
const showRecoveryModal = ref(false);
const recoveryMatches = ref<any[]>([]);
const recoverySearchTerm = ref('');
const isGeneratingPdf = ref(false);

// --- PERMISSÕES DE DESIGN ---
const currentUserPerms = ref({ is_leader: false, requires_leader_approval: false, can_approve_for_leader: false });
const isLeaderOrRightHand = computed(() => currentUserPerms.value.is_leader || currentUserPerms.value.can_approve_for_leader);
const requiresApproval = computed(() => currentUserPerms.value.requires_leader_approval);

const fetchUserPerms = async () => {
    if (!userStore.profile?.id) return;
    const { data } = await supabase.from('design_user_permissions').select('*').eq('user_id', userStore.profile.id).maybeSingle();
    if (data) currentUserPerms.value = data;
};

const activeItem = computed(() => activeItemId.value ? editableItems.value.find(i => i.id === activeItemId.value) : null);
const currentItemIndex = computed(() => activeItem.value ? editableItems.value.findIndex(i => i.id === activeItem.value!.id) : -1);
const hasNextItem = computed(() => currentItemIndex.value < editableItems.value.length - 1);
const hasPreviousItem = computed(() => currentItemIndex.value > 0);

const isAdmin = computed(() => ['admin', 'super_admin'].includes(userStore.profile?.role || ''));
const isDesigner = computed(() => userStore.profile?.role === 'designer');
const canEdit = computed(() => isAdmin.value || isDesigner.value);

const getTagColor = (tag: string) => {
    const tagLower = (tag || '').toLowerCase();
    if (tagLower.includes('alteração')) return '#ffab40';
    if (tagLower.includes('finalização')) return '#26A69A';
    if (tagLower.includes('desenvolvimento')) return '#40c4ff';
    if (tagLower.includes('aprovação') || tagLower.includes('lider')) return '#AB47BC';
    if (tagLower.includes('aprovado')) return '#4CAF50';
    return '#607D8B';
};

const statusColor = (status: string) => {
    if (status === 'design_released') return 'purple';
    if (status === 'approved_by_seller') return 'success';
    if (status === 'customer_approval') return 'warning';
    return 'grey';
};
const formatStatus = (status: string) => {
    const map: Record<string, string> = {
        'design_pending': 'Em Design',
        'customer_approval': 'Aprovação',
        'approved_by_seller': 'Aprovado',
        'production_queue': 'Produção',
        'design_released': 'Enviado PCP',
        'waiting_print': 'Fila Impressão',
        'printing': 'Imprimindo',
        'printed': 'Impresso',
        'in_production': 'Em Acabamento',
        'completed': 'Expedido'
    };
    return map[status] || status;
};

const getImagePreview = (item: OrderItemEditable) => {
    return item.local_image_preview || item.stamp_image_url;
};

const selectItem = (id: string) => { activeItemId.value = id; };
const selectNextItem = () => { if (hasNextItem.value) activeItemId.value = editableItems.value[currentItemIndex.value + 1].id; };
const selectPreviousItem = () => { if (hasPreviousItem.value) activeItemId.value = editableItems.value[currentItemIndex.value - 1].id; };

const searchForMissingImage = async (item: OrderItemEditable) => {
    isSearchingImage.value = true;
    recoverySearchTerm.value = item.stamp_ref;
    try {
        const { data, error } = await supabase.from('stamp_library').select('*').ilike('name', `%${item.stamp_ref.trim()}%`).limit(20);
        if (error) throw error;
        recoveryMatches.value = data || [];
        showRecoveryModal.value = true;
        if (recoveryMatches.value.length === 0) showSnackbar('Nenhuma imagem encontrada com esse nome no catálogo.', 'warning');
    } catch (e) { console.error(e); showSnackbar('Erro ao buscar imagem.', 'error'); } finally { isSearchingImage.value = false; }
};

const applyRecoveredImage = async (match: any) => {
    if (!activeItem.value || !confirm(`Confirma vincular a imagem "${match.name}" a este item?`)) return;
    try {
        const { error } = await supabase.from('order_items').update({ stamp_image_url: match.image_url }).eq('id', activeItem.value.id);
        if (error) throw error;
        activeItem.value.stamp_image_url = match.image_url;
        showRecoveryModal.value = false;
        showSnackbar('Imagem recuperada com sucesso!', 'success');
        emit('itemUpdated');
    } catch (e) { console.error(e); showSnackbar('Erro ao atualizar item.', 'error'); }
};

const fetchOrderDetails = async (id: string) => {
  if (!id) return;
  loading.value = true;
  try {
    const { data, error } = await supabase.from('orders').select('*, created_by:profiles!created_by(full_name), order_items(*)').eq('id', id).single();
    if (error) throw error;
    order.value = data;
    editableItems.value = (data.order_items || []).sort((a: any, b: any) => a.stamp_ref.localeCompare(b.stamp_ref)).map((item: any) => ({ ...item, isEditMode: false }));
    if (!activeItemId.value || !editableItems.value.find(i => i.id === activeItemId.value)) {
       activeItemId.value = props.itemId || editableItems.value[0]?.id || null;
    }
  } catch (err) { showSnackbar('Erro ao carregar pedido.', 'error'); } finally { loading.value = false; }
};

const fetchGestaoData = async () => {
    try {
       const products = await gestaoApi.buscarProdutos();
       gestaoClickProducts.value = products.map(p => ({ id: p.id, nome: p.nome }));
    } catch (e) { console.error(e); }
};

// --- LÓGICA DE APROVAÇÃO (NOVO FLUXO) ---
const sendToLeaderApproval = async (item: OrderItemEditable) => {
    if (!confirm("Enviar esta arte para avaliação do líder?")) return;
    isSaving.value[item.id] = true;
    try {
        const tagLider = 'Aprovação Líder';
        await supabase.from('order_items').update({ design_tag: tagLider }).eq('id', item.id);
        item.design_tag = tagLider;
        showSnackbar('Enviado para avaliação do líder!', 'success');
        emit('itemUpdated');
    } catch (error: any) {
        console.error(error);
        showSnackbar('Erro ao enviar: ' + error.message, 'error');
    } finally {
        isSaving.value[item.id] = false;
    }
};

// --- LÓGICA DE LIBERAÇÃO PARA PCP ---
const isReadyForPCPRelease = (item: any) => {
    if (item.status === 'approved_by_seller') return true;
    if (canEdit.value && ['Finalização', 'Aprovado'].includes(item.design_tag)) return true;
    return false;
};

const isReadyForProductionFlow = (item: any) => {
    if (!item) return false;
    return ['approved_by_seller', 'production_queue', 'design_released', 'waiting_print', 'printing', 'printed', 'in_production', 'completed'].includes(item.status) ||
           (item.status === 'design_pending' && ['Aprovado', 'Finalização'].includes(item.design_tag));
};

const directReleaseToPCP = async (item: OrderItemEditable) => {
    const isApprovedFlow = item.status === 'approved_by_seller';
    const isDirectFlow = canEdit.value && !requiresApproval.value && ['Finalização', 'Aprovado'].includes(item.design_tag);

    if (!isApprovedFlow && !isDirectFlow) {
         if (requiresApproval.value && item.status !== 'approved_by_seller') {
             alert("Você não tem permissão para liberar direto ao PCP. Envie para o Líder ou aguarde aprovação do vendedor.");
         } else if (item.design_tag === 'Alteração') {
             alert("Itens em 'Alteração' exigem aprovação do cliente/vendedor antes de ir ao PCP.");
         } else {
             alert("O item precisa estar Aprovado pelo Vendedor ou em Finalização/Aprovado no Design para ser liberado.");
         }
         return;
    }

    if(!item.is_op_generated) {
        alert("Bloqueio de PCP: É OBRIGATÓRIO gerar a OP (PDF) antes de enviar para a produção.");
        return;
    }

    if(!confirm(`Confirma enviar "${item.stamp_ref}" para a fila do PCP?`)) return;

    isSaving.value[item.id] = true;
    try {
        const { error } = await supabase
            .from('order_items')
            .update({ status: 'design_released' })
            .eq('id', item.id);

        if (error) throw error;

        if (order.value && ['design_pending', 'customer_approval'].includes(order.value.status)) {
             await supabase
                .from('orders')
                .update({ status: 'in_production' })
                .eq('id', order.value.id);
        }

        await supabase.from('production_logs').insert({
            order_item_id: item.id,
            user_id: userStore.user?.id,
            action: 'sent_to_pcp',
            metadata: { from: 'launch_detail_modal', previous_status: item.status, method: isDirectFlow ? 'direct_by_design' : 'standard_approval' }
        });

        item.status = 'design_released';
        showSnackbar('Item enviado para o Controle de Produção!', 'success');
        emit('itemUpdated');

    } catch (e: any) {
        console.error("Erro na liberação:", e);
        showSnackbar('Erro ao liberar: ' + e.message, 'error');
    } finally {
        isSaving.value[item.id] = false;
    }
};

const toggleEditMode = (item: OrderItemEditable) => {
  item.isEditMode = !item.isEditMode;
  if (item.isEditMode) originalItemState.value = { ...item };
  else if (originalItemState.value) { Object.assign(item, originalItemState.value); originalItemState.value = null; }
};

const handleFileChange = (event: Event, item: OrderItemEditable) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (file) { item.new_stamp_file = file; item.local_image_preview = URL.createObjectURL(file); }
};

const saveItem = (item: OrderItemEditable) => {
    if (!canEdit.value) return;
    const refChanged = item.stamp_ref !== originalItemState.value?.stamp_ref;
    if (refChanged) { itemToProcess.value = item; showVariationModal.value = true; }
    else proceedWithSave(item, 'update_only');
};

const handleVariationDecision = async (decision: any) => {
    if(!itemToProcess.value) return;
    await proceedWithSave(itemToProcess.value, decision);
    showVariationModal.value = false;
}

const proceedWithSave = async (item: OrderItemEditable, decision?: string) => {
    isSaving.value[item.id] = true;
    try {
        let imageUrl = item.stamp_image_url;
        if (item.new_stamp_file) {
             const filePath = `${order.value.id}/${item.id}/${Date.now()}-${item.new_stamp_file.name}`;
             await supabase.storage.from('arts').upload(filePath, item.new_stamp_file, { upsert: true });
             imageUrl = supabase.storage.from('arts').getPublicUrl(filePath).data.publicUrl;
        }
        const payload = { stamp_ref: item.stamp_ref, fabric_type: item.fabric_type, quantity_meters: item.quantity_meters, notes: item.notes, stamp_image_url: imageUrl };
        await supabase.from('order_items').update(payload).eq('id', item.id);
        Object.assign(item, payload);
        showSnackbar('Salvo com sucesso!', 'success');
        emit('itemUpdated');
        item.isEditMode = false;
    } catch(e: any) { showSnackbar(e.message, 'error'); } finally { isSaving.value[item.id] = false; }
};

const confirmDeleteItem = (item: OrderItemEditable) => { if(confirm('Excluir este item?')) deleteItem(item); };
const deleteItem = async (item: OrderItemEditable) => {
    try {
        await supabase.from('order_items').delete().eq('id', item.id);
        editableItems.value = editableItems.value.filter(i => i.id !== item.id);
        showSnackbar('Item excluído.', 'success');
        emit('itemUpdated');
        if(editableItems.value.length === 0) emit('close');
        else if(activeItemId.value === item.id) activeItemId.value = editableItems.value[0].id;
    } catch(e) { showSnackbar('Erro ao excluir.', 'error'); }
};

const toggleOpGenerated = async (item: OrderItemEditable) => {
    const oldVal = item.is_op_generated;
    item.is_op_generated = !oldVal;
    try {
        await supabase.from('order_items').update({ is_op_generated: item.is_op_generated }).eq('id', item.id);
        showSnackbar(`OP ${item.is_op_generated ? 'Liberada' : 'Revogada'}`, 'info');
        emit('itemUpdated');
    } catch { item.is_op_generated = oldVal; showSnackbar('Erro ao atualizar OP', 'error'); }
};

const isItemLocked = (s: string) => ['production_queue', 'design_released', 'waiting_print', 'printing', 'printed', 'in_production', 'completed'].includes(s);

const getReleaseButtonLabel = (item: any) => {
    if (isItemLocked(item.status)) return 'Já Enviado ao PCP';
    if (!item.is_op_generated) return 'Gerar OP Primeiro';
    if (item.status === 'approved_by_seller') return 'Liberar para PCP';
    if (canEdit.value && !requiresApproval.value && ['Finalização', 'Aprovado'].includes(item.design_tag)) return 'Liberar (Direto)';
    return 'Aguardando Aprovação';
}

const showSnackbar = (text: string, color: string) => { snackbar.text = text; snackbar.color = color; snackbar.show = true; };
const openImageModal = (url: any, name: any) => { selectedImageUrl.value = url; selectedImageName.value = name; showImageModal.value = true; };

// --- PDF GENERATION LOGIC ---
const addBusinessDays = (startDate: Date, days: number): Date => {
  const newDate = new Date(startDate);
  let addedDays = 0;
  while (addedDays < days) {
    newDate.setDate(newDate.getDate() + 1);
    if (newDate.getDay() !== 0) addedDays++;
  }
  return newDate;
};
const getNextDeliveryDay = (date: Date): Date => {
    const newDate = new Date(date);
    newDate.setDate(newDate.getDate() + 1);
    while (true) {
        const dayOfWeek = newDate.getDay();
        if ([2, 4, 6].includes(dayOfWeek)) return newDate;
        newDate.setDate(newDate.getDate() + 1);
    }
};
const imageToBase64 = (url: string): Promise<string> => {
  return new Promise((resolve, reject) => {
    if (!url) {
      return reject(new Error("URL da imagem está vazia."));
    }

    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext('2d');
      if(ctx) {
        ctx.drawImage(img, 0, 0);
        resolve(canvas.toDataURL('image/png'));
      } else {
        reject(new Error("Falha no renderizador de imagem (Canvas)."));
      }
    };

    img.onerror = () => {
      reject(new Error("A URL da arte não pôde ser carregada (Link quebrado ou bloqueado por CORS)."));
    };

    img.src = url;
  });
};

const generateOpPdf = async (item: any) => {

  if (!item.stamp_image_url) {
      alert("ERRO: A arte é OBRIGATÓRIA para gerar a OP. Por favor, anexe ou recupere a imagem primeiro.");
      return;
  }

  isGeneratingPdf.value = true;
  try {
    const { data: opNumber, error: rpcError } = await supabase.rpc('generate_op_number', { p_item_id: item.id });
    if(rpcError) throw rpcError;

    const { data: schedule } = await supabase.from('production_schedule').select('scheduled_date').eq('order_item_id', item.id).maybeSingle();
    const scheduleDate = (schedule && schedule.scheduled_date) ? parseISO(schedule.scheduled_date) : new Date();

    const parentOrder = order.value;
    const hasStockIssues = (parentOrder.order_items || []).some((i: any) => i.has_insufficient_stock || i.status === 'pending_stock');
    const completionDate = addBusinessDays(scheduleDate, 3 + (hasStockIssues ? 2 : 0));
    const forecastDate = getNextDeliveryDay(completionDate);

    const formattedOpNumber = String(opNumber).padStart(4, '0');
    const formattedOrderNumber = String(parentOrder.order_number).padStart(4, '0');
    const formattedForecastDate = format(forecastDate, 'dd/MM/yyyy', { locale: ptBR });

    const doc = new jsPDF();
    const [logoBase64, artBase64] = await Promise.all([
        imageToBase64('https://cdn.shopify.com/s/files/1/0661/4574/6991/files/Sem_nome_1080_x_800_px_1080_x_500_px_1080_x_400_px_1000_x_380_px_da020cf2-2bb9-4dac-8dd3-4548cfd2e5ae.png?v=1756811713'),
        imageToBase64(item.stamp_image_url || '')
    ]);

    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;

    const drawCommonHeader = () => {
        const logoProps = doc.getImageProperties(logoBase64);
        const logoWidth = 50;
        const logoHeight = (logoProps.height * logoWidth) / logoProps.width;
        doc.addImage(logoBase64, "PNG", 15, 12, logoWidth, logoHeight);
        doc.setFontSize(9).setTextColor(100);
        doc.text([ "MR JACKY - 20.631.721/0001-07", "RUA LUIZ MONTANHAN, 1302 TIRO DE GUERRA - TIETE - SP CEP: 18.532-000", "Fone/Celular: (15) 99847-8789 | E-mail: mrjackyfinanceiro@gmail.com" ], pageWidth - 15, 15, { align: "right" });
    };

    drawCommonHeader();
    doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(0, 0, 0);
    doc.text("VIA DA PRODUÇÃO", pageWidth / 2, 40, { align: "center" });
    doc.setFontSize(18).setTextColor(0);
    doc.text(`OP #${formattedOpNumber}`, 15, 45);
    doc.setFontSize(12);
    doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
    doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

    autoTable(doc, {
        startY: 55,
        head: [["CLIENTE", "VENDEDOR", "EMISSÃO", "PREVISÃO DE ENTREGA"]],
        body: [[ parentOrder.customer_name, parentOrder.created_by?.full_name || parentOrder.creator_name || "N/A", format(new Date(parentOrder.created_at), "dd/MM/yyyy", { locale: ptBR }), formattedForecastDate ]],
        theme: "striped", headStyles: { fillColor: [41, 128, 185] },
    });

    autoTable(doc, {
        startY: (doc as any).lastAutoTable.finalY + 10,
        head: [["PRODUTO (BASE)", "SERVIÇO (ESTAMPA)", "QUANTIDADE"]],
        body: [[ item.fabric_type, item.stamp_ref, `${Number(item.quantity_meters).toLocaleString('pt-BR')}m` ]],
        theme: "grid", headStyles: { fillColor: [41, 128, 185] },
    });

    let currentY = (doc as any).lastAutoTable.finalY + 10;

    const notesContent = String(parentOrder.notes || parentOrder.details?.observation || "").trim();
    if (notesContent) {
        doc.setFillColor(255, 243, 224);
        doc.setDrawColor(255, 183, 77);
        doc.setLineWidth(0.3);
        doc.setFont("helvetica", "normal");
        doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34);
        const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(15, currentY, pageWidth - 30, notesHeight, "FD");
        doc.setFont("helvetica", "bold");
        doc.setTextColor(230, 81, 0);
        doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY + 5);
        doc.setFont("helvetica", "normal");
        doc.setTextColor(0);
        doc.text(splitNotes, 17, currentY + 10);
        currentY += notesHeight + 10;
    } else {
        currentY += 5;
    }

    const artStartY = currentY;
    doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0).text("ARTE APROVADA", 15, artStartY);
    doc.setFontSize(10).setFont('helvetica', 'normal').setTextColor(100).text(`Cliente: ${parentOrder.customer_name}`, 15, artStartY + 5);

    const artY = artStartY + 10;
    const maxImgWidth = pageWidth - 30; const maxImgHeight = pageHeight - artY - 25;
    const imgProps = doc.getImageProperties(artBase64);
    const ratio = Math.min( maxImgWidth / imgProps.width, maxImgHeight / imgProps.height );
    const imgWidth = imgProps.width * ratio; const imgHeight = imgProps.height * ratio;
    const imgXCentered = (pageWidth - imgWidth) / 2;

    doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artY - 1, imgWidth + 2, imgHeight + 2, "S");
    doc.addImage(artBase64, "PNG", imgXCentered, artY, imgWidth, imgHeight);
    doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center" });

    doc.addPage();
    drawCommonHeader();
    doc.setFontSize(18).setTextColor(0);
    doc.text(`OP #${formattedOpNumber}`, 15, 45);
    doc.setFontSize(10).setFont('helvetica', 'bold').setTextColor(150, 0, 0);
    doc.text("VIA PARA ARQUIVAMENTO", pageWidth / 2, 40, { align: "center" });
    doc.setTextColor(0);
    doc.setFontSize(12);
    doc.text(`Pedido #${formattedOrderNumber}`, pageWidth - 15, 45, { align: "right" });
    doc.setLineWidth(0.5).line(15, 50, pageWidth - 15, 50);

    autoTable(doc, {
        startY: 55,
        theme: "grid",
        headStyles: { fillColor: [41, 128, 185] },
        head: [['CLIENTE', 'REFERÊNCIA (ESTAMPA)', 'PRODUTO (BASE)']],
        body: [[parentOrder.customer_name, item.stamp_ref, item.fabric_type]],
    });

    let currentY2 = (doc as any).lastAutoTable.finalY + 10;

    if (notesContent) {
        doc.setFillColor(255, 243, 224);
        doc.setDrawColor(255, 183, 77);
        doc.setLineWidth(0.3);
        doc.setFont("helvetica", "normal");
        doc.setFontSize(8.5);
        const splitNotes = doc.splitTextToSize(notesContent, pageWidth - 34);
        const notesHeight = (splitNotes.length * 4) + 8;
        doc.rect(15, currentY2, pageWidth - 30, notesHeight, "FD");
        doc.setFont("helvetica", "bold");
        doc.setTextColor(230, 81, 0);
        doc.text("OBSERVAÇÕES DO VENDEDOR / PEDIDO:", 17, currentY2 + 5);
        doc.setFont("helvetica", "normal");
        doc.setTextColor(0);
        doc.text(splitNotes, 17, currentY2 + 10);
        currentY2 += notesHeight + 10;
    } else {
        currentY2 += 5;
    }

    const artStartY2 = currentY2;
    doc.setFontSize(12).setFont("helvetica", "bold").setTextColor(0).text("ARTE APROVADA", 15, artStartY2);
    doc.setDrawColor(180, 180, 180).setLineWidth(0.5).rect(imgXCentered - 1, artStartY2 + 5 - 1, imgWidth + 2, imgHeight + 2, "S");
    doc.addImage(artBase64, "PNG", imgXCentered, artStartY2 + 5, imgWidth, imgHeight);
    doc.setFontSize(9).setTextColor(150).text("OP gerada com MJProcess", pageWidth / 2, pageHeight - 15, { align: "center" });

    doc.save(`OP-${formattedOpNumber}.pdf`);

    if(item.original) item.original.is_op_generated = true;
    else item.is_op_generated = true;

    await supabase.from('order_items').update({ is_op_generated: true }).eq('id', item.id);
    emit('itemUpdated');

  } catch (error: any) {
      console.error("Erro PDF:", error);
      alert("Erro ao gerar PDF: " + error.message);
  } finally {
      isGeneratingPdf.value = false;
  }
};

watch(() => props.show, (val) => {
    if(val) {
        fetchGestaoData();
        fetchUserPerms();
        if(props.itemId) activeItemId.value = props.itemId;
    }
});

watch(() => props.orderId, (id) => { if(id && props.show) fetchOrderDetails(id); });
</script>

<style scoped lang="scss">
/* --- ESTRUTURA GERAL --- */
.launch-detail-modal { overflow: hidden; }
.modal-root { display: flex; flex-direction: column; height: 100%; }
.content-body { height: calc(100% - 64px); overflow: hidden; }
.loading-container { height: 400px; display: flex; flex-direction: column; align-items: center; justify-content: center; }

/* --- SIDEBAR --- */
.width-sidebar { width: 320px; flex-shrink: 0; display: flex; flex-direction: column; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; .full-width { grid-column: 1 / -1; } }
.info-item { display: flex; flex-direction: column; .label { font-size: 0.7rem; text-transform: uppercase; color: rgba(var(--v-theme-on-surface), 0.5); font-weight: 600; } .value { font-size: 0.9rem; font-weight: 500; } }
.flex-1 { flex: 1; }

/* --- CSS DOS ÍCONES 3D --- */
.icon-3d {
    background: linear-gradient(135deg, rgba(25, 118, 210, 0.1) 0%, rgba(25, 118, 210, 0.3) 100%);
    border: 1px solid rgba(25, 118, 210, 0.2);
    box-shadow: inset 0 2px 4px rgba(255, 255, 255, 0.5), 0 2px 5px rgba(0,0,0,0.1);
}

/* --- FLIPPER --- */
.flipper-container { width: 100%; height: 100%; padding: 1rem; }
.card-flipper { width: 100%; max-width: 650px; height: 100%; max-height: 850px; position: relative; transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1); transform-style: preserve-3d; &.is-flipped { transform: rotateY(180deg); } }
.flipper-face { position: absolute; width: 100%; height: 100%; backface-visibility: hidden; &.face-back { transform: rotateY(180deg); } }

/* --- IMAGEM --- */
.image-wrapper { position: relative; overflow: hidden; &.bg-striped { background: repeating-linear-gradient(45deg, rgba(var(--v-theme-on-surface), 0.03), rgba(var(--v-theme-on-surface), 0.03) 10px, rgba(var(--v-theme-on-surface), 0.05) 10px, rgba(var(--v-theme-on-surface), 0.05) 20px); } }
.preview-image { cursor: pointer; transition: transform 0.3s ease; &:hover { transform: scale(1.02); } }
.icon-circle-lg { width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.pulse-subtle { animation: pulse 2s infinite; }
@keyframes pulse { 0% { transform: scale(1); } 50% { transform: scale(1.02); } 100% { transform: scale(1); } }
.hover-elevation:hover { transform: translateY(-4px); box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important; }

/* --- TEMAS --- */
:global(.tooltip-contrast) { background-color: rgba(40, 40, 40, 0.95) !important; color: #ffffff !important; font-size: 0.75rem !important; border: 1px solid rgba(255, 255, 255, 0.1); }

.light-mode { background-color: #F8F9FA !important; color: rgba(0,0,0,0.87); .modal-header { background-color: #FFFFFF; border-bottom: 1px solid #E0E0E0; } .meta-divider { border-right: 1px solid #E0E0E0; height: 16px; } .item-card { background-color: #FFFFFF; border: 1px solid #E0E0E0; box-shadow: 0 4px 12px rgba(0,0,0,0.08); border-radius: 12px; } .sidebar-area { background-color: #FFFFFF; border-right: 1px solid #E0E0E0; } .bg-stage { background-color: #F8F9FA; } .nav-item.v-list-item--active { background-color: #E3F2FD !important; color: #1976D2; border-left: 3px solid #1976D2; } .bg-surface-variant-light { background-color: #F5F5F5 !important; } }

.glass-mode {
    background-color: rgba(30, 30, 35, 0.85) !important; backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.1); color: #FFFFFF;
    .modal-header { background-color: rgba(255, 255, 255, 0.03); border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
    .meta-divider { border-right: 1px solid rgba(255, 255, 255, 0.2); height: 16px; }
    .item-card { background-color: rgba(45, 45, 50, 0.6); border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: 0 8px 32px rgba(0,0,0,0.3); border-radius: 16px; }
    .sidebar-area { background-color: rgba(255, 255, 255, 0.02); border-right: 1px solid rgba(255, 255, 255, 0.1); }
    .nav-item.v-list-item--active { background-color: rgba(64, 196, 255, 0.15) !important; color: #40c4ff; border-left: 3px solid #40c4ff; }
    .bg-surface-variant-light { background-color: rgba(255,255,255,0.05) !important; }
    .bg-surface { background-color: rgba(0,0,0,0.1) !important; }
    .icon-3d { background: linear-gradient(135deg, rgba(64, 196, 255, 0.1) 0%, rgba(64, 196, 255, 0.3) 100%); border: 1px solid rgba(64, 196, 255, 0.2); box-shadow: inset 0 2px 4px rgba(255, 255, 255, 0.1), 0 2px 5px rgba(0,0,0,0.3); }
}

.pulse-btn {
    animation: pulse-border 1.5s infinite;
}
@keyframes pulse-border {
    0% { box-shadow: 0 0 0 0 rgba(255, 152, 0, 0.7); }
    70% { box-shadow: 0 0 0 6px rgba(255, 152, 0, 0); }
    100% { box-shadow: 0 0 0 0 rgba(255, 152, 0, 0); }
}
.spin {
    animation: spin 1s linear infinite;
}
@keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
}
</style>
