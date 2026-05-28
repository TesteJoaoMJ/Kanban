import { defineStore } from 'pinia'
import { supabase } from '@/api/supabase'
import { useMarketplaceUserStore } from '@/stores/marketplaceUser'

export type RiskFlag = 'none' | 'low' | 'medium' | 'high'
export type AccessStatus = 'active' | 'revalidation_required' | 'blocked'
export type ProtectionContext = 'catalog' | 'discover' | 'art_detail' | 'checkout' | 'unknown'

interface SecurityEvent {
  session_id: string
  user_id?: string | null
  context: ProtectionContext
  event_type: 'exposure' | 'interaction' | 'scroll' | 'zoom' | 'violation'
  art_id?: string
  visible_duration?: number
  timestamp: number
  metadata_json?: any
}

interface ProtectionState {
  sessionId: string
  currentContext: ProtectionContext
  riskScore: number
  riskFlag: RiskFlag
  accessStatus: AccessStatus
  blockedUntil: string | null
  riskReason: string | null

  consecutiveStrikes: number
  plagiarismStrikes: number // Nova memória focada em roubo de conteúdo

  eventQueue: SecurityEvent[]
  recentExposures: SecurityEvent[]
  recentInteractions: SecurityEvent[]

  isInitialized: boolean
  syncInterval: ReturnType<typeof setInterval> | null
}

