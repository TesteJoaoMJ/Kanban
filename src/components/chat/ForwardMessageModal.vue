<template>
  <v-dialog
    v-model="internalShow"
    :fullscreen="isMobile"
    max-width="420px"
    scrollable
    transition="dialog-bottom-transition"
    style="z-index: 9999999;"
    @click:outside="close"
    @keydown.esc="close"
  >
    <v-card class="forward-card d-flex flex-column h-100 bg-background" :class="{'rounded-xl': !isMobile, 'rounded-0': isMobile}">

      <v-toolbar color="surface" elevation="0" density="comfortable" class="flex-shrink-0 border-b">
        <v-btn icon="mdi-close" variant="text" @click="close" color="medium-emphasis"></v-btn>
        <v-toolbar-title class="font-weight-bold text-subtitle-1 px-1">
          Encaminhar mensagem
        </v-toolbar-title>
      </v-toolbar>

      <div class="pa-3 bg-surface flex-shrink-0 border-b">
        <v-text-field
          v-model="searchQuery"
          placeholder="Pesquisar..."
          variant="solo"
          flat
          density="compact"
          hide-details
          clearable
          prepend-inner-icon="mdi-magnify"
          class="forward-search-input"
        ></v-text-field>
      </div>

      <v-expand-transition>
        <div
          v-if="selectedChannels.length > 0"
          class="selected-chips-area bg-surface px-4 py-3 d-flex flex-shrink-0 border-b"
        >
          <div
            v-for="channel in selectedChannels"
            :key="channel.id"
            class="d-inline-flex flex-column align-center position-relative mr-4"
            style="width: 56px"
          >
            <div class="position-relative">
              <v-avatar size="48" :color="channel.is_private_dm ? 'primary' : 'blue-grey'" variant="tonal">
                <v-img v-if="getChannelAvatar(channel)" :src="getChannelAvatar(channel)" cover></v-img>
                <span v-else class="text-white font-weight-bold">{{ getChannelInitials(channel) }}</span>
              </v-avatar>
              <v-btn
                icon="mdi-close"
                size="18"
                class="remove-chip-btn position-absolute"
                @click.stop="toggleSelection(channel)"
              >
                <v-icon size="14">mdi-close</v-icon>
              </v-btn>
            </div>
            <span class="text-caption text-truncate w-100 text-center mt-1 font-weight-medium text-medium-emphasis">
              {{ getFirstName(getChannelName(channel)) }}
            </span>
          </div>
        </div>
      </v-expand-transition>

      <v-card-text class="pa-0 flex-grow-1 overflow-y-auto bg-surface position-relative">

        <div v-if="filteredChannels.length === 0" class="d-flex flex-column align-center justify-center h-100 pa-6 text-center">
          <v-icon size="48" class="text-disabled mb-3">mdi-account-search-outline</v-icon>
          <p class="text-medium-emphasis text-body-2">Nenhum chat encontrado.</p>
        </div>

        <v-list v-else class="bg-transparent py-2" lines="two">
          <div class="px-4 py-2 text-caption font-weight-bold text-medium-emphasis text-uppercase tracking-widest">Conversas Recentes</div>

          <v-list-item
            v-for="channel in filteredChannels"
            :key="channel.id"
            @click="toggleSelection(channel)"
            class="py-2 hover-row"
            :ripple="false"
          >
            <template v-slot:prepend>
              <div class="position-relative mr-3">
                <v-avatar size="48" :color="channel.is_private_dm ? 'primary' : 'blue-grey'" variant="tonal">
                  <v-img v-if="getChannelAvatar(channel)" :src="getChannelAvatar(channel)" cover></v-img>
                  <span v-else class="text-white font-weight-bold">{{ getChannelInitials(channel) }}</span>
                </v-avatar>

                <v-scale-transition>
                  <div v-if="isSelected(channel)" class="check-overlay position-absolute d-flex align-center justify-center">
                    <div class="check-circle bg-whatsapp-green d-flex align-center justify-center">
                      <v-icon color="white" size="14">mdi-check</v-icon>
                    </div>
                  </div>
                </v-scale-transition>
              </div>
            </template>

            <v-list-item-title class="font-weight-medium text-body-1 text-high-emphasis">
              {{ getChannelName(channel) }}
            </v-list-item-title>
            <v-list-item-subtitle class="text-body-2 text-medium-emphasis text-truncate mt-1">
              {{ channel.is_private_dm ? 'Contato' : (channel.members?.length ? channel.members.length + ' participantes' : 'Grupo') }}
            </v-list-item-subtitle>
          </v-list-item>
        </v-list>
      </v-card-text>

      <v-scale-transition>
        <v-btn
          v-if="selectedChannels.length > 0"
          icon
          size="56"
          class="forward-fab"
          elevation="4"
          @click="executeForward"
        >
          <v-icon color="white" size="24">mdi-send</v-icon>
          <div v-if="selectedChannels.length > 1" class="fab-badge">
            {{ selectedChannels.length }}
          </div>
        </v-btn>
      </v-scale-transition>

    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';

