<template>
  <div class="presence-mobile-container bg-background d-flex flex-column w-100 h-100">

    <div class="search-header px-4 py-3 bg-surface flex-shrink-0 elevation-1">
      <v-text-field
        v-model="searchQuery"
        placeholder="Pesquisar contatos..."
        variant="solo-filled"
        flat
        density="compact"
        hide-details
        prepend-inner-icon="mdi-magnify"
        clearable
        rounded="pill"
        class="search-input"
      ></v-text-field>
    </div>

    <div class="contacts-scroll-area flex-grow-1 overflow-y-auto">

      <div v-if="filteredUsers.length === 0" class="d-flex flex-column align-center justify-center h-100 pa-6 text-center">
        <v-icon size="48" color="disabled" class="mb-3">mdi-account-search-outline</v-icon>
        <span class="text-medium-emphasis">Nenhum contato encontrado.</span>
      </div>

      <template v-else>
        <div class="px-5 py-3 text-caption font-weight-bold text-medium-emphasis text-uppercase tracking-wide sticky-header bg-background border-bottom">
          Todos os Contatos ({{ filteredUsers.length }})
        </div>

        <v-list class="bg-transparent py-0" lines="two">
          <v-list-item
            v-for="user in filteredUsers"
            :key="user.id"
            class="contact-item px-4 py-3"
            @click="$emit('start-dm', user)"
            ripple
          >
            <template v-slot:prepend>
              <v-badge
                dot
                location="bottom right"
                offset-x="4"
                offset-y="4"
                :color="user.status === 'online' ? 'success' : (user.status === 'away' ? 'warning' : 'grey-lighten-1')"
                class="mr-4"
              >
                <v-avatar size="56" color="blue-grey-lighten-4" class="elevation-1">
                  <v-img v-if="user.avatar_url" :src="user.avatar_url" cover></v-img>
                  <span v-else class="text-blue-grey-darken-3 font-weight-bold text-h5">
                    {{ user.full_name?.charAt(0).toUpperCase() || 'U' }}
                  </span>
                </v-avatar>
              </v-badge>
            </template>

            <v-list-item-title class="font-weight-bold text-body-1 text-high-emphasis mb-1">
              {{ user.full_name || 'Usuário Sem Nome' }}
            </v-list-item-title>

            <v-list-item-subtitle class="text-body-2 text-medium-emphasis d-flex align-center">
              <span class="text-truncate" style="max-width: 150px;">{{ user.role || 'Equipe' }}</span>
              <span class="mx-2 opacity-50">•</span>
              <span :class="user.status === 'online' ? 'text-success font-weight-medium' : ''">
                {{ user.status === 'online' ? 'Online' : (user.status === 'away' ? 'Ausente' : 'Offline') }}
              </span>
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const props = defineProps<{
  users: any[];
}>();

defineEmits(['start-dm']);

const searchQuery = ref('');

// Filtro instantâneo super rápido para o mobile (busca por nome ou cargo)
const filteredUsers = computed(() => {
  if (!searchQuery.value) return props.users;
  const term = searchQuery.value.toLowerCase();
  return props.users.filter(u =>
    (u.full_name || '').toLowerCase().includes(term) ||
    (u.role || '').toLowerCase().includes(term)
  );
});
</script>

<style scoped>
.presence-mobile-container {
  /* Garante que o componente respeite os limites da tela do celular */
  overflow: hidden;
}

.search-header {
  z-index: 10;
}

.search-input :deep(.v-field) {
  background-color: rgba(128, 128, 128, 0.08) !important;
}

.contacts-scroll-area {
  /* Ativa a aceleração de hardware no iOS para um scroll lisinho e macio */
  -webkit-overflow-scrolling: touch;
  /* Respeita a barra de navegação/botão home no fundo do iPhone/Android */
  padding-bottom: env(safe-area-inset-bottom);
}

.contacts-scroll-area::-webkit-scrollbar {
  display: none; /* Esconde a barra de rolagem feia no celular */
}

/* O título "Todos os Contatos" fica fixo no topo enquanto você desce a lista */
.sticky-header {
  position: sticky;
  top: 0;
  z-index: 5;
  backdrop-filter: blur(8px);
  background-color: rgba(var(--v-theme-background), 0.9) !important;
}

.contact-item {
  border-bottom: 1px solid rgba(128, 128, 128, 0.08);
  min-height: 76px; /* Altura ideal recomendada pelo Google para toque do dedo */
}

.border-bottom {
  border-bottom: 1px solid rgba(128, 128, 128, 0.08);
}

.tracking-wide {
  letter-spacing: 0.05em;
}
</style>
