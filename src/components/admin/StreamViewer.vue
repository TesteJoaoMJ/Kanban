<template>
  <v-card class="stream-viewer-card rounded-0 h-100" color="black">
    <v-card-title class="d-flex align-center pa-3 bg-grey-darken-4 border-b border-white-10">
      <div class="d-flex align-center">
        <v-icon start :color="connectionState === 'Conectado' ? 'success' : 'red'" :class="{'blinking-icon': connectionState === 'Conectado'}">
          mdi-record-circle
        </v-icon>
        <span class="text-subtitle-2 font-weight-bold text-uppercase ml-2">
          Visualizando: <span class="text-white">{{ userName || 'Colaborador' }}</span>
        </span>
      </div>
      <v-spacer></v-spacer>
    </v-card-title>

    <div
      ref="playerWrapper"
      class="player-wrapper d-flex align-center justify-center flex-grow-1"
      @mouseenter="controlsVisible = true"
      @mouseleave="controlsVisible = false"
      style="height: calc(100% - 50px);"
    >
      <video
        ref="videoPlayer"
        autoplay
        playsinline
        style="width: 100%; height: 100%; object-fit: contain; background-color: #000;"
      ></video>

      <v-fade-transition>
        <v-toolbar
          v-show="controlsVisible || connectionState !== 'Conectado'"
          class="player-controls px-4 py-2"
          color="transparent"
          height="60"
        >
          <v-chip :color="stateColor" variant="flat" size="small" class="font-weight-bold text-uppercase">
            <v-progress-circular
              v-if="['Conectando...', 'Aguardando resposta...', 'Criando oferta...', 'Buscando servidores...'].includes(connectionState)"
              indeterminate
              size="12"
              width="2"
              class="mr-2"
            ></v-progress-circular>
            {{ connectionState }}
          </v-chip>
          <v-spacer></v-spacer>

          <v-btn
            @click="toggleFullScreen"
            icon
            variant="text"
            color="white"
            :title="isFullscreen ? 'Sair da Tela Cheia' : 'Tela Cheia'"
            class="mr-2"
          >
            <v-icon>{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
          </v-btn>
          <v-btn color="error" variant="flat" @click="stopStream" size="small" class="font-weight-bold rounded-0">
            <v-icon start size="16">mdi-stop-circle-outline</v-icon>
            Parar Transmissão
          </v-btn>
        </v-toolbar>
      </v-fade-transition>

      <v-fade-transition>
        <div v-if="connectionState !== 'Conectado' && connectionState !== 'Parado'" class="loading-overlay">
          <v-progress-circular indeterminate color="success" size="64" width="4"></v-progress-circular>
          <div class="mt-4 text-subtitle-2 font-weight-bold text-uppercase tracking-widest text-success">{{ connectionState }}</div>
        </div>
      </v-fade-transition>
    </div>
  </v-card>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue'
import { supabase } from '@/api/supabase'
import { useUserStore } from '@/stores/user'

const props = defineProps({
  colaboradorId: { type: String, required: true },
  userName: { type: String, default: '' },
})

const emit = defineEmits(['close'])

const videoPlayer = ref(null)
const playerWrapper = ref(null);
const connectionState = ref('Iniciando...')
const controlsVisible = ref(false)
const isFullscreen = ref(false)

// --- Variáveis Críticas de Conexão ---
let peerConnection = null
let signalingChannel = null // Escuta as respostas do colaborador
let collabChannel = null    // Canal EXCLUSIVO para enviar comandos ao colaborador

const userStore = useUserStore()
const adminId = userStore.user?.id

// --- Configuração WebRTC (METERED ALINHADO COM ELECTRON) ---
const METERED_DOMAIN = 'estudiomj.metered.live';
const METERED_CREDENTIAL_API_KEY = '332adb7b0fd78cc20c6addea17bc43ec4733';

async function getDynamicRtcConfig() {
  console.log('[ADMIN-STREAM][METERED] Buscando configuração ICE...');
  try {
    const response = await fetch(`https://${METERED_DOMAIN}/api/v1/turn/credentials?apiKey=${METERED_CREDENTIAL_API_KEY}`);
    if (!response.ok) throw new Error(`Falha ao buscar credenciais: ${response.status}`);

    const iceServers = await response.json();
    if (!iceServers || iceServers.length === 0) throw new Error('Array de ICE Vazio.');

    return { iceServers: iceServers };
  } catch (error) {
    console.warn('[ADMIN-STREAM][METERED] FALHA. Usando STUN fallback.', error);
    return {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    };
  }
}

const stateColor = computed(() => {
  if (connectionState.value === 'Conectado') return 'success';
  if (['Falhou', 'Desconectado', 'Erro'].includes(connectionState.value)) return 'error';
  return 'warning';
})

function stopStream() {
  console.log('[ADMIN-STREAM] Parando stream e limpando canais...')

  // 1. Envia comando de parada via canal dedicado e o DESTRÓI
  if (collabChannel) {
      collabChannel.send({
        type: 'broadcast',
        event: 'stop-stream',
        payload: { adminId: adminId }
      }).catch(err => console.error('[ADMIN-STREAM] Erro stop-stream:', err))

      supabase.removeChannel(collabChannel) // REMOÇÃO CRÍTICA PARA RECONEXÃO
      collabChannel = null
  }

  // 2. Destrói o canal de escuta do admin
  if (signalingChannel) {
      supabase.removeChannel(signalingChannel)
      signalingChannel = null
  }

  // 3. Fecha a conexão P2P
  if (peerConnection) {
    peerConnection.onicecandidate = null;
    peerConnection.onconnectionstatechange = null;
    peerConnection.ontrack = null;
    peerConnection.close()
    peerConnection = null
  }

  if (videoPlayer.value) videoPlayer.value.srcObject = null;
  connectionState.value = 'Parado';
  emit('close')
}

async function startStreaming() {
  if (!adminId) return;
  if (peerConnection) peerConnection.close();
  if (signalingChannel) supabase.removeChannel(signalingChannel);
  if (collabChannel) supabase.removeChannel(collabChannel);

  console.log(`[ADMIN-STREAM] Iniciando stream...`)

  try {
    connectionState.value = 'Buscando servidores...'
    const dynamicRtcConfig = await getDynamicRtcConfig();

    connectionState.value = 'Criando conexão...'
    peerConnection = new RTCPeerConnection(dynamicRtcConfig)

    peerConnection.ontrack = (event) => {
      console.log('[ADMIN-STREAM] Recebido ontrack (stream de vídeo)!')
      if (videoPlayer.value && event.streams && event.streams[0]) {
        videoPlayer.value.srcObject = event.streams[0]
      }
    }

    peerConnection.onicecandidate = (event) => {
      if (event.candidate && collabChannel) {
          collabChannel.send({
            type: 'broadcast',
            event: 'ice-candidate',
            payload: { payload: event.candidate, adminId: adminId },
          }).catch(err => console.error('[ADMIN-STREAM] Erro ICE:', err))
      }
    }

    peerConnection.onconnectionstatechange = () => {
      const state = peerConnection?.connectionState
      if (!state) return;
      if (state === 'connected') connectionState.value = 'Conectado';
      else if (state === 'disconnected' || state === 'closed') connectionState.value = 'Desconectado';
      else if (state === 'failed') { connectionState.value = 'Falhou'; stopStream(); }
    }

    // A. Configura Canal de Recepção (Escuta respostas do Desktop)
    const adminChannelName = `stream-signal-${adminId}`
    signalingChannel = supabase.channel(adminChannelName)

    signalingChannel.on('broadcast', { event: 'answer' }, (message) => {
        if (peerConnection && message.payload?.collabId === props.colaboradorId) {
          peerConnection.setRemoteDescription(new RTCSessionDescription(message.payload.payload))
        }
    }).on('broadcast', { event: 'ice-candidate' }, (message) => {
        if (peerConnection && message.payload?.collabId === props.colaboradorId) {
          peerConnection.addIceCandidate(new RTCIceCandidate(message.payload.payload))
        }
    }).subscribe()

    // B. Configura Canal de Envio (Dedicado a mandar comandos pro Desktop)
    const collabChannelName = `stream-signal-${props.colaboradorId}`
    collabChannel = supabase.channel(collabChannelName)

    // Só envia a oferta DEPOIS de confirmar que o canal foi registrado no Supabase
    collabChannel.subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
            await createAndSendOffer()
        }
    })

  } catch (err) {
    console.error('[ADMIN-STREAM] Erro fatal:', err)
    connectionState.value = 'Erro fatal'
  }
}

