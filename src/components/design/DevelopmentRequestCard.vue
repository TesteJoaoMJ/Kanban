<template>
  <v-card
    class="dev-card my-2 border-s-4 glass-card-clean"
    :class="[
      isLight ? 'dev-card-light' : 'dev-card-dark',
      isAlteration ? (isLight ? 'dev-card-alt-light' : 'dev-card-alt-dark') : '',
      isDelayed ? 'border-error' : ''
    ]"
    :style="`border-left-color: ${isDelayed ? '#FF5252' : (isAlteration ? '#f57c00' : '#1976D2')} !important; border-left-width: 4px !important;`"
    variant="flat"
    @click="$emit('open', item)"
  >
    <div v-if="!isLight" class="card-shine"></div>

    <div class="card-header d-flex align-center justify-space-between pa-3 border-b" :class="isLight ? 'border-grey-lighten-3' : 'border-white-05'">
      <div class="d-flex align-center gap-2">
          <span class="dev-code" :class="isLight ? (isAlteration ? 'text-orange-darken-4' : 'text-indigo-darken-3') : (isAlteration ? 'text-orange-lighten-2' : 'text-blue-lighten-3')">
            {{ isAlteration ? item.dev_code.replace('DEV', 'ALT') : item.dev_code }}
          </span>
          <v-chip size="x-small" :color="isLight ? (isAlteration ? 'orange-darken-3' : 'indigo') : (isAlteration ? 'orange' : 'primary')" variant="tonal" class="font-weight-bold">
            {{ item.design_items?.length || 0 }} Item(ns)
          </v-chip>
      </div>

      <v-btn icon size="small" variant="text" :color="isLight ? 'grey-darken-2' : 'grey-lighten-1'" @click.stop="openInfoModal" style="width: 24px; height: 24px;">
          <v-icon size="18">mdi-help-circle-outline</v-icon>
      </v-btn>
    </div>

    <v-card-text class="pa-3">
      <div class="d-flex align-center justify-space-between mb-3">
          <div class="d-flex flex-column gap-0">
               <span class="text-[10px] font-weight-bold text-primary d-flex align-center" :title="formatDateFull(item.created_at)">
                   <v-icon size="12" start class="mr-1">mdi-clock-time-four-outline</v-icon>
                   {{ getRelativeTime(item.created_at) }}
               </span>
          </div>
          <div class="font-weight-black text-caption font-mono">
              {{ getTotalMeters(item.design_items).toLocaleString('pt-BR') }}m
          </div>
      </div>

      <div class="d-flex align-center gap-1 mb-3 text-truncate" :title="getCustomerList(item.design_items)">
          <v-icon size="14" :color="isLight ? 'grey-darken-1' : 'grey-lighten-1'">mdi-account-group-outline</v-icon>
          <span class="text-caption font-weight-medium text-truncate" :class="isLight ? 'text-grey-darken-3' : 'text-grey-lighten-2'">
              {{ getCustomerList(item.design_items) }}
          </span>
      </div>

      <div class="pt-2 border-t d-flex align-center justify-space-between" :class="isLight ? 'border-grey-lighten-3' : 'border-white-05'">
          <div class="d-flex align-center gap-2">
              <v-avatar size="24" :color="item.designer_id ? 'primary' : 'grey-lighten-1'" class="shadow-sm">
                  <span class="text-[10px] text-white font-weight-bold">{{ getInitials(getDesignerName(item.designer_id)) }}</span>
              </v-avatar>
              <div class="d-flex flex-column lh-1">
                  <span class="text-[9px] font-weight-black uppercase opacity-60">Responsável</span>
                  <span class="text-[10px] font-weight-bold text-truncate" style="max-width: 90px;" :class="item.designer_id ? '' : 'text-error'">
                      {{ getDesignerName(item.designer_id) || 'Sem Dono' }}
                  </span>
              </div>
          </div>

          <v-menu v-if="isLeaderOrRightHand" location="bottom end">
              <template v-slot:activator="{ props }">
                  <v-btn v-bind="props" size="x-small" variant="tonal" color="deep-purple-darken-1" class="font-weight-bold px-2 text-[10px]" @click.stop>
                      <v-icon start size="12">mdi-account-switch</v-icon> Atribuir
                  </v-btn>
              </template>
              <v-list density="compact" nav>
                  <v-list-item @click="assignCard(null)">
                      <template v-slot:prepend><v-icon size="small" color="grey">mdi-account-off</v-icon></template>
                      <v-list-item-title class="text-caption font-weight-bold">Nenhum (Livre)</v-list-item-title>
                  </v-list-item>
                  <v-divider class="my-1"></v-divider>
                  <v-list-item v-for="member in designTeamMembers" :key="member.user_id" @click="assignCard(member.user_id)">
                      <template v-slot:prepend>
                          <v-avatar size="20" color="primary" class="mr-2"><span class="text-[8px] text-white">{{ getInitials(member.profile?.full_name) }}</span></v-avatar>
                      </template>
                      <v-list-item-title class="text-caption font-weight-bold">{{ member.profile?.full_name }}</v-list-item-title>
                  </v-list-item>
              </v-list>
          </v-menu>

          <v-btn v-else-if="!item.designer_id" size="x-small" variant="tonal" color="success" class="font-weight-bold px-2 text-[10px]" @click.stop="assignCard(userStore.profile?.id)">
               <v-icon start size="12">mdi-hand-back-right</v-icon> Assumir
          </v-btn>
      </div>

      <div class="mt-3 d-flex flex-column gap-2" v-if="isLeaderOrRightHand || item.designer_id === userStore.profile?.id">

          <v-btn
              v-if="!isLeaderOrRightHand && requiresApproval && item.design_tag !== 'Aprovação Líder' && item.design_tag !== 'Aprovado'"
              block
              variant="tonal"
              size="x-small"
              color="deep-purple-accent-4"
              class="font-weight-bold"
              @click.stop="$emit('uploadLeader', item)"
          >
              <v-icon start size="14">mdi-cloud-upload</v-icon>
              Upload / Enviar p/ Líder
          </v-btn>

          <v-btn
              v-if="(!requiresApproval || item.design_tag === 'Aprovado') && !isLeaderOrRightHand"
              block
              variant="flat"
              size="x-small"
              color="primary"
              class="font-weight-bold"
              @click.stop="$emit('uploadCustomer', item)"
          >
              <v-icon start size="14">mdi-send</v-icon>
              Upload / Enviar Vendedor
          </v-btn>

          <v-btn
              v-if="isLeaderOrRightHand && item.design_tag === 'Aprovação Líder'"
              block
              variant="flat"
              size="x-small"
              color="success"
              class="font-weight-bold"
              @click.stop="$emit('approveLeaderReturn', item)"
          >
              <v-icon start size="14">mdi-check-decagram</v-icon>
              Aprovar (Retornar ao Designer)
          </v-btn>

          <v-btn
              v-if="isLeaderOrRightHand && item.design_tag !== 'Aprovação Líder'"
              block
              variant="flat"
              size="x-small"
              color="success"
              class="font-weight-bold"
              @click.stop="$emit('uploadCustomer', item)"
          >
              <v-icon start size="14">mdi-send</v-icon>
              Upload Direto / Enviar Vendedor
          </v-btn>

          <v-btn
              v-if="isLeaderOrRightHand && item.design_tag === 'Aprovação Líder'"
              block
              variant="tonal"
              size="x-small"
              color="error"
              class="font-weight-bold"
              @click.stop="openRejectModal"
          >
              <v-icon start size="14">mdi-close-octagon</v-icon>
              Rejeitar / Solicitar Ajuste
          </v-btn>
      </div>

    </v-card-text>

    <v-dialog v-model="infoModal.show" max-width="650">
        <v-card class="rounded-xl overflow-hidden glass-modal" :class="isLight ? 'bg-white' : 'bg-surface border-white-05'">
            <div class="pa-4 border-b d-flex align-center justify-space-between bg-primary text-white">
                <div class="font-weight-bold d-flex align-center gap-2">
                    <v-icon>mdi-information-outline</v-icon>
                    Raio-X: {{ isAlteration ? item.dev_code.replace('DEV', 'ALT') : item.dev_code }}
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="infoModal.show = false"></v-btn>
            </div>

            <v-card-text class="pa-6" :class="isLight ? 'bg-grey-lighten-5' : 'bg-black-20'">
                <div v-if="infoModal.loading" class="d-flex justify-center py-6">
                    <v-progress-circular indeterminate color="primary"></v-progress-circular>
                </div>
                <div v-else class="d-flex flex-column gap-5">

                    <div class="elegant-box">
                        <div class="box-title"><v-icon size="16" class="mr-1">mdi-clipboard-text-outline</v-icon> Informações Gerais</div>
                        <div class="info-grid">
                            <div class="info-item">
                                <span class="label">Vendedor (Solicitante)</span>
                                <span class="value">{{ item.profile?.full_name || 'Desconhecido' }}</span>
                            </div>
                            <div class="info-item">
                                <span class="label">Quantidade de Estampas</span>
                                <span class="value">{{ item.design_items?.length || 0 }} itens</span>
                            </div>
                            <div class="info-item full-width">
                                <span class="label">Clientes Envolvidos</span>
                                <span class="value text-truncate" :title="getCustomerList(item.design_items)">
                                    {{ getCustomerList(item.design_items) }}
                                </span>
                            </div>
                        </div>
                    </div>

                    <div class="elegant-box">
                        <div class="box-title"><v-icon size="16" class="mr-1">mdi-account-hard-hat</v-icon> Histórico de Atribuição</div>
                        <div class="pa-3 text-body-2 border-thin" :class="isLight ? 'bg-white text-grey-darken-3' : 'bg-surface-card text-white-70'" style="border-radius: 8px;">
                            <template v-if="infoModal.assignment">
                                <v-icon color="success" size="18" class="mr-1">mdi-hand-back-right</v-icon>
                                <strong>{{ getDesignerName(item.designer_id) }}</strong> solicitou este card e foi aprovado por <strong>Liderança</strong> em {{ formatDateFullTime(infoModal.assignment.created_at) }}.
                            </template>
                            <template v-else-if="item.designer_id">
                                <v-icon color="primary" size="18" class="mr-1">mdi-account-arrow-right</v-icon>
                                <strong>{{ getDesignerName(item.designer_id) }}</strong> foi atribuído diretamente ao card pela Liderança.
                            </template>
                            <template v-else>
                                <v-icon color="grey" size="18" class="mr-1">mdi-account-off</v-icon>
                                Nenhum designer responsável até o momento.
                            </template>
                        </div>
                    </div>

                    <div class="elegant-box mt-2">
                        <div class="box-title"><v-icon size="16" class="mr-1">mdi-history</v-icon> Ciclos de Rejeição / Ajustes ({{ infoModal.rejections.length }})</div>
                        <div v-if="infoModal.rejections.length === 0" class="text-caption opacity-60 pa-2">
                            Nenhuma rejeição ou ajuste registrado neste fluxo.
                        </div>
                        <div v-else class="d-flex flex-column gap-3 mt-2" style="max-height: 250px; overflow-y: auto;">
                            <div v-for="log in infoModal.rejections" :key="log.id" class="pa-3 border rounded-lg" :class="log.type === 'leader' ? (isLight ? 'bg-red-lighten-5 border-red-lighten-4' : 'bg-red-darken-4-alpha border-red-darken-3') : (isLight ? 'bg-orange-lighten-5 border-orange-lighten-4' : 'bg-orange-darken-4-alpha border-orange-darken-3')">
                                <div class="d-flex justify-space-between mb-1 align-center">
                                    <strong class="text-[11px] text-uppercase" :class="log.type === 'leader' ? (isLight ? 'text-red-darken-4' : 'text-red-lighten-2') : (isLight ? 'text-orange-darken-4' : 'text-orange-lighten-2')">
                                        <v-icon size="14" :color="log.type === 'leader' ? 'error' : 'warning'" class="mr-1">{{ log.type === 'leader' ? 'mdi-account-cancel' : 'mdi-alert' }}</v-icon>
                                        {{ log.author }}
                                    </strong>
                                    <span class="text-[10px] opacity-70">{{ log.dateFormatted }}</span>
                                </div>
                                <div class="text-caption mt-1" :class="isLight ? 'text-grey-darken-3' : 'text-white-80'">{{ log.reason }}</div>
                                <v-card v-if="log.image" @click="openImage(log.image)" class="mt-2 cursor-pointer rounded border-thin overflow-hidden" width="60" height="60" elevation="2">
                                    <v-img :src="log.image" cover class="w-100 h-100"></v-img>
                                </v-card>
                            </div>
                        </div>
                    </div>

                </div>
            </v-card-text>
        </v-card>
    </v-dialog>

    <v-dialog v-model="rejectModal.show" max-width="500" persistent>
        <v-card class="rounded-xl overflow-hidden" :class="isLight ? 'bg-white' : 'bg-surface border-white-05'">
            <div class="pa-4 border-b d-flex align-center justify-space-between bg-error text-white">
                <div class="d-flex align-center gap-2 font-weight-bold">
                    <v-icon>mdi-alert-octagon</v-icon>
                    Rejeitar Desenvolvimento: {{ item.dev_code }}
                </div>
                <v-btn icon="mdi-close" variant="text" size="small" @click="rejectModal.show = false"></v-btn>
            </div>
            <v-card-text class="pa-6">
                <p class="text-body-2 mb-4" :class="isLight ? 'text-grey-darken-3' : 'text-white-70'">Descreva o motivo da rejeição. A solicitação será devolvida para a coluna de <strong>Alteração</strong> do designer.</p>
                <v-textarea
                    v-model="rejectModal.reason"
                    label="Motivo / Ajustes Necessários *"
                    variant="outlined"
                    rows="4"
                    auto-grow
                    hide-details
                    :bg-color="isLight ? 'white' : 'rgba(0,0,0,0.2)'"
                ></v-textarea>
            </v-card-text>
            <v-card-actions class="pa-4 border-t d-flex justify-end gap-3" :class="isLight ? 'bg-grey-lighten-5 border-grey-lighten-2' : 'bg-surface border-white-05'">
                <v-btn variant="text" @click="rejectModal.show = false" :color="isLight ? 'grey-darken-2' : 'white'">Cancelar</v-btn>
                <v-btn color="error" variant="flat" class="px-6 font-weight-bold" :loading="rejectModal.loading" :disabled="!rejectModal.reason" @click="confirmRejection">Confirmar Rejeição</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
  <ImageModal :show="showImageModal" :image-url="selectedImageUrl" @close="showImageModal = false" />
  </v-card>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { useTheme } from 'vuetify';
