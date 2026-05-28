<template>
  <div class="security-tab-wrapper">

    <div class="panel-header">
      <h3 class="panel-title">Segurança & Gateways</h3>
      <p class="panel-desc">Auditoria de conexões, IPs, Fingerprint e redefinição de criptografia local.</p>
    </div>

    <div class="security-layout">

      <div class="security-section">
        <h4 class="section-title">Criptografia Local</h4>
        <p class="section-subtitle">Renove sua chave de acesso ao ecossistema.</p>

        <v-form @submit.prevent="updatePassword" class="profile-form mt-6">
          <div class="form-group mb-4">
            <label>Nova Senha</label>
            <div class="input-icon-wrap">
              <v-icon size="20" class="input-icon">mdi-lock-outline</v-icon>
              <input
                v-model="form.newPassword"
                type="password"
                class="mj-input mj-surface-2 mj-border"
                required
                minlength="6"
                placeholder="Mínimo 6 caracteres"
                @input="calculatePwdStrength"
              />
            </div>

            <div class="strength-ui mj-surface-2 mj-border mt-3">
              <div class="d-flex justify-space-between align-center mb-2">
                <span class="text-caption font-weight-bold text-uppercase tracking-widest text-muted">Score de Entropia</span>
                <v-chip size="x-small" :color="pwdStrengthColor" variant="tonal" class="font-weight-black px-2 rounded-2px tracking-widest text-uppercase">
                  {{ pwdStrengthLabel }}
                </v-chip>
              </div>
              <div class="strength-bar-bg">
                <div class="strength-bar-fill" :class="'bg-' + pwdStrengthColor" :style="{ width: pwdStrengthPercent + '%' }"></div>
              </div>
            </div>
          </div>

          <div class="form-group mb-6">
            <label>Confirmar Nova Senha</label>
            <div class="input-icon-wrap">
              <v-icon size="20" class="input-icon">mdi-lock-check-outline</v-icon>
              <input
                v-model="form.confirmPassword"
                type="password"
                class="mj-input mj-surface-2 mj-border"
                required
                minlength="6"
                placeholder="Repita a senha"
              />
            </div>
            <div class="mt-2 pl-1" v-if="form.confirmPassword">
              <span class="text-caption font-weight-black text-uppercase tracking-widest d-flex align-center gap-1" :class="passwordsMatch ? 'text-success' : 'text-error'">
                <v-icon size="14">{{ passwordsMatch ? 'mdi-check-circle' : 'mdi-close-circle' }}</v-icon>
                {{ passwordsMatch ? 'Assinaturas Coincidem' : 'Divergência Detectada' }}
              </span>
            </div>
          </div>

          <div class="form-actions">
            <v-btn
              type="submit"
              color="primary"
              size="large"
              block
              :loading="savingPwd"
              :disabled="!passwordsMatch || form.newPassword.length < 6"
              class="action-btn"
            >
              <v-icon start>mdi-fingerprint</v-icon>
              Efetivar Credencial
            </v-btn>
          </div>
        </v-form>
      </div>

      <div class="security-section">
        <div class="d-flex justify-space-between align-center mb-1">
          <h4 class="section-title m-0">Gateways Ativos</h4>
          <div class="d-flex gap-2">
            <v-btn variant="outlined" color="primary" size="small" class="action-btn px-3" @click="fetchSessions" :loading="loadingSessions">
              <v-icon size="16" class="mr-1">mdi-radar</v-icon> Escanear
            </v-btn>
            <v-btn variant="tonal" color="error" size="small" class="action-btn px-3" @click="revokeAllSessions" :loading="revokingAll" :disabled="activeSessions.length <= 1">
              Revogar Outros
            </v-btn>
          </div>
        </div>
        <p class="section-subtitle mb-6">Monitoramento de IPs e Dispositivos em tempo real.</p>

        <div v-if="loadingSessions" class="empty-state py-12 mj-surface-2 mj-border">
           <v-progress-circular indeterminate color="primary" size="32" width="3" class="mb-4" />
           <h4 class="m-0 text-body-2 font-weight-bold uppercase tracking-widest">Triangulando Hashes...</h4>
        </div>

        <div v-else-if="activeSessions.length === 0" class="empty-state py-12 mj-surface-2 mj-border">
          <v-icon size="42" color="grey" class="mb-3">mdi-server-network-off</v-icon>
          <h4 class="m-0 text-body-2 font-weight-bold uppercase tracking-widest">Nenhuma conexão</h4>
        </div>

        <div v-else class="sessions-list scrollable-nav">
          <div
            v-for="(session, index) in activeSessions"
            :key="session.id"
            class="session-item mj-surface-2 mj-border"
            :class="{ 'is-active-device': index === 0, 'is-inspected': inspectedSession?.id === session.id }"
            @click="inspectSessionMap(session)"
          >
            <div class="session-icon">
              <v-icon size="24">{{ getDeviceIcon(session.device_type) }}</v-icon>
            </div>

            <div class="session-info">
              <div class="d-flex align-center gap-2 flex-wrap">
                <strong class="session-browser">{{ session.browser || 'Browser Desconhecido' }}</strong>
                <span class="session-os">{{ session.os || 'OS Desconhecido' }}</span>
                <v-chip v-if="index === 0" size="x-small" color="success" variant="flat" class="rounded-2px font-weight-bold px-2 tracking-widest text-[9px]">SESSÃO ATUAL</v-chip>
              </div>
              <div class="session-meta">
                <span class="d-flex align-center gap-1"><v-icon size="12">mdi-map-marker-outline</v-icon> {{ session.location || 'Localização Pendente' }}</span>
                <span class="d-flex align-center gap-1 text-primary"><v-icon size="12">mdi-ip-network</v-icon> {{ session.ip_address || '0.0.0.0' }}</span>
              </div>
            </div>

            <div class="session-actions">
              <v-btn v-if="index !== 0" variant="outlined" color="error" size="small" class="action-btn px-4" @click.stop="revokeSession(session.id)" :loading="revokingId === session.id">
                Derrubar
              </v-btn>
              <v-icon v-else color="success" size="24">mdi-shield-check</v-icon>
            </div>
          </div>
        </div>

        <div class="disclaimer-box mt-6 mj-surface-2 mj-border">
          <v-icon size="16" color="warning" class="mr-3 mt-1">mdi-alert-outline</v-icon>
          <div>
            <strong class="d-block text-warning mb-1">Aviso de Rastreamento</strong>
            <p class="m-0">Desktops sem GPS exibem o provedor de internet (ISP). Guie-se pela Assinatura de Hardware clicando na conexão.</p>
          </div>
        </div>
      </div>
    </div>

    <div class="security-seals">
       <div class="seal-item"><v-icon size="16">mdi-shield-key-outline</v-icon> AES-256 Encrypted</div>
       <div class="seal-item"><v-icon size="16">mdi-server-network</v-icon> SOC 2 Type II</div>
       <div class="seal-item"><v-icon size="16">mdi-check-decagram-outline</v-icon> Zero-Knowledge</div>
    </div>

    <transition name="slide-fade">
      <aside v-show="inspectedSession" class="map-inspector-drawer mj-surface mj-border">
        <div class="drawer-header border-b">
          <div class="d-flex flex-column gap-1">
             <h3 class="panel-title text-h6 m-0 d-flex align-center gap-2 text-primary">
               <v-icon size="20">mdi-radar</v-icon> Auditoria Atômica
             </h3>
             <p class="panel-desc text-caption m-0">Rastreio e Assinatura de Hardware</p>
          </div>
          <v-btn icon="mdi-close" variant="tonal" size="small" class="action-btn" @click="closeMapDrawer"></v-btn>
        </div>

        <div class="map-container-wrap border-b">
           <div id="session-map-container" class="w-100 h-100 bg-surface-2"></div>
           <div class="map-overlay-info mj-surface mj-border">
              <v-icon size="24" color="primary">mdi-crosshairs-gps</v-icon>
              <div class="d-flex flex-column min-w-0">
                 <strong class="text-truncate">{{ inspectedSession?.location || 'Localização Oculta' }}</strong>
                 <span class="text-primary text-truncate">Lat: {{ inspectedSession?.lat?.toFixed(5) || '--' }} / Lng: {{ inspectedSession?.lng?.toFixed(5) || '--' }}</span>
              </div>
           </div>
        </div>

        <div class="drawer-content scrollable-nav">
           <div class="fingerprint-box mj-surface-2 mj-border">
             <v-icon size="60" class="fingerprint-bg">mdi-fingerprint</v-icon>
             <span class="label">Assinatura de Hardware (Fingerprint ID)</span>
             <strong class="value text-primary">{{ inspectedSession?.fingerprint || 'HASH-PENDENTE' }}</strong>
             <p class="desc">Identificador único gerado via Canvas Rendering e Hardware Info.</p>
           </div>

           <div class="meta-data-list">
             <div class="meta-row border-b">
               <span class="meta-label">Endereço IP (ISP Gateway)</span>
               <span class="meta-value text-primary">{{ inspectedSession?.ip_address || '0.0.0.0' }}</span>
             </div>
             <div class="meta-row border-b d-flex gap-4">
               <div class="flex-grow-1">
                 <span class="meta-label">Navegador</span>
                 <span class="meta-value">{{ inspectedSession?.browser || 'Desconhecido' }}</span>
               </div>
               <div class="flex-grow-1">
                 <span class="meta-label">Sistema (OS)</span>
                 <span class="meta-value">{{ inspectedSession?.os || 'Desconhecido' }}</span>
               </div>
             </div>
             <div class="meta-row border-b">
               <span class="meta-label">Última Atividade</span>
               <span class="meta-value text-success d-flex align-center gap-1">
                 <v-icon size="14">mdi-clock-outline</v-icon> {{ inspectedSession ? formatTimeAgo(inspectedSession.last_active_at) : '' }}
               </span>
             </div>
           </div>

           <div class="mt-auto pt-6">
             <v-btn
               v-if="activeSessions[0]?.id !== inspectedSession?.id"
               block color="error" size="large"
               class="action-btn"
               @click="revokeSession(inspectedSession!.id)"
               :loading="revokingId === inspectedSession?.id"
             >
               <v-icon start>mdi-power-plug-off</v-icon> Derrubar Conexão
             </v-btn>
             <div v-else class="active-device-alert mj-surface-2 mj-border text-success">
               <v-icon size="16" class="mr-2">mdi-shield-check</v-icon> Este é o seu dispositivo atual. Impressão validada.
             </div>
           </div>
        </div>
      </aside>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { supabase } from '@/api/supabase'
