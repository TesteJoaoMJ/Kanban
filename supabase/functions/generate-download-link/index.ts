import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.17"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Lidar com o CORS para o Vue.js não bloquear
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { purchase_id } = await req.json()
    const authHeader = req.headers.get('Authorization')

    if (!authHeader) throw new Error('Token de autenticação ausente.')
    if (!purchase_id) throw new Error('ID da compra não fornecido.')

    // 1. Iniciar o Supabase com o token do usuário logado
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // 2. Verificar quem é o usuário
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) throw new Error('Usuário não autorizado.')

    // 3. Checar a compra no Banco de Dados (Anti-Fraude)
    const { data: purchase, error: purchaseError } = await supabase
      .from('digital_purchases')
      .select('status, file_url, client_email')
      .eq('id', purchase_id)
      .single()

    if (purchaseError || !purchase) throw new Error('Compra não encontrada no sistema.')
    if (purchase.status !== 'paid') throw new Error('O pagamento desta estampa ainda consta como pendente.')
    if (purchase.client_email !== user.email) throw new Error('Este arquivo pertence a outra conta.')
    if (!purchase.file_url) throw new Error('O arquivo digital ainda não foi vinculado a esta estampa.')

    // 4. Conectar na Cloudflare R2 usando aws4fetch (Ultra-leve, feita para Edge Functions)
    const aws = new AwsClient({
      accessKeyId: Deno.env.get('R2_ACCESS_KEY_ID')!,
      secretAccessKey: Deno.env.get('R2_SECRET_ACCESS_KEY')!,
      service: 's3',
      region: 'auto',
    })

    // 5. Montar a URL exata do arquivo no Cloudflare
    const r2Endpoint = Deno.env.get('R2_ENDPOINT')!.replace(/\/$/, '')
    const r2Bucket = Deno.env.get('R2_BUCKET_NAME')!

    // Codifica os espaços no nome do arquivo (ex: "10658 corrido.PSD" vira "10658%20corrido.PSD")
    const encodedPath = purchase.file_url.split('/').map(encodeURIComponent).join('/')
    const objectUrl = new URL(`${r2Endpoint}/${r2Bucket}/${encodedPath}`)

    // Define que o link morre em exatos 60 segundos
    objectUrl.searchParams.set('X-Amz-Expires', '60')

    // 6. Gerar a Assinatura e colocar na URL
    const signedRequest = await aws.sign(objectUrl, {
      method: 'GET',
      aws: { signQuery: true }, // Diz pra colocar as chaves direto no link pro navegador conseguir abrir
    })

    // 7. Devolve o link pronto e blindado para o Vue.js
    return new Response(JSON.stringify({ signedUrl: signedRequest.url }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    console.error('Erro de Segurança:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