import { formatDistanceToNow, parseISO, format, addDays } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useAppStore } from '@/stores/app';
import ImageModal from '@/components/ImageModal.vue';

const theme = useTheme();
const isLight = computed(() => !theme.global.current.value.dark);
const userStore = useUserStore();
const appStore = useAppStore();

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
  designTeamMembers: {
    type: Array as () => any[],
    default: () => []
  },
  currentUserPerms: {
    type: Object,
    default: () => ({ is_leader: false, requires_leader_approval: false, can_approve_for_leader: false })
  }
});

const emit = defineEmits(['open', 'itemUpdated', 'uploadLeader', 'uploadCustomer', 'approveLeaderReturn']);
const showImageModal = ref(false);
const selectedImageUrl = ref('');

const isLeaderOrRightHand = computed(() => props.currentUserPerms.is_leader || props.currentUserPerms.can_approve_for_leader);
const requiresApproval = computed(() => props.currentUserPerms.requires_leader_approval);
const isAlteration = computed(() => props.item.request_type === 'alteration');
const oneDayAgo = addDays(new Date(), -1);
const isDelayed = computed(() => {
    if (props.item.status === 'customer_approval' || props.item.status === 'approved_by_seller') return false;
    if (!props.item.created_at) return false;
    return parseISO(props.item.created_at) < oneDayAgo;
});

