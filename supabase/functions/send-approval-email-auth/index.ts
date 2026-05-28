import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Lida com a requisição de preflight do CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, name, code } = await req.json()
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    if (!RESEND_API_KEY) throw new Error('API Key do Resend não configurada nos Secrets.')
    if (!email || !code) throw new Error('Email e Código são obrigatórios.')

    const LOGO_URL = 'https://drprfuinwglmzquqtqzq.supabase.co/storage/v1/object/public/catalog-assets/logomjlm.png'
    const BG_URL = 'https://drprfuinwglmzquqtqzq.supabase.co/storage/v1/object/public/catalog-assets/aprovacaodesenvolvimento.jpg'

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8">
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap');
      </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #1e293b; font-family: 'Inter', -apple-system, sans-serif;">

      <table width="100%" border="0" cellspacing="0" cellpadding="0" background="${BG_URL}" style="background-color: #1e293b; background-image: url('${BG_URL}'); background-size: cover; background-position: center; padding: 60px 20px;">
        <tr>
          <td align="center">

            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 540px; background-color: #ffffff; border-radius: 20px; box-shadow: 0 25px 50px rgba(0,0,0,0.3); overflow: hidden;">

              <tr>
                <td align="center" style="padding: 48px 40px 20px 40px;">
                  <img src="${LOGO_URL}" alt="MJ Process" width="130" style="display: block;" />
                </td>
              </tr>

              <tr>
                <td style="padding: 20px 50px 40px 50px; text-align: center;">

                  <div style="display: inline-block; padding: 6px 16px; background-color: #f0fdf4; color: #166534; border-radius: 99px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.15em; margin-bottom: 24px; border: 1px solid #bbf7d0;">
                    Acesso Exclusivo Liberado
                  </div>

                  <h1 style="margin: 0 0 20px 0; font-size: 26px; font-weight: 900; color: #111827; letter-spacing: -0.03em; line-height: 1.2;">
                    Seu acesso ao Acervo<br>Premium está pronto.
                  </h1>

                  <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.7; color: #4b5563;">
                    Olá, <strong>${name || 'Cliente'}</strong>. Sua chave de segurança foi gerada com sucesso e garantirá sua entrada no nosso catálogo exclusivo.
                  </p>

                  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin: 0 0 32px 0;">
                    <tr>
                      <td align="center" style="background-color: #f8fafc; padding: 28px 20px; border-radius: 16px; border: 2px dashed #cbd5e1;">
                        <p style="margin: 0 0 12px 0; font-size: 11px; color: #64748b; font-weight: 800; text-transform: uppercase; letter-spacing: 0.2em;">
                          Chave de Acesso (Válida por 12h)
                        </p>
                        <div style="font-size: 42px; font-weight: 900; color: #0f172a; letter-spacing: 0.25em; line-height: 1; text-shadow: 2px 2px 0px rgba(0,0,0,0.05);">
                          ${code}
                        </div>
                      </td>
                    </tr>
                  </table>

                  <p style="margin: 0 0 32px 0; font-size: 15px; line-height: 1.7; color: #6b7280;">
                    Copie a chave acima e insira-a na tela de validação para desbloquear a visualização das nossas coleções de alto padrão.
                  </p>

                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td align="center">
                        <a href="https://estudiodeestampasmj.com.br/marketplace-login" style="display: inline-block; padding: 18px 42px; background-color: #000000; color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 800; border-radius: 12px; text-transform: uppercase; letter-spacing: 0.05em;">
                          Acessar o Acervo Digital
                        </a>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr>
                <td style="padding: 32px 50px; background-color: #fafafa; border-top: 1px solid #f3f4f6; text-align: center;">
                  <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280; line-height: 1.6;">
                    Este é um e-mail automático do sistema de segurança.<br>
                    <strong>Por favor, não responda a este e-mail.</strong>
                  </p>
                </td>
              </tr>
            </table>

            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 540px; margin-top: 24px;">
              <tr>
                <td align="center" style="padding: 20px; background-color: rgba(0,0,0,0.7); border-radius: 12px; backdrop-filter: blur(4px);">
                  <p style="margin: 0 0 4px 0; font-size: 11px; color: #fde68a; font-weight: 800; letter-spacing: 0.08em;">
                    &copy; 2026 MJ PROCESS &bull; DESIGN &AMP; TECNOLOGIA
                  </p>
                  <p style="margin: 0; font-size: 10px; color: rgba(255,255,255,0.7); line-height: 1.5;">
                    Todo o acervo digital é protegido por direitos autorais.<br>
                    O compartilhamento da chave de acesso com terceiros é estritamente proibido.
                  </p>
                </td>
              </tr>
            </table>

          </td>
        </tr>
      </table>
    </body>
    </html>
    `

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`
      },
      body: JSON.stringify({
        from: 'Acervo Digital MJ <nao-responda@estudiodeestampasmj.com.br>',
        to: email,
        subject: '🔑 Acesso Liberado: Sua chave do Acervo Digital MJ',
        html: htmlContent
      })
    })

    const data = await res.json()

    if (!res.ok) throw new Error(data.message || 'Erro do Resend')

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