export const useProtectionStore = defineStore('protection', {
  state: (): ProtectionState => ({
    sessionId: '',
    currentContext: 'unknown',
    riskScore: 0,
    riskFlag: 'none',
    accessStatus: 'active',
    blockedUntil: null,
    riskReason: null,

    consecutiveStrikes: 0,
    plagiarismStrikes: 0,

    eventQueue: [],
    recentExposures: [],
    recentInteractions: [],

    isInitialized: false,
    syncInterval: null
  }),

  getters: {
    isBlocked: (state) => state.accessStatus === 'blocked',
    requiresRevalidation: (state) => state.accessStatus === 'revalidation_required',

    currentUserId: () => {
      const userStore = useMarketplaceUserStore()
      return userStore.user?.id || null
    },

    protectionLevel: (state): number => {
      if (state.accessStatus === 'blocked') return 3
      if (state.accessStatus === 'revalidation_required') return 2
      if (state.riskFlag === 'medium' || state.riskFlag === 'high') return 1
      return 0
    },

    watermarkOpacity: (state) => {
      if (state.riskFlag === 'none') return 0.01
      if (state.riskFlag === 'low') return 0.03
      if (state.riskFlag === 'medium') return 0.06
      return 0.1
    }
  },

  actions: {
    async initializeGuard() {
      if (this.isInitialized) return

      let storedSession = localStorage.getItem('mj_security_session_id')
      if (!storedSession) {
        storedSession = crypto.randomUUID()
        localStorage.setItem('mj_security_session_id', storedSession)
      }
      this.sessionId = storedSession

      await this.fetchStatusFromBackend()

      this.syncInterval = setInterval(() => {
        this.flushEvents()
        this.cleanSlidingWindows()
      }, 10000)

      this.isInitialized = true
    },

    setContext(context: ProtectionContext) {
      this.currentContext = context
      this.recentExposures = []
      this.recentInteractions = []
    },

    // Ação específica para punir tentativa de plágio (F12, Botão Direito, Salvar)
    registerPlagiarismAttempt() {
      this.plagiarismStrikes += 1;

      const event: SecurityEvent = {
        session_id: this.sessionId,
        user_id: this.currentUserId,
        context: this.currentContext,
        event_type: 'violation',
        metadata_json: { action: 'plagiarism_attempt', strike: this.plagiarismStrikes },
        timestamp: Date.now()
      }
      this.eventQueue.push(event)

      if (this.plagiarismStrikes === 1) {
        this.applyPenalty(35, 'plagiarism_attempt_warning_1');
      } else if (this.plagiarismStrikes === 2) {
        this.applyPenalty(40, 'plagiarism_attempt_warning_2');
      } else if (this.plagiarismStrikes >= 3) {
        // Terceiro strike é bloqueio imediato e implacável.
        this.riskScore = 100;
        this.applyPenalty(100, 'plagiarism_attempt_block');
      }
    },

    logExposure(artId: string, visibleDurationMs: number) {
      const durationSeconds = visibleDurationMs / 1000

      if (durationSeconds >= 5) {
         this.applyPenalty(-15, 'long_pause_observation');
      }

      const event: SecurityEvent = {
        session_id: this.sessionId,
        user_id: this.currentUserId,
        context: this.currentContext,
        event_type: 'exposure',
        art_id: artId,
        visible_duration: durationSeconds,
        timestamp: Date.now()
      }

      this.recentExposures.push(event)
      this.eventQueue.push(event)
      this.evaluateHeuristicRisk()
    },

    logInteraction(type: 'click' | 'zoom' | 'favorite' | 'manual_load', artId: string) {
      if (['click', 'zoom', 'favorite'].includes(type)) {
         this.applyPenalty(-20, 'real_human_interaction');
         this.consecutiveStrikes = 0;
      }

      const event: SecurityEvent = {
        session_id: this.sessionId,
        user_id: this.currentUserId,
        context: this.currentContext,
        event_type: 'interaction',
        art_id: artId,
        metadata_json: { action: type },
        timestamp: Date.now()
      }

      this.recentInteractions.push(event)
      this.eventQueue.push(event)
      this.evaluateHeuristicRisk()
    },

    evaluateHeuristicRisk() {
      if (this.isBlocked) return

      const now = Date.now()
      const twoMinsAgo = now - (2 * 60 * 1000)
      const fourMinsAgo = now - (4 * 60 * 1000)

      const activeExposures = this.recentExposures.filter(e => e.timestamp > twoMinsAgo)
      const activeInteractions = this.recentInteractions.filter(e => e.timestamp > twoMinsAgo)

      const exposureCount = activeExposures.length

      const manualLoads = activeInteractions.filter(i => i.metadata_json?.action === 'manual_load').length
      const realClicks = activeInteractions.filter(i => ['click', 'zoom', 'favorite'].includes(i.metadata_json?.action)).length
      const longPauses = activeExposures.filter(e => (e.visible_duration || 0) >= 5).length

      const avgVisibleTime = exposureCount > 0
        ? activeExposures.reduce((acc, curr) => acc + (curr.visible_duration || 0), 0) / exposureCount
        : 0

      if (this.currentContext === 'discover') {
        if (manualLoads >= 3 && realClicks === 0 && longPauses === 0) {
          this.consecutiveStrikes = (this.consecutiveStrikes || 0) + 1;
          const compoundedPenalty = 30 * this.consecutiveStrikes;
          this.applyPenalty(compoundedPenalty, 'spam_pagination_recidivism')
          this.recentInteractions = this.recentInteractions.filter(i => i.metadata_json?.action !== 'manual_load')
        }

        else if (exposureCount >= 40 && realClicks === 0 && longPauses === 0 && avgVisibleTime < 3.5) {
          this.consecutiveStrikes = (this.consecutiveStrikes || 0) + 1;
          const compoundedPenalty = 25 * this.consecutiveStrikes;
          this.applyPenalty(compoundedPenalty, 'fast_scroll_recidivism')
          this.recentExposures = this.recentExposures.slice(-10);
        }
      }

      if (this.currentContext === 'catalog') {
        const catalogExposures = this.recentExposures.filter(e => e.timestamp > fourMinsAgo).length
        if (catalogExposures >= 40 && realClicks === 0 && avgVisibleTime < 5) {
          this.consecutiveStrikes = (this.consecutiveStrikes || 0) + 1;
          const compoundedPenalty = 25 * this.consecutiveStrikes;
          this.applyPenalty(compoundedPenalty, 'fast_catalog_sweep_recidivism')
          this.recentExposures = this.recentExposures.slice(-10);
        }
      }
    },

    async applyPenalty(points: number, reason: string) {
      if (points === 0) return

      this.riskScore += points;
      if (this.riskScore < 0) this.riskScore = 0;

      if (this.riskScore >= 100) {
        this.accessStatus = 'blocked';
        this.riskFlag = 'high';
      } else if (this.riskScore >= 70) {
        this.accessStatus = 'revalidation_required';
        this.riskFlag = 'high';
      } else if (this.riskScore >= 40) {
        this.riskFlag = 'medium';
      } else if (this.riskScore >= 20) {
        this.riskFlag = 'low';
      } else {
        this.riskFlag = 'none';
      }

      try {
        const { data, error } = await supabase.rpc('update_session_risk', {
          p_session_id: this.sessionId,
          p_user_id: this.currentUserId,
          p_score_add: points,
          p_reason: reason,
          p_context: this.currentContext
        })

        if (!error && data) {
          if (data.risk_score !== undefined) this.riskScore = data.risk_score;
          if (data.risk_flag !== undefined) this.riskFlag = data.risk_flag;
          if (data.access_status !== undefined) this.accessStatus = data.access_status;
          if (data.blocked_until !== undefined) this.blockedUntil = data.blocked_until;
        }
      } catch (err) {
        console.error('Security Guard: Erro Exception', err)
      }
    },

    async fetchStatusFromBackend() {
      try {
        const { data } = await supabase
          .from('security_profiles')
          .select('risk_score, risk_flag, access_status, blocked_until, current_context')
          .eq('session_id', this.sessionId)
          .maybeSingle()

        if (data) {
          this.riskScore = data.risk_score
          this.riskFlag = data.risk_flag
          this.accessStatus = data.access_status
          this.blockedUntil = data.blocked_until

          if (this.accessStatus === 'blocked' && this.blockedUntil) {
            if (new Date() > new Date(this.blockedUntil)) {
              this.accessStatus = 'active'
              this.riskScore = 0
              this.riskFlag = 'none'
            }
          }
        }
      } catch (e) {}
    },

    async flushEvents() {
      if (this.eventQueue.length === 0) return

      const eventsToSend = [...this.eventQueue]
      this.eventQueue = []

      try {
        await supabase.rpc('log_security_events', { p_events: eventsToSend })
      } catch (err) {
        this.eventQueue = [...eventsToSend, ...this.eventQueue]
      }
    },

    cleanSlidingWindows() {
      const fiveMinsAgo = Date.now() - (5 * 60 * 1000)
      this.recentExposures = this.recentExposures.filter(e => e.timestamp > fiveMinsAgo)
      this.recentInteractions = this.recentInteractions.filter(e => e.timestamp > fiveMinsAgo)
    },

    async clearRevalidation() {
      try {
        const { data, error } = await supabase.rpc('update_session_risk', {
          p_session_id: this.sessionId,
          p_user_id: this.currentUserId,
          p_score_add: -30,
          p_reason: 'manual_revalidation_passed',
          p_context: this.currentContext
        })
        if (!error && data) {
          this.riskScore = data.risk_score
          this.riskFlag = data.risk_flag
          this.accessStatus = data.access_status
        }
      } catch (err) {}
    }
  }
})
