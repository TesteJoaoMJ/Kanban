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

    // URLs das imagens armazenadas publicamente no seu Supabase
    const LOGO_URL = 'https://drprfuinwglmzquqtqzq.supabase.co/storage/v1/object/public/catalog-assets/logomjlm.png'
    const BG_URL = 'https://drprfuinwglmzquqtqzq.supabase.co/storage/v1/object/public/catalog-assets/aprovacaoconta.jpg'

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8">
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap');
      </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #e2e8f0; font-family: 'Inter', -apple-system, sans-serif;">

      <table width="100%" border="0" cellspacing="0" cellpadding="0" background="${BG_URL}" style="background-color: #e2e8f0; background-image: url('${BG_URL}'); background-size: cover; background-position: center; padding: 60px 20px;">
        <tr>
          <td align="center">

            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 540px; background-color: #ffffff; border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.15); overflow: hidden;">

              <tr>
                <td align="center" style="padding: 48px 40px 20px 40px;">
                  <img src="${LOGO_URL}" alt="MJ Process" width="120" style="display: block;" />
                </td>
              </tr>

              <tr>
                <td style="padding: 20px 50px 40px 50px; text-align: center;">
                  <div style="display: inline-block; padding: 6px 14px; background-color: #f0fdf4; color: #16a34a; border-radius: 99px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 24px;">
                    Cadastro Verificado
                  </div>

                  <h1 style="margin: 0 0 16px 0; font-size: 26px; font-weight: 900; color: #0f172a; letter-spacing: -0.025em; line-height: 1.2;">
                    Sua marca agora faz parte do nosso Acervo.
                  </h1>

                  <p style="margin: 0 0 24px 0; font-size: 15px; line-height: 1.6; color: #475569;">
                    Olá, <strong>${name}</strong>. Nossa curadoria aprovou seu acesso. Você já pode explorar as coleções exclusivas e solicitar produções de alto padrão.
                  </p>

                  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-top: 32px;">
                    <tr>
                      <td align="center">
                        <a href="https://estudiodeestampasmj.com.br/marketplace-login" style="display: inline-block; padding: 16px 36px; background-color: #000000; color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 700; border-radius: 12px;">
                          Entrar no Catálogo
                        </a>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr>
                <td style="padding: 30px 50px; background-color: #f8fafc; border-top: 1px solid #f1f5f9; text-align: center;">
                  <p style="margin: 0; font-size: 12px; color: #64748b; line-height: 1.5;">
                    Este é um canal exclusivo para parceiros da MJ.<br>
                    <strong>Não responda a este e-mail.</strong>
                  </p>
                </td>
              </tr>
            </table>

            <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 540px; margin-top: 24px;">
              <tr>
                <td align="center" style="padding: 20px; background-color: rgba(0,0,0,0.6); border-radius: 12px; backdrop-filter: blur(4px);">
                  <p style="margin: 0 0 4px 0; font-size: 11px; color: #ffffff; font-weight: 700; letter-spacing: 0.05em;">
                    &copy; 2026 MJ PROCESS &bull; INDÚSTRIA TÊXTIL PREMIUM
                  </p>
                  <p style="margin: 0; font-size: 10px; color: rgba(255,255,255,0.7);">
                    Todos os direitos reservados sobre as estampas e coleções.<br>
                    O acesso ao acervo é pessoal, intransferível e monitorado.
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
        from: 'Acervo MJ <nao-responda@estudiodeestampasmj.com.br>',
        to: email,
        subject: 'Acesso Liberado: Explore o Catálogo Premium MJ',
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
