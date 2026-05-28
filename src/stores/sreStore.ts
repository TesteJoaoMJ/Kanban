import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';

export const useSreStore = defineStore('sre', {
  state: () => ({
    incidents: [] as any[],
    liveFeed: [] as any[],
    isRealtimeOnline: false,
    lastScan: null as string | null,
    metrics: {
      sales: { activeDrafts: 0, todayOrders: 0 },
      pcp: { stuckOrders: 0, negativeStock: 0 }
    }
  }),
  getters: {
    criticals: (state) => state.incidents.filter(i => i.severity === 'critical' && i.status === 'open'),
    byModule: (state) => (mod: string) => state.incidents.filter(i => i.module === mod && i.status === 'open'),
  },
  actions: {
    // 1. BOOTSTRAP REAL (O que faltou da última vez)
    async bootstrapSystem() {
      // Força a reconciliação no banco para achar erros antigos
      await supabase.rpc('sre_run_reconciliation');

      // Puxa os incidentes
      const { data: inc } = await supabase.from('sre_incidents').select('*').eq('status', 'open').order('created_at', { ascending: false });
      if (inc) this.incidents = inc;

      // Puxa o histórico recente de telemetria
      const { data: feed } = await supabase.from('sre_live_telemetry').select('*').order('created_at', { ascending: false }).limit(30);
      if (feed) this.liveFeed = feed;

      this.lastScan = new Date().toLocaleTimeString();
      this.initRealtime();
    },

    initRealtime() {
      supabase.channel('sre_ops')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'sre_incidents' }, payload => {
          this.bootstrapSystem(); // Refetch simplificado
        })
        .subscribe((status) => { this.isRealtimeOnline = status === 'SUBSCRIBED'; });
    },

    // RUNBOOK: Corrigir Colisão de Draft
    async runbookFixDraftCollision(incident: any) {
      try {
        // Usa a sua função nativa de calcular o número seguro (que verifica orders e drafts)
        const { data: nextNumber, error: calcErr } = await supabase.rpc('get_next_order_number');
        if (calcErr) throw calcErr;

        // Executa a correção segura
        const { error: updErr } = await supabase.from('order_drafts')
          .update({ reserved_order_number: nextNumber })
          .eq('id', incident.context_data.draft_id);
        if (updErr) throw updErr;

        // Registra a resolução e fecha o incidente
        await supabase.from('sre_incidents')
          .update({ status: 'resolved', resolved_at: new Date().toISOString() })
          .eq('id', incident.id);

        await this.bootstrapSystem();
        return { success: true, message: `Rascunho redirecionado para o Pedido #${nextNumber} com sucesso.` };
      } catch (err: any) {
        return { success: false, message: err.message };
      }
    }
  }
});