async function createAndSendOffer() {
   if (!peerConnection || !collabChannel) return;
   try {
     connectionState.value = 'Criando oferta...'
     const offer = await peerConnection.createOffer({ offerToReceiveVideo: true });
     await peerConnection.setLocalDescription(offer)

     const status = await collabChannel.send({
       type: 'broadcast',
       event: 'offer',
       payload: { offer: offer, adminId: adminId },
     })

     if (status === 'ok') connectionState.value = 'Aguardando resposta...';
     else connectionState.value = 'Falha ao enviar oferta';
   } catch (err) {
     connectionState.value = 'Erro ao criar oferta'
   }
}

function toggleFullScreen() {
  if (!playerWrapper.value) return;
  if (!document.fullscreenElement) playerWrapper.value.requestFullscreen();
  else document.exitFullscreen();
}

function onFullScreenChange() {
  isFullscreen.value = !!document.fullscreenElement;
  if (isFullscreen.value) {
    controlsVisible.value = true;
    setTimeout(() => { if (isFullscreen.value) controlsVisible.value = false; }, 3000);
  }
}

onMounted(async () => {
  await nextTick();
  startStreaming();
  document.addEventListener('fullscreenchange', onFullScreenChange);
})

onBeforeUnmount(() => {
  document.removeEventListener('fullscreenchange', onFullScreenChange);
  stopStream();
})
</script>

<style scoped>
.stream-viewer-card { overflow: hidden; }
.player-wrapper { position: relative; background-color: #000; width: 100%; }

.player-controls {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  z-index: 10;
  background-image: linear-gradient(to top, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0) 100%);
}

.loading-overlay {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 9;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background-color: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(8px);
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}
.blinking-icon { animation: blink 1.5s infinite; }
.tracking-widest { letter-spacing: 2px !important; }
</style>