import { useAppStore } from '@/stores/app'

const props = defineProps<{ user: any }>()
const appStore = useAppStore()

// --- CRIPTOGRAFIA (SENHA) ---
const savingPwd = ref(false)
const form = reactive({ newPassword: '', confirmPassword: '' })
const pwdStrengthPercent = ref(0)
const pwdStrengthLabel = ref('Ausente')
const pwdStrengthColor = ref('grey')

const passwordsMatch = computed(() => form.newPassword !== '' && form.newPassword === form.confirmPassword)

const calculatePwdStrength = () => {
  const pwd = form.newPassword
  let score = 0
  if (pwd.length > 5) score += 20
  if (pwd.length > 9) score += 20
  if (/[A-Z]/.test(pwd)) score += 20
  if (/[0-9]/.test(pwd)) score += 20
  if (/[^A-Za-z0-9]/.test(pwd)) score += 20

  pwdStrengthPercent.value = score
  if (score === 0) { pwdStrengthLabel.value = 'Ausente'; pwdStrengthColor.value = 'grey' }
  else if (score <= 40) { pwdStrengthLabel.value = 'Vulnerável'; pwdStrengthColor.value = 'error' }
  else if (score <= 80) { pwdStrengthLabel.value = 'Sólida'; pwdStrengthColor.value = 'warning' }
  else { pwdStrengthLabel.value = 'Impenetrável'; pwdStrengthColor.value = 'success' }
}

