<template>
  <v-dialog v-model="showUpdateModal" max-width="550" persistent z-index="10000">
    <v-card class="rounded-xl overflow-hidden border-thin shadow-2xl" :class="isDark ? 'bg-grey-darken-4 text-white' : 'bg-white'">

      <div class="px-6 py-4 border-b d-flex align-center justify-space-between flex-shrink-0" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-blue-lighten-5 border-blue-lighten-4'">
        <div class="d-flex align-center gap-4">
          <div class="pa-2 rounded-lg shadow-sm d-flex align-center justify-center pulse-box" :class="isDark ? 'bg-blue-darken-4' : 'bg-blue-darken-3'">
            <v-icon size="28" color="white">mdi-rocket-launch</v-icon>
          </div>
          <div>
            <div class="text-h6 font-weight-black text-uppercase tracking-tight lh-1 mb-1" :class="isDark ? 'text-blue-lighten-2' : 'text-blue-darken-4'">Atualização de Sistema</div>
            <div class="text-caption opacity-80 font-weight-bold lh-1">Novas melhorias e correções disponíveis.</div>
          </div>
        </div>
        <v-chip :color="isDark ? 'blue-lighten-2' : 'blue-darken-3'" variant="flat" size="small" class="font-weight-black chip-3d tracking-widest px-3">
          v{{ updateData.version }}
        </v-chip>
      </div>

      <div class="pa-6" :class="isDark ? 'bg-grey-darken-4' : 'bg-white'">
        <div class="text-caption font-weight-black text-uppercase opacity-70 mb-2 tracking-widest d-flex align-center gap-2" :class="isDark ? 'text-blue-lighten-2' : 'text-blue-darken-3'">
          <v-icon size="16">mdi-text-box-check-outline</v-icon> Notas da Versão:
        </div>

        <div class="pa-4 rounded-lg border-thin custom-scroll overflow-y-auto shadow-inner" style="max-height: 220px;" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'">
          <p class="text-body-2 font-weight-medium m-0" style="white-space: pre-wrap; line-height: 1.5;" :class="isDark ? 'text-grey-lighten-2' : 'text-grey-darken-3'">
            {{ updateData.description }}
          </p>
        </div>

        <div v-if="updateData.reopenInterval > 0" class="d-flex align-center gap-2 mt-4 text-[11px] font-weight-bold opacity-60">
          <v-icon size="14">mdi-clock-outline</v-icon>
          Se ignorado, este aviso retornará automaticamente em {{ Math.round(updateData.reopenInterval / 60) }} minuto(s).
        </div>
        <div v-else class="d-flex align-center gap-2 mt-4 text-[11px] font-weight-bold text-error opacity-80">
          <v-icon size="14">mdi-alert-circle-outline</v-icon>
          Atualização obrigatória. Não é possível fechar este aviso.
        </div>
      </div>

      <div class="px-6 py-4 border-t d-flex align-center justify-end flex-shrink-0" style="gap: 12px;" :class="isDark ? 'bg-grey-darken-3 border-white-10' : 'bg-grey-lighten-5'">

        <v-btn
          v-if="updateData.reopenInterval > 0"
          variant="outlined"
          class="btn-3d font-weight-bold px-6"
          height="40"
          :color="isDark ? 'white' : 'grey-darken-2'"
          @click="closeTemporarily"
        >
          Lembrar Depois
        </v-btn>

        <v-btn
          color="success"
          variant="flat"
          class="btn-3d px-8 font-weight-black shadow-soft"
          height="40"
          @click="reloadPage"
        >
          <v-icon start size="18">mdi-refresh</v-icon>
          Atualizar Agora
        </v-btn>
      </div>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { supabase } from '@/api/supabase';
import { useUserStore } from '@/stores/user';
import { useTheme } from 'vuetify';

const theme = useTheme();
const isDark = computed(() => theme.global.current.value.dark);
const userStore = useUserStore();

const showUpdateModal = ref(false);
const updateData = ref({ version: '', description: '', reopenInterval: 300 });
let realtimeChannel: any;
let reopenTimer: ReturnType<typeof setTimeout> | null = null;

