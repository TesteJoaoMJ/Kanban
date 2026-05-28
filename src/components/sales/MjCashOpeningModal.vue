<template>
  <v-dialog v-model="dialog" max-width="450" persistent transition="dialog-bottom-transition">
    <v-card class="rounded-xl overflow-hidden" :class="themeClass">

      <div class="pt-8 pb-4 text-center relative">
        <div class="absolute top-0 right-0 p-4">
           <v-btn icon variant="text" density="compact" @click="handleCloseOrBack">
             <v-icon>mdi-close</v-icon>
           </v-btn>
        </div>

        <div class="mb-4 d-flex justify-center">
          <div class="icon-circle-lg elevation-3" :class="isDark ? 'bg-surface-light text-primary' : 'bg-blue-lighten-5 text-blue-darken-2'">
            <v-icon size="40">mdi-cash-register</v-icon>
          </div>
        </div>

        <h2 class="text-h5 font-weight-black mb-1">Abertura de Caixa</h2>
        <p class="text-body-2 opacity-70 px-6">
          Olá <strong>{{ userStore.profile?.full_name?.split(' ')[0] || 'Operador' }}</strong>, informe o valor presente na sua gaveta individual para iniciar suas operações de venda na unidade <strong class="text-primary">{{ userStore.activeStoreName }}</strong>.
        </p>
      </div>

      <v-divider class="mx-6 opacity-20"></v-divider>

      <div class="pa-6">
        <label class="text-caption font-weight-bold text-uppercase opacity-70 mb-2 d-block">Saldo Inicial (Fundo de Troco)</label>

        <v-text-field
          v-model="initialBalance"
          type="number"
          variant="outlined"
          prefix="R$"
          placeholder="0,00"
          class="text-h5 font-weight-bold centered-input"
          :bg-color="inputBgColor"
          hide-details
          autofocus
          @keydown.enter="confirmOpen"
        ></v-text-field>

        <div class="mt-6 d-flex flex-column gap-3">
          <v-btn
            block
            size="large"
            color="primary"
            class="font-weight-bold rounded-lg text-button"
            height="52"
            :loading="loading"
            @click="confirmOpen"
          >
            Abrir Meu Caixa
            <v-icon end>mdi-arrow-right</v-icon>
          </v-btn>

          <v-btn
            v-if="userStore.isAdmin"
            block
            variant="text"
            size="large"
            class="text-caption font-weight-bold opacity-70 hover:opacity-100"
            @click="emitChangeStore"
          >
            <v-icon start size="18">mdi-store-edit</v-icon>
            Trocar Unidade
          </v-btn>

          <v-btn
            v-else
            block
            variant="text"
            size="large"
            class="text-caption font-weight-bold opacity-70 hover:opacity-100"
            @click="goToDashboard"
          >
            <v-icon start size="18">mdi-view-dashboard-outline</v-icon>
            Voltar ao Dashboard
          </v-btn>
        </div>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { useUserStore } from '@/stores/user';
import { useThemeStore } from '@/stores/theme';
import { useRouter } from 'vue-router';

const props = defineProps(['modelValue']);
const emit = defineEmits(['update:modelValue', 'session-opened', 'change-store']);

const cashStore = useMjCashSessionStore();
const userStore = useUserStore();
const themeStore = useThemeStore();
const router = useRouter();

const initialBalance = ref('');
const loading = ref(false);

const dialog = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
});

// Estilos Computados
const isDark = computed(() => themeStore.currentMode !== 'light');
const themeClass = computed(() => isDark.value ? 'bg-surface border-white-10' : 'bg-white');
const inputBgColor = computed(() => isDark.value ? 'rgba(255,255,255,0.05)' : 'grey-lighten-5');

const handleCloseOrBack = () => {
  if (userStore.isAdmin) {
    emit('change-store'); // Admin pode querer trocar loja
    dialog.value = false;
  } else {
    goToDashboard();
  }
};

const goToDashboard = () => {
  dialog.value = false;
  router.push({ name: 'Hub' });
};

const emitChangeStore = () => {
  dialog.value = false;
  // O componente pai (NewOrder) deve ouvir esse evento para resetar o userStore.adminSelectedStore
  router.push({ name: 'Hub' }); // Ou reseta a store no pai
};

const confirmOpen = async () => {
  if (!initialBalance.value && initialBalance.value !== '0') return;

  loading.value = true;
  try {
    const val = parseFloat(initialBalance.value.replace(',', '.'));
    await cashStore.openSession(val);
    emit('session-opened');
    dialog.value = false;
  } catch (error) {
    console.error(error);
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.icon-circle-lg {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}
.centered-input :deep(input) {
  text-align: center;
}
.gap-3 { gap: 12px; }
.border-white-10 { border: 1px solid rgba(255,255,255,0.1); }
</style>