const rejectModal = reactive({ show: false, reason: '', loading: false });

const infoModal = reactive({
    show: false,
    loading: false,
    assignment: null as any,
    rejections: [] as any[]
});

const openInfoModal = async () => {
    infoModal.show = true;
    infoModal.loading = true;
    try {
        const { data: assignData } = await supabase
            .from('design_assignment_requests')
            .select('*')
            .eq('item_id', props.item.id)
            .eq('status', 'approved')
            .order('created_at', { ascending: false })
            .limit(1)
            .maybeSingle();
        infoModal.assignment = assignData;

        const { data: rejData } = await supabase
            .from('design_rejection_logs')
            .select('*, leader:profiles!leader_id(full_name)')
            .eq('item_id', props.item.id)
            .order('created_at', { ascending: false });

        const logs: any[] = [];

        (rejData || []).forEach(r => {
            logs.push({
                id: 'ldr_' + r.id,
                type: 'leader',
                author: r.leader?.full_name || 'Líder',
                date: new Date(r.created_at),
                dateFormatted: formatDateFullTime(r.created_at),
                reason: r.reason,
                image: r.rejected_image_url
            });
        });

        const items = Array.isArray(props.item.design_items) ? props.item.design_items : [];
        items.forEach((di, idx) => {
            if (di.adjustment_log) {
                const parts = di.adjustment_log.split(/\[DEVOLUÇÃO VENDEDOR - /).filter((p: string) => p.trim());
                parts.forEach((p: string, pIdx: number) => {
                    if (p.includes(']:')) {
                        const [dateStr, ...rest] = p.split(']:');
                        logs.push({
                            id: `vnd_${idx}_${pIdx}`,
                            type: 'seller',
                            author: props.item.profile?.full_name || 'Vendedor',
                            date: new Date(),
                            dateFormatted: dateStr,
                            reason: rest.join(']:').trim(),
                            image: null
                        });
                    }
                });
            }
        });

        infoModal.rejections = logs.sort((a, b) => b.date.getTime() - a.date.getTime());
    } catch (e) {
        console.error(e);
    } finally {
        infoModal.loading = false;
    }
};

const assignCard = async (designerId: string | null) => {
    if (designerId === userStore.profile?.id && !isLeaderOrRightHand.value) {
        try {
            const payload = { item_id: props.item.id, order_id: null, item_type: 'development', item_name: props.item.dev_code, designer_id: designerId };
            await supabase.from('design_assignment_requests').insert(payload);
            appStore.showSnackbar('Solicitação enviada ao líder!', 'info');
        } catch (e) { appStore.showSnackbar('Erro ao enviar solicitação.', 'error'); }
        return;
    }

    try {
        await supabase.from('design_requests').update({ designer_id: designerId }).eq('id', props.item.id);
        props.item.designer_id = designerId;
        appStore.showSnackbar('Responsável atualizado.', 'success');
        emit('itemUpdated');
    } catch (e: any) { appStore.showSnackbar('Erro ao atribuir.', 'error'); }
};

const openRejectModal = () => {
    rejectModal.reason = '';
    rejectModal.show = true;
};

const confirmRejection = async () => {
    if (!rejectModal.reason.trim()) return;
    rejectModal.loading = true;
    try {
        await supabase.from('design_rejection_logs').insert({
            item_id: props.item.id, item_type: 'development', leader_id: userStore.profile?.id, reason: rejectModal.reason
        });
        await supabase.from('design_requests').update({ design_tag: 'Alteração' }).eq('id', props.item.id);
        appStore.showSnackbar('Rejeitado e devolvido.', 'warning');
        rejectModal.show = false;
        emit('itemUpdated');
    } catch (e: any) { appStore.showSnackbar('Erro ao rejeitar.', 'error'); } finally { rejectModal.loading = false; }
};

const openImage = (url: string) => { selectedImageUrl.value = url; showImageModal.value = true; };

const getDesignerName = (id: string | null | undefined) => {
    if (!id) return '';
    const member = props.designTeamMembers.find((p: any) => p.user_id === id);
    return member?.profile?.full_name || 'Desconhecido';
};

const getCustomerList = (items: any[]) => {
    if (!items || !Array.isArray(items)) return 'Nenhum';
    const names = items.map(di => di.customer_name).filter(Boolean);
    return names.length > 0 ? names.join(', ') : 'Nenhum';
};

const getTotalMeters = (items: any[]) => {
    if (!items || !Array.isArray(items)) return 0;
    return items.reduce((sum: number, di: any) => sum + (Number(di.quantity_meters) || 0), 0);
};

const getRelativeTime = (dateStr: string) => {
    if (!dateStr) return '';
    try { return formatDistanceToNow(parseISO(dateStr), { addSuffix: true, locale: ptBR }); } catch { return ''; }
};

const formatDateFullTime = (dateStr: string) => {
    if (!dateStr) return '';
    return format(parseISO(dateStr), "dd/MM/yyyy HH:mm", { locale: ptBR });
};

const formatDateFull = (dateStr: string) => {
    if (!dateStr) return '';
    return format(parseISO(dateStr), "dd/MM/yyyy HH:mm:ss", { locale: ptBR });
};

const getInitials = (name: string) => {
    if(!name) return '--';
    const parts = name.trim().split(' ');
    if (parts.length > 1) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    return name.substring(0, 2).toUpperCase();
};
</script>

<style scoped lang="scss">
.dev-card { border-radius: 8px; cursor: pointer; position: relative; transition: transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.3s; }
.dev-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(0,0,0,0.1) !important; z-index: 2; }
.glass-card-clean { background: rgba(255, 255, 255, 0.5) !important; backdrop-filter: blur(12px); box-shadow: 0 4px 16px rgba(0,0,0,0.02) !important; border: 1px solid rgba(255, 255, 255, 0.6); }
.lh-1 { line-height: 1 !important; }