const reloadPage = () => {
    const url = new URL(window.location.href);
    url.searchParams.set('v', updateData.value.version.replace(/\./g, ''));
    window.location.href = url.toString();
};

const closeTemporarily = () => {
    showUpdateModal.value = false;
    if (updateData.value.reopenInterval > 0) {
        if (reopenTimer) clearTimeout(reopenTimer);
        reopenTimer = setTimeout(() => {
            showUpdateModal.value = true;
        }, updateData.value.reopenInterval * 1000);
    }
};

onMounted(() => {
    realtimeChannel = supabase.channel('system_updates_listener')
        .on(
            'postgres_changes',
            { event: 'INSERT', schema: 'public', table: 'system_updates' },
            (payload) => {
                const newUpdate = payload.new;

                const rawRoles = Array.isArray(newUpdate.target_roles) ? newUpdate.target_roles : [];
                const rawUsers = Array.isArray(newUpdate.target_users) ? newUpdate.target_users : [];

                const isGlobal = rawRoles.length === 0 && rawUsers.length === 0;

                const userRoleId = String(userStore.profile?.custom_role_id || '').trim();
                const userId = String(userStore.profile?.id || '').trim();

                const safeRoles = rawRoles.map(r => String(r).trim());
                const safeUsers = rawUsers.map(u => String(u).trim());

                const matchesRole = userRoleId !== '' && safeRoles.includes(userRoleId);
                const matchesUser = userId !== '' && safeUsers.includes(userId);

                if (isGlobal || matchesRole || matchesUser) {
                    updateData.value = {
                        version: newUpdate.version,
                        description: newUpdate.description,
                        reopenInterval: Number(newUpdate.reopen_interval_seconds) || 0
                    };

                    if (reopenTimer) clearTimeout(reopenTimer);
                    showUpdateModal.value = true;
                }
            }
        )
        .subscribe();
});

onUnmounted(() => {
    if (realtimeChannel) supabase.removeChannel(realtimeChannel);
    if (reopenTimer) clearTimeout(reopenTimer);
});
</script>

<style scoped>
/* EFEITOS 3D E BORDAS */
.btn-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.15), inset 0 2px 0 rgba(255,255,255,0.25) !important;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    text-transform: none !important;
}
.btn-3d:active {
    transform: translateY(2px);
    box-shadow: 0 1px 2px rgba(0,0,0,0.15), inset 0 1px 0 rgba(255,255,255,0.2) !important;
}

.chip-3d {
    border-radius: 6px !important;
    box-shadow: 0 3px 5px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.25) !important;
    text-shadow: 0 1px 2px rgba(0,0,0,0.25);
}

.shadow-inner {
    box-shadow: inset 0 2px 4px rgba(0,0,0,0.06);
}

.shadow-soft {
    box-shadow: 0 4px 12px rgba(0,0,0,0.1) !important;
}

.shadow-up {
    box-shadow: 0 -4px 12px rgba(0,0,0,0.05);
}

.border-thin { border: 1px solid rgba(0,0,0,0.08) !important; }

/* ANIMAÇÃO DE PULSO NO ÍCONE */
.pulse-box {
    animation: pulse-box-glow 2s infinite;
}
@keyframes pulse-box-glow {
    0% { box-shadow: 0 0 0 0 rgba(21, 101, 192, 0.4); }
    70% { box-shadow: 0 0 0 6px rgba(21, 101, 192, 0); }
    100% { box-shadow: 0 0 0 0 rgba(21, 101, 192, 0); }
}

/* UTILITÁRIOS DE TEXTO */
.lh-1 { line-height: 1.1; }
.tracking-tight { letter-spacing: -0.5px; }
.tracking-widest { letter-spacing: 0.05em; }

/* SCROLLBAR CUSTOMIZADA */
.custom-scroll { scrollbar-gutter: stable; }
.custom-scroll::-webkit-scrollbar { width: 6px; }
.custom-scroll::-webkit-scrollbar-track { background: transparent; }
.custom-scroll::-webkit-scrollbar-thumb { background: rgba(128,128,128, 0.25); border-radius: 4px; }
</style>