const props = defineProps<{
  modelValue: boolean;
  message: any;
  channels: any[];
}>();

const emit = defineEmits(['update:modelValue', 'forward']);

const isMobile = ref(window.innerWidth <= 767);
const handleResize = () => { isMobile.value = window.innerWidth <= 767; };

onMounted(() => window.addEventListener('resize', handleResize));
onUnmounted(() => window.removeEventListener('resize', handleResize));

const internalShow = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
});

const searchQuery = ref('');
const selectedChannels = ref<any[]>([]);

watch(internalShow, (newVal) => {
  if (newVal) {
    searchQuery.value = '';
    selectedChannels.value = [];
  }
});

const close = () => {
  internalShow.value = false;
  searchQuery.value = '';
  selectedChannels.value = [];
};

const filteredChannels = computed(() => {
  let list = props.channels || [];
  if (props.message?.channel_id) {
    list = list.filter(c => c.id !== props.message.channel_id);
  }
  if (!searchQuery.value) return list;
  const term = searchQuery.value.toLowerCase();
  return list.filter(c => getChannelName(c).toLowerCase().includes(term));
});

const isSelected = (channel: any) => {
  return selectedChannels.value.some(c => c.id === channel.id);
};

const toggleSelection = (channel: any) => {
  if (isSelected(channel)) {
    selectedChannels.value = selectedChannels.value.filter(c => c.id !== channel.id);
  } else {
    selectedChannels.value.push(channel);
  }
};

const executeForward = () => {
  if (selectedChannels.value.length === 0) return;
  const channelIds = selectedChannels.value.map(c => c.id);
  emit('forward', { channels: channelIds, message: props.message });
  close();
};

const getChannelName = (channel: any): string => {
  return channel.name || (channel.is_private_dm ? 'Contato' : 'Grupo');
};

const getChannelAvatar = (channel: any): string | null => {
  return channel.icon_image_url || null;
};

const getChannelInitials = (channel: any): string => {
  const name = getChannelName(channel);
  if (!name || name === 'Contato' || name === 'Grupo') return '?';
  const words = name.split(' ').filter(Boolean);
  if (words.length > 1) {
    return `${words[0][0]}${words[1][0]}`.toUpperCase();
  }
  return name.substring(0, 2).toUpperCase();
};

const getFirstName = (fullName: string): string => {
  if (!fullName) return '';
  return fullName.split(' ')[0];
};
</script>

<style scoped>
.forward-card {
  box-shadow: 0 8px 24px rgba(0,0,0,0.15) !important;
}

.border-b {
  border-bottom: 1px solid rgba(128, 128, 128, 0.1);
}

.tracking-widest {
  letter-spacing: 0.05em;
}

.forward-search-input {
  :deep(.v-field) {
    background-color: rgba(128, 128, 128, 0.05) !important;
    border-radius: 8px;
  }
  :deep(.v-field__input) {
    min-height: 40px !important;
    padding-top: 8px;
    padding-bottom: 8px;
    font-size: 0.95rem;
  }
}

.selected-chips-area {
  overflow-x: auto;
  white-space: nowrap;
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.selected-chips-area::-webkit-scrollbar {
  display: none;
}

.remove-chip-btn {
  bottom: -4px;
  right: -4px;
  background-color: rgb(var(--v-theme-surface));
  border: 1px solid rgba(128,128,128,0.2);
  color: rgb(var(--v-theme-on-surface));
}
.remove-chip-btn:hover {
  background-color: rgba(128,128,128,0.1);
}

.hover-row {
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.hover-row:hover {
  background-color: rgba(128, 128, 128, 0.04);
}

/* Checkmark Overlays */
.check-overlay {
  top: 0; left: 0; width: 100%; height: 100%;
  background-color: rgba(0, 0, 0, 0.3);
  border-radius: 50%;
  z-index: 2;
}
.check-circle {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid white;
}
.bg-whatsapp-green {
  background-color: #00a884 !important;
}

/* FAB WhatsApp Style */
.forward-fab {
  position: absolute;
  bottom: 24px;
  right: 24px;
  z-index: 100;
  background-color: #00a884 !important;
}

.fab-badge {
  position: absolute;
  top: -4px;
  left: -4px;
  background-color: #ff5252;
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  height: 20px;
  min-width: 20px;
  padding: 0 6px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid rgb(var(--v-theme-surface));
}

@media (prefers-color-scheme: dark) {
  .forward-search-input :deep(.v-field) {
    background-color: rgba(255, 255, 255, 0.05) !important;
  }
  .check-circle {
    border-color: #202c33;
  }
}
</style>
