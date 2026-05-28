// backend/src/routes/sefaz.js
const express = require('express');
const router = express.Router();
const axios = require('axios');

// Configurações
const NFE_PROVIDER_URL = process.env.NFE_API_URL || 'https://api.nuvemfiscal.com.br/v2/nfe';
const NFE_API_TOKEN = process.env.NFE_API_TOKEN;

// --- Rota de Sincronização (POST) ---
router.post('/sincronizar-sefaz', async (req, res) => {
  try {
    const { cnpj } = req.body;
    console.log(`[Proxy] Iniciando sincronização para CNPJ: ${cnpj}`);

    const response = await axios.post(`${NFE_PROVIDER_URL}/sincronizar`, {}, {
      headers: { 'Authorization': `Bearer ${NFE_API_TOKEN}` }
    });

    return res.json(response.data);

  } catch (error) {
    // Pega a mensagem de erro da API ou do Axios
    const errorResponse = error.response?.data;
    const errorMsg = typeof errorResponse === 'string' ? errorResponse : (errorResponse?.message || error.message || '');

    console.error('[Proxy Error Sync]', errorMsg);

    // LÓGICA DE BLOQUEIO E TEMPO
    // Detecta se é o erro de "menos de 1 hora" e extrai os minutos
    if (errorMsg.includes('menos de 1 hora') || errorMsg.includes('Validation failed') || error.response?.status === 422 || error.response?.status === 429) {

       // Tenta ler "em X minuto(s)" da mensagem de erro
       let minutosRestantes = 60; // Padrão
       const match = errorMsg.match(/em (\d+) minuto/);
       if (match && match[1]) {
           minutosRestantes = parseInt(match[1]);
       }

       const proximaTentativa = new Date(Date.now() + minutosRestantes * 60000).toISOString();

       // Retorna 200 (OK) com status 'blocked' para o Front não dar erro 500
       return res.json({
         status: 'blocked',
         message: `Sincronização em pausa. ${errorMsg}`,
         next_attempt: proximaTentativa,
         wait_minutes: minutosRestantes
       });
    }

    // Outros erros
    return res.json({
        status: 'error',
        message: 'Erro na comunicação com a SEFAZ.',
        details: errorMsg
    });
  }
});

// --- Rota de Consulta (GET) ---
router.get('/consultar-notas', async (req, res) => {
  try {
    const { cnpj } = req.query;
    console.log(`[Proxy] Consultando notas para CNPJ: ${cnpj}`);

    const response = await axios.get(`${NFE_PROVIDER_URL}/destinadas`, {
      params: {
        'limit': 50, // Pega as últimas 50
        'order': 'desc'
      },
      headers: { 'Authorization': `Bearer ${NFE_API_TOKEN}` }
    });

    const rawData = response.data.data || response.data || [];
    const notas = Array.isArray(rawData) ? rawData : [rawData];

    if (notas.length > 0) {
        console.log('[Proxy DEBUG] Exemplo de Nota Bruta:', JSON.stringify(notas[0]).substring(0, 200) + '...');
    }

    // MAPEAMENTO PROFUNDO (DEEP SEARCH)
    const notasFormatadas = notas.map(n => {

      // 1. Busca o NOME em todos os lugares possíveis
      let nome = 'Emitente Desconhecido';

      // Tenta emitente_nome direto
      if (n.emitente_nome) nome = n.emitente_nome;
      // Tenta objeto emitente
      else if (n.emitente) {
          if (typeof n.emitente === 'string') nome = n.emitente;
          else nome = n.emitente.nome || n.emitente.xNome || n.emitente.razao_social || nome;
      }
      // Tenta campos soltos
      else if (n.nome) nome = n.nome;
      else if (n.xNome) nome = n.xNome;
      else if (n.razao_social) nome = n.razao_social;

      // 2. Busca o VALOR
      let valor = 0;
      if (n.valor_total !== undefined) valor = n.valor_total;
      else if (n.valor !== undefined) valor = n.valor;
      else if (n.vNF !== undefined) valor = n.vNF;
      else if (n.total !== undefined) valor = n.total;

      // 3. Link XML
      const xml = n.xml_url || n.url_xml || n.link_xml || n.xmlLink || null;

      return {
        chave: n.chave_acesso || n.chave || n.chNFe || '',
        emitente: nome,
        cnpj_emitente: n.emitente_cpf_cnpj || n.cnpj_emitente || n.CNPJ || '',
        valor: Number(valor),
        emissao: n.data_emissao || n.dhEmi || new Date().toISOString(),
        situacao_sefaz: n.situacao_sefaz || n.status || 'Processada',
        xml_link: xml,
        pdf_link: `/api/danfe/${n.chave_acesso || n.chave}`
      };
    });

    return res.json(notasFormatadas);

  } catch (error) {
    console.error('[Proxy Error List]', error.message);
    return res.json([]);
  }
});

router.get('/danfe/:chave', async (req, res) => {
  try {
    const { chave } = req.params;
    console.log(`[Proxy] Buscando PDF para chave: ${chave}`);

    // Chamada para a API da NuvemFiscal pedindo o PDF
    // NOTA: Verifique na doc da NuvemFiscal se o endpoint é /nfe/{id}/pdf ou /nfe/danfe
    // O exemplo abaixo assume o padrão comum REST
    const response = await axios.get(`${NFE_PROVIDER_URL}/${chave}/pdf`, {
      headers: { 'Authorization': `Bearer ${NFE_API_TOKEN}` },
      responseType: 'arraybuffer' // IMPORTANTE: Para lidar com binário (PDF)
    });

    // Configura os cabeçalhos para o navegador entender que é um PDF
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="danfe-${chave}.pdf"`);

    // Envia o arquivo binário
    return res.send(response.data);

  } catch (error) {
    console.error('[Proxy Error PDF]', error.message);
    // Se der erro, retorna JSON explicativo em vez de quebrar a página
    res.status(500).json({
        status: 'error',
        message: 'Não foi possível recuperar a DANFE.',
        details: error.response?.data ? error.response.data.toString() : error.message
    });
  }
});

module.exports = router;
