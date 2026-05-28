// supabase/functions/secure-audit/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (userError || !user) throw new Error('Unauthorized')

    const reqBody = await req.json()
    const secretKey = Deno.env.get('AUDIT_SECRET_KEY') || 'default-secret-CHANGE-ME'

    // --- MODO DE VERIFICAÇÃO (INTEGRIDADE) ---
    if (reqBody.action === 'verify') {
        const { log_id } = reqBody

        // 1. Busca o log original no banco (como ele está agora)
        const { data: log, error: fetchError } = await supabaseAdmin
            .from('audit_logs')
            .select('*')
            .eq('id', log_id)
            .single()

        if (fetchError || !log) throw new Error('Log not found')

        // 2. Reconstrói a string de assinatura usando os dados do banco + SEGREDO
        // Nota: A ordem e o formato devem ser EXATAMENTE iguais ao da criação
        // payload deve ser stringificado da mesma forma.
        const dataToSign = `${log.user_id}:${log.action_type}:${log.ip_address}:${log.created_at}:${JSON.stringify(log.payload)}:${secretKey}`

        const encoder = new TextEncoder()
        const data = encoder.encode(dataToSign)
        const hashBuffer = await crypto.subtle.digest('SHA-256', data)
        const calculatedHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('')

        // 3. Compara
        const isValid = calculatedHash === log.audit_hash

        return new Response(JSON.stringify({
            valid: isValid,
            calculated: calculatedHash, // Útil para debug (remover em prod se quiser)
            stored: log.audit_hash
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })
    }

    // --- MODO DE CRIAÇÃO (INSERT) ---
    const { action_type, target_id, payload, device_fingerprint } = reqBody
    const ip = req.headers.get('x-forwarded-for') || 'unknown'
    const userAgent = req.headers.get('user-agent') || 'unknown'

    const rawHeaders: any = {}
    req.headers.forEach((value, key) => { rawHeaders[key] = value })

    const timestamp = new Date().toISOString()
    const dataToSign = `${user.id}:${action_type}:${ip}:${timestamp}:${JSON.stringify(payload)}:${secretKey}`

    const encoder = new TextEncoder()
    const data = encoder.encode(dataToSign)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const auditHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('')

    const { error: insertError } = await supabaseAdmin
      .from('audit_logs')
      .insert({
        user_id: user.id,
        action_type,
        target_id,
        ip_address: ip,
        user_agent: userAgent,
        device_fingerprint,
        payload,
        request_headers: rawHeaders,
        audit_hash: auditHash,
        created_at: timestamp
      })

    if (insertError) throw insertError

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
