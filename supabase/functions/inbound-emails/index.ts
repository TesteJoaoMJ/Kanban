import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // O provedor de e-mail envia um POST via Webhook. Precisamos garantir que é o método certo.
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    // 1. Pega o corpo da requisição que o provedor (ex: Resend) enviou
    const payload = await req.json()

    // 2. Inicia o Supabase usando a Service Role Key para ignorar o RLS na hora de inserir
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 3. Extrai os dados (Estamos usando o formato padrão do Resend como base)
    // Nota: Dependendo do provedor, esses campos podem vir em minúsculo (ex: payload.from)
    const from = payload.from || payload.From || 'desconhecido'
    const to = payload.to || payload.To || 'desconhecido'
    const subject = payload.subject || payload.Subject || '(Sem Assunto)'
    const htmlBody = payload.html || payload.HtmlBody || payload.text || ''
    const textBody = payload.text || payload.TextBody || ''

    // 4. Salva no banco de dados na tabela que acabamos de criar
    const { error } = await supabase.from('emails').insert({
      direction: 'inbound',
      from_address: from,
      to_address: to,
      subject: subject,
      html_body: htmlBody,
      text_body: textBody,
      is_read: false
    })

    if (error) {
      console.error('Erro ao inserir no Supabase:', error)
      return new Response(JSON.stringify({ error: error.message }), { status: 400 })
    }

    // 5. Retorna sucesso para o provedor de e-mail parar de tentar enviar
    return new Response(JSON.stringify({ message: 'E-mail recebido e salvo com sucesso!' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (err) {
    console.error('Erro na Edge Function:', err)
    return new Response(JSON.stringify({ error: 'Erro interno no processamento' }), { status: 500 })
  }
})
