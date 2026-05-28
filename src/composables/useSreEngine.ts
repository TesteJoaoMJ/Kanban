import { supabase } from '@/api/supabase';
import { useSreStore } from '@/stores/sreStore';

export function useSreEngine() {
  const store = useSreStore();

  // Função de Bootstrap (Roda ao abrir a tela)
  const bootstrapSre = async () => {
    const { data, error } = await supabase
      .from('sre_incidents')
      .select('*')
      .neq('status', 'resolved')
      .order('created_at', { ascending: false });

    if (!error && data) {
      store.setIncidents(data);
    }
  };

  // Inicializa o Realtime Subscriptions
  const initRealtime = () => {
    supabase.channel('sre_channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sre_incidents' }, payload => {
        store.addOrUpdateIncident(payload.new as any);
      })
      .subscribe((status) => {
        store.isRealtimeConnected = status === 'SUBSCRIBED';
      });
  };

  // === RUNBOOKS (Ações Corretivas Seguras) ===

  const runbookFixDraftCollision = async (incident: any) => {
    try {
      // 1. Usa a função que já existe no seu DB para calcular o próximo número real
      const { data: nextNumber, error: fnError } = await supabase.rpc('get_next_order_number');
      if (fnError) throw fnError;

      // 2. Tira o draft do caminho de colisão
      const draftId = incident.context_data.draft_id;
      const { error: updateError } = await supabase
        .from('order_drafts')
        .update({ reserved_order_number: nextNumber })
        .eq('id', draftId);
      if (updateError) throw updateError;

      // 3. Marca o incidente como resolvido e registra auditoria
      await resolveIncident(incident.id, `Corrigido via Cockpit. Novo número atribuído: ${nextNumber}`);

      return { success: true, newNumber: nextNumber };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  const resolveIncident = async (incidentId: string, actionNote: string) => {
    const userId = (await supabase.auth.getUser()).data.user?.id;

    // Atualiza o incidente
    await supabase.from('sre_incidents')
      .update({ status: 'resolved', resolved_at: new Date().toISOString(), resolved_by: userId })
      .eq('id', incidentId);

    // Registra na auditoria SRE
    await supabase.from('sre_audit_logs').insert({
      incident_id: incidentId,
      action_type: 'RESOLVE_INCIDENT',
      performed_by: userId,
      metadata: { note: actionNote }
    });
  };

  return { bootstrapSre, initRealtime, runbookFixDraftCollision, resolveIncident };
}