.dev-card-dark { color: #e0e0e0; }
.dev-card-dark.glass-card-clean { background: rgba(30, 30, 35, 0.3) !important; border: 1px solid rgba(255, 255, 255, 0.05) !important; box-shadow: 0 4px 16px rgba(0,0,0,0.2) !important; }
.dev-card-light { color: #424242; }

.card-header { display: flex; align-items: center; padding: 8px 12px; }
.dev-code { font-weight: 900; font-size: 0.85rem; }

.elegant-box { display: flex; flex-direction: column; gap: 8px; .box-title { font-size: 0.75rem; font-weight: 900; text-transform: uppercase; letter-spacing: 0.5px; opacity: 0.7; display: flex; align-items: center; } }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: rgba(var(--v-theme-surface), 0.5); padding: 12px; border-radius: 8px; border: 1px solid rgba(var(--v-theme-on-surface), 0.08); .full-width { grid-column: 1 / -1; } .info-item { display: flex; flex-direction: column; .label { font-size: 0.65rem; text-transform: uppercase; font-weight: 700; opacity: 0.6; margin-bottom: 2px; } .value { font-size: 0.85rem; font-weight: 600; } } }
.bg-red-darken-4-alpha { background: rgba(183, 28, 28, 0.15) !important; }
.bg-orange-darken-4-alpha { background: rgba(230, 81, 0, 0.15) !important; }
</style>
