import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Variável para guardar o ID e fazer o Rollback Global se der merda
  let createdUserId: string | null = null;
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  );

  try {
    const body = await req.json()
    const {
        email, password, full_name, role, cajuia_role, gestao_click_id,
        store_id, employee_id, company_id, custom_role_id, can_access_crm,
        can_move_cash, is_active, security_pin, avatar_url,
        commission_percentage, permissions, read_only_permissions, delete_permissions
    } = body;

    if (!email || !password || !full_name) {
      throw new Error("Dados insuficientes para criar o usuário. Nome, E-mail e Senha são obrigatórios.");
    }

    // 1. CRIA O USUÁRIO NO AUTH
    const { data: { user }, error: authError } = await adminClient.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
    })

    if (authError) throw authError;
    if (!user) throw new Error("Falha ao obter ID do novo usuário.");

    // Salva o ID para caso precisemos abortar a missão
    createdUserId = user.id;

    // 2. UPSERT NO PROFILES (O Segredo: Força a criação se o gatilho falhar)
    const { error: profileError } = await adminClient
      .from('profiles')
      .upsert({
        id: user.id, // OBRIGATÓRIO PARA O UPSERT
        email: email, // OBRIGATÓRIO PARA O UPSERT
        full_name: full_name,
        role: role || 'user',
        gestao_click_id: gestao_click_id || null,
        store_id: store_id || null,
        employee_id: employee_id || null,
        company_id: company_id || null,
        custom_role_id: custom_role_id || null,
        can_access_crm: can_access_crm ?? false,
        can_move_cash: can_move_cash ?? true,
        is_active: is_active ?? true,
        security_pin: security_pin || null,
        avatar_url: avatar_url || null,
        commission_percentage: commission_percentage || 0,
        permissions: permissions || [],
        read_only_permissions: read_only_permissions || [],
        delete_permissions: delete_permissions || []
      });

    if (profileError) throw profileError;

    // 3. INSERE NA CAJUIA
    if (cajuia_role) {
      const { error: cajuiaError } = await adminClient
          .from('cajuia_permissions')
          .upsert({ user_id: user.id, role: cajuia_role }, { onConflict: 'user_id' });

      if (cajuiaError) throw cajuiaError;
    }

    return new Response(JSON.stringify({
        id: user.id,
        message: 'Usuário criado com sucesso de ponta a ponta!'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    // 🚨 ROLLBACK GLOBAL 🚨
    // Se o código crachar em QUALQUER linha acima, ele entra aqui e apaga o fantasma.
    if (createdUserId) {
      await adminClient.auth.admin.deleteUser(createdUserId).catch(() => console.error("Falha no rollback"));
    }

    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
