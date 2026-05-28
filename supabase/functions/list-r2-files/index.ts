import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { AwsClient } from "https://esm.sh/aws4fetch@1.0.17"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Não autorizado')

    // Checagem de segurança (Garante que só alguém logado no seu sistema pode listar)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) throw new Error('Acesso Negado.')

    // Conecta no Cloudflare R2
    const aws = new AwsClient({
      accessKeyId: Deno.env.get('R2_ACCESS_KEY_ID')!,
      secretAccessKey: Deno.env.get('R2_SECRET_ACCESS_KEY')!,
      service: 's3',
      region: 'auto',
    })

    const r2Endpoint = Deno.env.get('R2_ENDPOINT')!.replace(/\/$/, '')
    const r2Bucket = Deno.env.get('R2_BUCKET_NAME')!

    // Pede a lista de arquivos para a Cloudflare
    const listUrl = `${r2Endpoint}/${r2Bucket}?list-type=2`
    const res = await aws.fetch(listUrl, { method: 'GET' })
    const xmlText = await res.text()

    // Extrai o nome dos arquivos (Keys)
    const files: string[] = []
    const regex = /<Key>(.*?)<\/Key>/g
    let match;
    while ((match = regex.exec(xmlText)) !== null) {
      // Ignora pastas vazias e limpa o texto
      const fileName = match[1].replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
      if (!fileName.endsWith('/')) {
        files.push(fileName)
      }
    }

    // Ordena do mais recente (alfabeticamente reverso ou como preferir)
    files.sort((a, b) => b.localeCompare(a))

    return new Response(JSON.stringify({ files }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    console.error('Erro ao listar arquivos:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
