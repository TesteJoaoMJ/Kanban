import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';
import type { Profile } from '@/types';

declare global {
  interface Window {
    electronApi?: {
      setUserId: (userId: string | null) => void;
    };
  }
}

export const useUserStore = defineStore('user', {
  state: () => ({
    session: null as any | null,
    profile: null as Profile | null,
    cajuiaRole: null as string | null,
    showTermsModal: false,
    isAcceptingTerms: false,
    currentModule: (localStorage.getItem('mj_current_module') as 'mj' | 'cajuia' | null),
    // Estado para Admin selecionar loja contextualmente
    adminSelectedStore: null as { id: string; name: string } | null,
  }),

  getters: {
    isLoggedIn: (state) => !!state.session,

    // --- ROLES & PERMISSÕES ---

    // Verifica se é especificamente Super Admin (para o dashboard Holding)
    isSuperAdmin: (state) => state.profile?.role === 'super_admin',

    // Verifica se é Admin OU Super Admin (para permissões gerais de admin)
    isAdmin: (state) => ['admin', 'super_admin'].includes(state.profile?.role || ''),

    // Alias para compatibilidade com código existente que usa isGlobalAdmin
    isGlobalAdmin(): boolean {
        return this.isAdmin;
    },

    user: (state) => state.session?.user,

    canAccessCrm: (state) => state.profile?.can_access_crm === true,

    // --- VERIFICAÇÃO DE PERMISSÕES GRANULARES ---
    hasPermission: (state) => (permission: string) => {
        // Apenas Super Admin tem acesso irrestrito garantido
        if (state.profile?.role === 'super_admin') return true;

        // O 'admin' comum agora passará por esta verificação do custom_role
        // @ts-ignore
        return state.profile?.permissions?.includes(permission) || false;
    },

    // --- PERMISSÕES DE MÓDULO ---

    isCajuiaAdmin: (state) => state.cajuiaRole === 'admin_cajuia',
    isCajuiaVendedor: (state) => state.cajuiaRole === 'vendedor_cajuia',

    canAccessCajuia(state): boolean {
      return this.isGlobalAdmin || !!state.cajuiaRole;
    },

    canAccessMJProcess(state): boolean {
      return this.hasMJAccess;
    },

    hasMJAccess(state): boolean {
      const role = state.profile?.role;
      const allowedRoles = [
        'super_admin',
        'admin',
        'vendedor',
        'designer',
        'producao',
        'gerente',
        'financeiro',
        'impressor',
        'faturador'
      ];
      return allowedRoles.includes(role || '');
    },

    hasCajuiaAccess(state): boolean {
      // Admin e Super Admin têm acesso irrestrito
      return this.isGlobalAdmin || !!state.cajuiaRole;
    },

    activeModuleName(): string {
        if (this.currentModule === 'cajuia') return 'Cajuia Store';
        if (this.currentModule === 'mj') return 'MJ Process';
        return 'Portal';
    },

    // --- LÓGICA DE LOJA ATIVA (MULTI-TENANCY) ---
    activeStoreId(state): string | null {
        // 1. Se for Admin/SuperAdmin, prioriza a loja que ele escolheu manualmente
        if (this.isAdmin) {
            return state.adminSelectedStore?.id || null;
        }
        // 2. Se for Vendedor (ou outros), usa a loja vinculada ao perfil
        return state.profile?.store_id || null;
    },

    activeStoreName(state): string {
        if (this.isAdmin) {
            return state.adminSelectedStore?.name || 'Modo Admin (Sem Loja)';
        }
        // @ts-ignore - Supabase join retorna 'store' como objeto
        return state.profile?.store?.name || 'Loja Não Definida';
    }
  },

  actions: {
    setModule(module: 'mj' | 'cajuia' | null) {
        this.currentModule = module;
        if (module) {
            localStorage.setItem('mj_current_module', module);
        } else {
            localStorage.removeItem('mj_current_module');
        }
    },

    // Ação para o Admin trocar de contexto
    setAdminStore(store: { id: string; name: string } | null) {
        this.adminSelectedStore = store;
    },

    async fetchSession() {
      const { data: sessionData, error: sessionError } = await supabase.auth.getSession();

      if (sessionError || !sessionData.session) {
        this.session = null;
        return;
      }

      const { data: userData, error: userError } = await supabase.auth.getUser();

      if (userError || !userData.user) {
        // Se o token for fantasma, limpa TUDO sem recarregar a tela,
        // deixando o Router te jogar pro Login de forma natural.
        this.session = null;

        const keysToRemove = Object.keys(localStorage).filter(k => k.includes('auth-token') || k.includes('supabase'));
        keysToRemove.forEach(k => localStorage.removeItem(k));

        return;
      }

      this.session = sessionData.session;

      if (window.electronApi && typeof window.electronApi.setUserId === 'function') {
        window.electronApi.setUserId(this.session.user.id);
      }

      if (this.session) {
        await Promise.all([
            this.fetchProfile(),
            this.fetchCajuiaRole()
        ]);
      }
    },

    async fetchProfile() {
      if (!this.session?.user) return;
      try {
        // CORREÇÃO APLICADA: .maybeSingle() em vez de .single()
        // Isso impede que clientes do site (public_leads) gerem o erro PGRST116
        // ao não serem encontrados na tabela profiles do ERP.
        const { data: profileData, error } = await supabase
          .from('profiles')
          .select('*, store:store_id(id, name), can_move_cash, permissions')
          .eq('id', this.session.user.id)
          .maybeSingle();

        if (error) throw error;

        if (profileData) {
            this.profile = {
                ...profileData,
                store_id: profileData.store_id || null
            };

            if (!profileData.has_accepted_terms) {
              this.showTermsModal = true;
            }
        } else {
            // Se não encontrou o perfil, é porque é um cliente da 'public_leads'.
            // Mantemos nulo sem disparar erros no console.
            this.profile = null;
        }

      } catch (e) {
        console.error('Erro ao buscar perfil do usuário:', e);
        this.profile = null;
      }
    },

    async fetchCajuiaRole() {
      if (!this.session?.user) return;
      try {
        const { data, error } = await supabase
          .from('cajuia_permissions')
          .select('role')
          .eq('user_id', this.session.user.id)
          .maybeSingle();

        if (error) throw error;
        this.cajuiaRole = data ? data.role : null;
      } catch (e) {
        this.cajuiaRole = null;
      }
    },

    async acceptTerms() {
      if (!this.profile) return;
      this.isAcceptingTerms = true;
      try {
        const { error } = await supabase
          .from('profiles')
          .update({ has_accepted_terms: true })
          .eq('id', this.profile.id);

        if (error) throw error;
        this.profile.has_accepted_terms = true;
        this.showTermsModal = false;
      } catch (e) {
        console.error('Erro ao salvar aceite dos termos:', e);
      } finally {
        this.isAcceptingTerms = false;
      }
    },

    async signOut() {
      // 1. Desloga oficialmente no Supabase PRIMEIRO (Isso limpa a memória RAM e o servidor)
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.warn("Erro silencioso ao deslogar do Supabase:", e);
      }

      // 2. Limpa variáveis de estado do Pinia
      this.session = null;
      this.profile = null;
      this.cajuiaRole = null;
      this.currentModule = null;
      this.adminSelectedStore = null;
      this.showTermsModal = false;

      // 3. Limpeza profunda do Disco (Fallback de segurança)
      localStorage.removeItem('mj_current_module');
      localStorage.removeItem('activeCompany');
      localStorage.removeItem('activeContext');

      const keysToRemove = Object.keys(localStorage).filter(k => k.includes('auth-token') || k.includes('supabase'));
      keysToRemove.forEach(k => localStorage.removeItem(k));

      try {
        if (window.electronApi && typeof window.electronApi.setUserId === 'function') {
          window.electronApi.setUserId(null);
        }
      } catch (e) {}
    }
  },
});
