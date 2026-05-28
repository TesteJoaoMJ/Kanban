import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'

type Payload = {
  name: string
  email: string
  password: string
  phone?: string
  document?: string | null
  durationHours?: number
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function normalizeEmail(email: string) {
  return String(email || '').trim().toLowerCase()
}

function normalizePhone(phone?: string) {
  return String(phone || '').replace(/\D/g, '')
}

function makeAccessCode() {
  return `SELLER-${Math.floor(100000 + Math.random() * 900000)}`
}

async function findAuthUserByEmail(supabaseAdmin: any, email: string) {
  let page = 1
  const perPage = 1000

  while (page <= 20) {
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({
      page,
      perPage,
    })

    if (error) throw error

    const user = data?.users?.find((u: any) => normalizeEmail(u.email) === email)
    if (user) return user

    if (!data?.users || data.users.length < perPage) break
    page += 1
  }

  return null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405)
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Variáveis SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY ausentes.' }, 500)
    }

    const authHeader = req.headers.get('Authorization') || ''

    const requesterClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } },
    })

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const token = authHeader.replace('Bearer ', '')
    const { data: authData, error: authError } = await requesterClient.auth.getUser(token)

    if (authError || !authData.user) {
      return json({ error: 'Usuário não autenticado.' }, 401)
    }

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('id, role, full_name')
      .eq('id', authData.user.id)
      .maybeSingle()

    if (profileError) throw profileError

    const allowedRoles = ['super_admin', 'admin', 'gerente', 'vendedor']
    if (!profile || !allowedRoles.includes(profile.role)) {
      return json({ error: 'Você não tem permissão para criar conta de cliente.' }, 403)
    }

    const body = (await req.json()) as Payload
    const email = normalizeEmail(body.email)
    const phone = normalizePhone(body.phone)
    const durationHours = Number(body.durationHours || 12)
    const document = body.document ? String(body.document).replace(/\D/g, '') : null

    if (!body.name || String(body.name).trim().length < 3) {
      return json({ error: 'Nome do cliente inválido.' }, 400)
    }

    if (!email || !/^\S+@\S+\.\S+$/.test(email)) {
      return json({ error: 'E-mail inválido.' }, 400)
    }

    if (!body.password || String(body.password).length < 6) {
      return json({ error: 'Senha deve ter pelo menos 6 caracteres.' }, 400)
    }

    if (!phone || phone.length < 10) {
      return json({ error: 'WhatsApp inválido.' }, 400)
    }

    if (!durationHours || durationHours <= 0) {
      return json({ error: 'Tempo de ativação inválido.' }, 400)
    }

    if (document) {
      const { data: docConflict, error: docConflictError } = await supabaseAdmin
        .from('public_leads')
        .select('id, email')
        .eq('document', document)
        .neq('email', email)
        .maybeSingle()

      if (docConflictError) throw docConflictError

      if (docConflict) {
        return json({
          error: `Este CPF/CNPJ já está vinculado ao e-mail ${docConflict.email}.`,
        }, 409)
      }
    }

    let authUser = await findAuthUserByEmail(supabaseAdmin, email)
    let authAction: 'created' | 'updated' = 'created'

    if (authUser?.id) {
      const { data: updatedUser, error: updateUserError } = await supabaseAdmin.auth.admin.updateUserById(authUser.id, {
        password: String(body.password),
        email_confirm: true,
        user_metadata: {
          ...(authUser.user_metadata || {}),
          name: String(body.name).trim(),
          updated_by_seller: authData.user.id,
          updated_by_seller_name: profile.full_name,
          origin: 'seller_assisted_marketplace_account',
        },
      })

      if (updateUserError) {
        return json({ error: updateUserError.message }, 400)
      }

      authUser = updatedUser.user
      authAction = 'updated'
    } else {
      const { data: createdUser, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password: String(body.password),
        email_confirm: true,
        user_metadata: {
          name: String(body.name).trim(),
          created_by_seller: authData.user.id,
          created_by_seller_name: profile.full_name,
          origin: 'seller_assisted_marketplace_account',
        },
      })

      if (createUserError) {
        return json({ error: createUserError.message }, 400)
      }

      authUser = createdUser.user
      authAction = 'created'
    }

    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + durationHours)

    // ACESSO DIRETO SEM CÓDIGO:
    // O MarketplacePortal libera automaticamente quando access_status='active', prazo futuro
    // e temp_auth_code é NULL. Se temp_auth_code tiver valor, ele entende que precisa validar código.
    const accessCode = null

    // NÃO adiciona auth_user_id aqui.
    // Essa coluna não existe em public_leads no seu banco.
    // Mantemos só campos que o fluxo atual já usa.
    const leadPayload = {
      email,
      name: String(body.name).trim(),
      phone,
      document,
      account_status: 'approved',
      access_status: 'active',
      design_access_status: 'granted',
      auth_code_requested: false,
      temp_auth_code: null,
      temp_auth_expires_at: expiresAt.toISOString(),
      last_ip: null,
      authorized_context: null,
      discovery_source: 'Cadastro assistido pelo vendedor',
    }

    const { data: existingLead, error: existingLeadError } = await supabaseAdmin
      .from('public_leads')
      .select('id, email')
      .eq('email', email)
      .maybeSingle()

    if (existingLeadError) throw existingLeadError

    let lead = null
    let leadAction: 'created' | 'updated' = 'created'

    if (existingLead?.id) {
      const { data: updatedLead, error: updateLeadError } = await supabaseAdmin
        .from('public_leads')
        .update(leadPayload)
        .eq('id', existingLead.id)
        .select('*')
        .single()

      if (updateLeadError) throw updateLeadError

      lead = updatedLead
      leadAction = 'updated'
    } else {
      const { data: createdLead, error: leadError } = await supabaseAdmin
        .from('public_leads')
        .insert([leadPayload])
        .select('*')
        .single()

      if (leadError) {
        if (authAction === 'created' && authUser?.id) {
          await supabaseAdmin.auth.admin.deleteUser(authUser.id)
        }
        throw leadError
      }

      lead = createdLead
    }

    return json({
      status: 'success',
      message: leadAction === 'updated'
        ? 'Conta existente reativada, senha atualizada e acesso direto liberado sem código.'
        : 'Conta criada com acesso direto liberado sem código.',
      user_id: authUser?.id,
      auth_action: authAction,
      lead_action: leadAction,
      access_code: null,
      lead,
    })
  } catch (error) {
    console.error('create-marketplace-lead-account error:', error)
    return json({ error: error?.message || 'Erro inesperado ao criar conta.' }, 500)
  }
})