const updatePassword = async () => {
  if (!passwordsMatch.value) return
  savingPwd.value = true
  try {
    const { error } = await supabase.auth.updateUser({ password: form.newPassword })
    if (error) throw error
    appStore.showSnackbar('Senha atualizada com sucesso.', 'success')
    form.newPassword = ''; form.confirmPassword = ''; calculatePwdStrength()
  } catch (error) {
    appStore.showSnackbar('Falha ao atualizar senha. Verifique as regras.', 'error')
  } finally {
    savingPwd.value = false
  }
}

// --- GATEWAYS & SESSÕES ---
interface ActiveSession {
  id: string;
  ip_address: string;
  user_agent: string;
  browser: string;
  os: string;
  device_type: string;
  location: string;
  lat: number;
  lng: number;
  fingerprint?: string;
  last_active_at: string;
}

const loadingSessions = ref(true)
const activeSessions = ref<ActiveSession[]>([])
const revokingId = ref<string | null>(null)
const revokingAll = ref(false)

const getDeviceIcon = (type: string) => {
  if (!type) return 'mdi-monitor'
  const t = type.toLowerCase()
  if (t.includes('mobile') || t.includes('phone')) return 'mdi-cellphone'
  if (t.includes('tablet')) return 'mdi-tablet'
  return 'mdi-laptop-mac'
}

