<template>
  <div class="sre-terminal d-flex flex-column h-100 bg-grey-darken-4 rounded-lg overflow-hidden border border-grey-darken-2 shadow-lg">
    <div class="terminal-header bg-grey-darken-3 px-4 py-2 border-b border-grey-darken-2 d-flex align-center justify-space-between">
      <div class="d-flex align-center">
        <v-icon size="small" color="success" class="mr-2 pulse-icon">mdi-console-network</v-icon>
        <span class="text-caption font-weight-bold text-white letter-spacing-1 font-mono">LIVE TELEMETRY FEED</span>
      </div>
      <v-chip size="x-small" color="success" variant="flat" class="font-mono">ONLINE</v-chip>
    </div>

    <div class="terminal-body flex-grow-1 overflow-y-auto pa-3 custom-scrollbar">
      <v-slide-y-transition group>
        <div v-for="log in sreStore.liveFeed" :key="log.event_id" class="mb-3">
          <div class="d-flex align-start mb-1 gap-2">
            <span class="text-[10px] text-green font-mono">[{{ formatTime(log.created_at) }}]</span>
            <span class="text-[10px] text-blue-lighten-2 font-mono">[{{ log.module }}]</span>
            <span class="text-[11px] text-yellow font-weight-bold">{{ log.user_name || 'SYSTEM' }}:</span>
          </div>
          <div class="text-[12px] text-grey-lighten-2 font-mono ml-3 cursor-pointer hover-bright" @click="log.expanded = !log.expanded">
            > {{ log.didactic_message }}
          </div>

          <v-expand-transition>
            <div v-if="log.expanded" class="ml-3 mt-2 pa-2 bg-black rounded border border-grey-darken-3 text-[10px] text-grey font-mono overflow-x-auto">
              <pre>{{ JSON.stringify(log.payload, null, 2) }}</pre>
            </div>
          </v-expand-transition>
        </div>
      </v-slide-y-transition>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSreStore } from '@/stores/sreStore';
const sreStore = useSreStore();

const formatTime = (iso: string) => {
  return new Date(iso).toLocaleTimeString('pt-BR', { hour12: false });
};
</script>

<style scoped>
.font-mono { font-family: 'Courier New', Courier, monospace; }
.hover-bright:hover { color: #fff !important; }
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #555; }
.pulse-icon { animation: blink 1.5s infinite; }
@keyframes blink { 0% { opacity: 0.2; } 50% { opacity: 1; } 100% { opacity: 0.2; } }
</style>
