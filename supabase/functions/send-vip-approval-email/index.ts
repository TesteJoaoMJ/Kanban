import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, name } = await req.json()
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    if (!RESEND_API_KEY) throw new Error('API Key do Resend não configurada.')

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
                  <div style="display: inline-block; padding: 6px 16px; background-color: #fffbeb; color: #b45309; border-radius: 99px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.15em; margin-bottom: 24px; border: 1px solid #fde68a;">
                    Acesso Exclusivo Liberado
                  </div>

                  <h1 style="margin: 0 0 20px 0; font-size: 26px; font-weight: 900; color: #111827; letter-spacing: -0.03em; line-height: 1.2;">
                    O seu Estúdio de Design<br>está pronto.
                  </h1>

                  <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.7; color: #4b5563;">
                    Olá, <strong>${name}</strong>. É um prazer confirmar que sua marca foi selecionada para o nosso grupo de <strong>Desenvolvimento Exclusivo</strong>.
                  </p>

                  <p style="margin: 0 0 32px 0; font-size: 15px; line-height: 1.7; color: #6b7280;">
                    A partir de agora, você possui um canal direto com nossa equipe criativa para solicitar artes sob medida, mockups em 3D e acesso antecipado às coleções.
                  </p>

                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td align="center">
                        <a href="https://estudiodeestampasmj.com.br/perfil" style="display: inline-block; padding: 18px 42px; background-color: #000000; color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 800; border-radius: 12px; text-transform: uppercase; letter-spacing: 0.05em;">
                          Entrar no Estúdio
                        </a>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr>
                <td style="padding: 32px 50px; background-color: #fafafa; border-top: 1px solid #f3f4f6; text-align: center;">
                  <p style="margin: 0 0 8px 0; font-size: 12px; color: #6b7280; line-height: 1.6;">
                    Este é um canal direto e restrito.<br>
                    <strong>Por favor, não responda a este e-mail automático.</strong>
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
                  <p style="margin: 0; font-size: 10px; color: rgba(255,255,255,0.7);">
                    Toda arte desenvolvida neste estúdio é protegida por direitos autorais.<br>
                    A reprodução não autorizada está sujeita às sanções legais.
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
        from: 'Estúdio MJ <nao-responda@estudiodeestampasmj.com.br>',
        to: email,
        subject: '✨ Acesso Exclusivo Liberado: Estúdio de Design MJ',
        html: htmlContent
      })
    })

    const data = await res.json()
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