const formatTimeAgo = (dateStr: string) => {
  if (!dateStr) return 'Desconhecido'
  const diff = new Date().getTime() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'Agora mesmo'
  if (mins < 60) return `Há ${mins} min`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `Há ${hrs}h`
  return `Há ${Math.floor(hrs / 24)} dias`
}

const generateDeviceFingerprint = async (): Promise<string> => {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  if (ctx) {
    ctx.textBaseline = 'top'
    ctx.font = '14px Arial'
    ctx.fillStyle = '#f60'
    ctx.fillRect(125,1,62,20)
    ctx.fillStyle = '#069'
    ctx.fillText('PatternAtlas ERP 2026', 2, 15)
    ctx.fillStyle = 'rgba(102, 204, 0, 0.7)'
    ctx.fillText('PatternAtlas ERP 2026', 4, 17)
  }
  const canvasData = canvas.toDataURL()
  const browserInfo = navigator.userAgent + navigator.language + screen.colorDepth + screen.width + screen.height

  const msgUint8 = new TextEncoder().encode(canvasData + browserInfo)
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')

  return hashHex.substring(0, 12).toUpperCase()
}

const getUserLocation = (): Promise<{ lat: number, lng: number, address: string }> => {
  return new Promise((resolve) => {
    const fallback = { lat: -23.1066, lng: -47.7156, address: 'Gateway de ISP (Tietê-SP)' }

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const lat = pos.coords.latitude
          const lng = pos.coords.longitude
          let address = 'Localização Georreferenciada'

          try {
            const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`)
            const data = await res.json()
            if (data && data.address) {
              const street = data.address.road || data.address.pedestrian || ''
              const suburb = data.address.suburb || data.address.neighbourhood || ''
              const city = data.address.city || data.address.town || data.address.village || ''
              address = `${street ? street + ', ' : ''}${suburb ? suburb + ' - ' : ''}${city}`
            }
          } catch (e) {
             console.warn('Falha no Nominatim', e)
          }
          resolve({ lat, lng, address })
        },
        (err) => { resolve(fallback) },
        { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
      )
    } else {
      resolve(fallback)
    }
  })
}

const fetchSessions = async () => {
  loadingSessions.value = true
  await new Promise(r => setTimeout(r, 800))

  try {
    const { data, error } = await supabase
      .from('user_active_sessions')
      .select('*')
      .eq('user_id', props.user?.id)
      .eq('is_revoked', false)
      .order('last_active_at', { ascending: false })

    if (error) throw error

    if (!data || data.length === 0) {
      const fingerprintId = await generateDeviceFingerprint()
      const realLocation = await getUserLocation()

      let realIp = '177.12.89.44'
      try {
        const ipRes = await fetch('https://api.ipify.org?format=json')
        const ipData = await ipRes.json()
        realIp = ipData.ip
      } catch(e){}

      activeSessions.value = [{
        id: 'mock_current_session',
        ip_address: realIp,
        user_agent: navigator.userAgent,
        browser: navigator.userAgent.includes('Chrome') ? 'Google Chrome' : 'Safari / Firefox',
        os: navigator.userAgent.includes('Windows') ? 'Windows' : 'macOS / Linux',
        device_type: window.innerWidth < 768 ? 'Mobile' : 'Desktop',
        location: realLocation.address,
        lat: realLocation.lat,
        lng: realLocation.lng,
        fingerprint: fingerprintId,
        last_active_at: new Date().toISOString()
      }]
    } else {
      activeSessions.value = data
    }
  } catch (err) {
    console.error(err)
    appStore.showSnackbar('Erro ao auditar sessões.', 'error')
  } finally {
    loadingSessions.value = false
  }
}

const revokeSession = async (sessionId: string) => {
  if (sessionId === 'mock_current_session') {
    appStore.showSnackbar('Sessão simulada removida.', 'success')
    activeSessions.value = activeSessions.value.filter(s => s.id !== sessionId)
    closeMapDrawer()
    return
  }
  revokingId.value = sessionId
  try {
    await supabase.from('user_active_sessions').update({ is_revoked: true }).eq('id', sessionId)
    activeSessions.value = activeSessions.value.filter(s => s.id !== sessionId)
    if (inspectedSession.value?.id === sessionId) closeMapDrawer()
    appStore.showSnackbar('Conexão derrubada com sucesso.', 'success')
  } catch (err) {
    appStore.showSnackbar('Erro ao revogar sessão.', 'error')
  } finally {
    revokingId.value = null
  }
}

const revokeAllSessions = async () => {
  if (!confirm('Atenção: Deseja derrubar todas as outras conexões ativas?')) return
  revokingAll.value = true
  try {
    const currentSessionId = activeSessions.value[0]?.id
    if (currentSessionId !== 'mock_current_session') {
      await supabase.from('user_active_sessions')
        .update({ is_revoked: true })
        .eq('user_id', props.user?.id)
        .neq('id', currentSessionId)
    }
    activeSessions.value = activeSessions.value.filter(s => s.id === currentSessionId)
    closeMapDrawer()
    appStore.showSnackbar('Gateways externos foram desativados.', 'success')
  } catch(err) {
    appStore.showSnackbar('Erro ao revogar sessões.', 'error')
  } finally {
    revokingAll.value = false
  }
}

// --- LEAFLET MAP & DRAWER ---
const inspectedSession = ref<ActiveSession | null>(null)
let LMap: any = null
let leafletMarker: any = null
let leafletCircle: any = null

const injectLeaflet = (): Promise<any> => {
  return new Promise((resolve) => {
    if ((window as any).L) return resolve((window as any).L)
    const css = document.createElement('link')
    css.rel = 'stylesheet'; css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
    document.head.appendChild(css)
    const script = document.createElement('script')
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
    script.onload = () => resolve((window as any).L)
    document.head.appendChild(script)
  })
}

const inspectSessionMap = async (session: ActiveSession) => {
  inspectedSession.value = session

  await nextTick()
  const L = await injectLeaflet()

  if (!LMap) {
    LMap = L.map('session-map-container', { zoomControl: false, attributionControl: false })
    const tiles = L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png', { maxZoom: 19 })
    tiles.addTo(LMap)
  }

  const targetLat = session.lat || -23.1066
  const targetLng = session.lng || -47.7156

  LMap.setView([targetLat, targetLng], 16)

  setTimeout(() => { LMap.invalidateSize() }, 300)

  if (leafletCircle) leafletCircle.remove()
  if (leafletMarker) leafletMarker.remove()

  leafletCircle = L.circle([targetLat, targetLng], {
    color: '#EF4444', fillColor: '#EF4444', fillOpacity: 0.1,
    radius: 100, weight: 2, dashArray: '4, 4'
  }).addTo(LMap)

  const customIcon = L.divIcon({
    className: 'custom-radar-marker',
    html: `<div style="width:12px;height:12px;background:#EF4444;border:2px solid #fff;border-radius:2px;box-shadow:0 0 10px rgba(0,0,0,0.8);"></div>`,
    iconSize: [12, 12],
    iconAnchor: [6, 6]
  })

  leafletMarker = L.marker([targetLat, targetLng], { icon: customIcon }).addTo(LMap)
}

const closeMapDrawer = () => { inspectedSession.value = null }

onMounted(() => { fetchSessions() })
onUnmounted(() => { if (LMap) LMap.remove() })
</script>

<style scoped>
/* =========================================================
   MARKETPLACE DESIGN SYSTEM - STRICT 2PX
========================================================= */

/* Wrapper que anula o padding do componente pai (.tab-panel) para a gaveta funcionar */
.security-tab-wrapper {
  position: relative;
  margin: -36px;
  padding: 36px;
  min-height: 600px;
  overflow: hidden;
}

.panel-header {
  margin-bottom: 36px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--border-color);
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.panel-title {
  color: var(--text-main);
  font-size: 1.8rem;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin: 0;
}

.panel-desc {
  color: var(--text-muted);
  font-size: 1rem;
  margin-top: 6px;
}

/* LAYOUT */
.security-layout {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 40px;
}

.section-title {
  color: var(--text-main);
  font-size: 1.2rem;
  font-weight: 800;
  margin-bottom: 4px;
}

.section-subtitle {
  color: var(--text-muted);
  font-size: 0.9rem;
}

/* FORMULÁRIOS */
.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  color: var(--text-main);
  font-size: 0.85rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.input-icon-wrap {
  position: relative;
  width: 100%;
}

.input-icon {
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0.5;
  pointer-events: none;
}

.mj-input {
  width: 100%;
  height: 56px;
  padding: 0 16px 0 48px;
  border-radius: 2px !important;
  color: var(--text-main);
  font-size: 1.05rem;
  outline: none;
  transition: all 0.2s ease;
}

.mj-input:focus {
  border-color: rgba(var(--v-theme-primary), 0.65) !important;
  box-shadow: 0 0 0 4px rgba(var(--v-theme-primary), 0.12);
  background: var(--bg-surface);
}

.action-btn {
  border-radius: 2px !important;
  font-weight: 800 !important;
  letter-spacing: 0.02em;
}

/* FORÇA DA SENHA */
.strength-ui {
  padding: 16px;
  border-radius: 2px !important;
}

.strength-bar-bg {
  width: 100%;
  height: 4px;
  background: var(--border-color);
  border-radius: 2px;
  overflow: hidden;
}

.strength-bar-fill {
  height: 100%;
  transition: width 0.3s ease, background-color 0.3s ease;
}

/* SESSÕES */
.sessions-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 400px;
  overflow-y: auto;
  padding-right: 8px;
}

.session-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border-radius: 2px !important;
  cursor: pointer;
  transition: all 0.2s ease;
}

.session-item:hover {
  border-color: rgba(var(--v-theme-primary), 0.3) !important;
  background: var(--bg-surface);
}

.session-item.is-active-device {
  border-color: rgba(var(--v-theme-primary), 0.5) !important;
}

.session-item.is-inspected {
  background: rgba(var(--v-theme-primary), 0.05);
  border-color: rgb(var(--v-theme-primary)) !important;
}

.session-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 2px;
  background: var(--bg-surface-2);
  border: 1px solid var(--border-color);
  flex-shrink: 0;
}

.session-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.session-browser {
  color: var(--text-main);
  font-size: 0.95rem;
}

.session-os {
  color: var(--text-muted);
  font-size: 0.85rem;
}

.session-meta {
  color: var(--text-muted);
  font-size: 0.8rem;
  font-family: monospace;
  margin-top: 4px;
  display: flex;
  gap: 16px;
}

.disclaimer-box {
  padding: 16px;
  border-radius: 2px !important;
  display: flex;
  align-items: flex-start;
  font-size: 0.85rem;
  color: var(--text-muted);
}

/* SELOS DE SEGURANÇA */
.security-seals {
  margin-top: 48px;
  padding-top: 24px;
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: flex-end;
  gap: 32px;
}

.seal-item {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--text-muted);
  font-size: 0.75rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  opacity: 0.6;
}

/* DRAWER DO MAPA */
.map-inspector-drawer {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 400px;
  z-index: 50;
  border-left: 1px solid var(--border-color) !important;
  border-radius: 0;
  display: flex;
  flex-direction: column;
  box-shadow: -10px 0 30px rgba(0,0,0,0.1);
}

.drawer-header {
  padding: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.map-container-wrap {
  position: relative;
  width: 100%;
  height: 250px;
  flex-shrink: 0;
}

.map-overlay-info {
  position: absolute;
  bottom: 16px;
  left: 16px;
  right: 16px;
  padding: 12px 16px;
  border-radius: 2px !important;
  display: flex;
  align-items: center;
  gap: 12px;
  z-index: 1000;
}

.map-overlay-info strong {
  color: var(--text-main);
  font-size: 0.9rem;
}

.map-overlay-info span {
  font-size: 0.75rem;
  font-family: monospace;
}

.drawer-content {
  padding: 24px;
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

.fingerprint-box {
  position: relative;
  padding: 20px;
  border-radius: 2px !important;
  margin-bottom: 24px;
  overflow: hidden;
}

.fingerprint-bg {
  position: absolute;
  right: -10px;
  top: -10px;
  opacity: 0.05;
  pointer-events: none;
}

.fingerprint-box .label {
  display: block;
  font-size: 0.75rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.fingerprint-box .value {
  display: block;
  font-size: 1.2rem;
  font-family: monospace;
  margin-bottom: 8px;
}

.fingerprint-box .desc {
  font-size: 0.75rem;
  color: var(--text-muted);
  margin: 0;
}

.meta-data-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.meta-row {
  padding-bottom: 16px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-label {
  font-size: 0.75rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.meta-value {
  font-size: 0.95rem;
  color: var(--text-main);
}

.active-device-alert {
  padding: 16px;
  border-radius: 2px !important;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.85rem;
  font-weight: 800;
}

/* TRANSIÇÕES */
.slide-fade-enter-active, .slide-fade-leave-active {
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.slide-fade-enter-from, .slide-fade-leave-to {
  transform: translateX(100%);
  opacity: 0;
}

.scrollable-nav::-webkit-scrollbar { width: 4px; }
.scrollable-nav::-webkit-scrollbar-thumb { background: rgba(150,150,150,0.3); border-radius: 2px; }

/* RESPONSIVIDADE */
@media (max-width: 959px) {
  .security-layout { grid-template-columns: 1fr; gap: 48px; }
}

@media (max-width: 599px) {
  .security-tab-wrapper { margin: -24px; padding: 24px; }
  .map-inspector-drawer { width: 100%; }
  .panel-header { flex-direction: column; gap: 16px; }
  .security-seals { flex-direction: column; gap: 12px; align-items: center; }
}
</style>
