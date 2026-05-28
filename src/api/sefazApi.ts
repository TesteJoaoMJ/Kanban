// src/api/sefazApi.ts
import axios from 'axios';

// Garante que usa a URL configurada ou localhost em desenvolvimento
const SEFAZ_PROXY_URL = import.meta.env.VITE_SEFAZ_PROXY_URL || 'https://sefaz-proxy-dujl.onrender.com';

const api = axios.create({
  baseURL: SEFAZ_PROXY_URL,
  timeout: 120000, // Timeout maior para emissão fiscal
  headers: { 'Content-Type': 'application/json' }
});

export const sefazService = {
  // =========================================================================
  // GESTÃO DE EMPRESAS & CERTIFICADOS
  // =========================================================================
  async listarEmpresas() {
    try {
      const response = await api.get('/api/empresas');
      return response.data.data || [];
    } catch (error) {
      console.error('Erro ao listar empresas:', error);
      return [];
    }
  },

  async buscarNotaPorChave(chave: string, cnpj: string) {
    try {
      const response = await api.get(`/api/consultar-nota-chave/${chave}`, {
          params: { cnpj: cnpj.replace(/\D/g, '') }
      });
      return response.data;
    } catch (error: any) {
        throw new Error(error.response?.data?.message || 'Erro ao buscar a nota pela chave.');
    }
  },

  async uploadCertificado(cnpj: string, file: File, password: string) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = async () => {
        try {
          const base64Content = (reader.result as string).split(',')[1];
          // Remove pontuação do CNPJ para a URL
          const response = await api.put(`/api/empresas/${cnpj.replace(/\D/g, '')}/certificado`, {
            certificado_base64: base64Content,
            password: password
          });
          resolve(response.data);
        } catch (error: any) {
          reject(error.response?.data?.error || 'Erro no upload');
        }
      };
      reader.onerror = error => reject(error);
    });
  },

  async sincronizarDfe(cnpj: string, lastNsu: number = 0, provider: 'nuvem' | 'sefaz' = 'nuvem') {
    try {
      const url = provider === 'sefaz' ? '/api/sincronizar-sefaz-direto' : '/api/sincronizar-sefaz';
      const response = await api.post(url, { cnpj, last_nsu: lastNsu });
      return response.data;
    } catch (error) {
      console.error(`Erro ao sincronizar NF-e via ${provider}:`, error);
      return { status: 'error' };
    }
  },

  // =========================================================================
  // STATUS E CONSULTAS DIRETAS (NOVAS ROTAS SEFAZ)
  // =========================================================================
  async verificarStatusServico(tipo: 'nfe' | 'nfce' | 'cte', ambiente: string, provider: 'nuvem' | 'sefaz' = 'nuvem') {
      try {
          const url = provider === 'sefaz'
            ? `/api/${tipo}/sefaz/status-direto`
            : `/api/${tipo}/sefaz/status`;

          const response = await api.get(url, { params: { ambiente } });
          return response.data;
      } catch (error: any) {
          throw new Error(error.response?.data?.message || 'Erro ao consultar status do serviço.');
      }
  },

  async consultarNotaDireta(chave: string, tipo: 'nfe' | 'nfce' | 'cte') {
      try {
          const response = await api.get(`/api/${tipo}/sefaz/consultar-direto/${chave}`);
          return response.data;
      } catch (error: any) {
          throw new Error(error.response?.data?.message || 'Erro ao consultar chave diretamente na SEFAZ.');
      }
  },

  // =========================================================================
  // NF-e (MODELO 55 - NOTA GRANDE)
  // =========================================================================
  async consultarNotas(cnpj?: string, deepScan: boolean = false) {
    try {
      const response = await api.get('/api/consultar-notas', {
        params: { cnpj, deep_scan: deepScan }
      });
      return response.data.data || [];
    } catch (error) {
      console.error('Erro na API Sefaz:', error);
      throw error;
    }
  },

  async listarNfesNuvem(cnpj: string, ambiente: string = 'producao', top: number = 50, skip: number = 0) {
      try {
          const response = await api.get('/api/nfe/nuvem-list', {
              params: { cnpj: cnpj.replace(/\D/g, ''), ambiente, top, skip }
          });
          return response.data;
      } catch (error: any) {
          throw new Error(error.response?.data?.message || 'Erro ao listar notas da Nuvem Fiscal.');
      }
  },

  // A MÁGICA DO ROTEAMENTO: SE FOR SEFAZ, VAI PRA ROTA NOVA
  async emitirNFe(fullOrderData: any, cnpjEmitente: string, ieEmitente?: string, provider: 'nuvem' | 'sefaz' = 'nuvem') {
    try {
        const url = provider === 'sefaz' ? '/api/emitir-nfe-sefaz' : '/api/emitir-nfe';
        const response = await api.post(url, {
            order: fullOrderData,
            cnpj_emitente: cnpjEmitente,
            ie_emitente: ieEmitente
        });
        return response.data;
    } catch (error: any) {
        throw error;
    }
  },

  async cancelarNFe(nfeId: string, justificativa: string) {
     try {
         const response = await api.post('/api/nfe/cancelar', { nfe_id: nfeId, justificativa });
         return response.data;
     } catch (error: any) {
         throw new Error(error.response?.data?.message || 'Erro ao cancelar NFe');
     }
  },

  async manifestarNota(chave: string, cnpj: string, tipo: 'ciencia' | 'confirmacao' | 'desconhecimento' | 'nao_realizada') {
      try {
          const response = await api.post('/api/manifestar', {
              chave,
              cnpj: cnpj.replace(/\D/g, ''),
              tipo
          });
          return response.data;
      } catch (error: any) {
          throw new Error(error.response?.data?.message || 'Erro ao comunicar manifestação.');
      }
  },

  // Helper para URL de Download (NFe)
  getProxyDownloadUrl(tipo: 'pdf' | 'xml', idNuvem: string) {
      return `${SEFAZ_PROXY_URL}/api/nfe/download/${tipo}/${idNuvem}`;
  },

  // =========================================================================
  // INUTILIZAÇÃO DE NUMERAÇÃO NF-e
  // =========================================================================
  async inutilizarNFe(payload: {
    ambiente: 'homologacao' | 'producao';
    cnpj: string;
    ano: number;
    serie: number;
    numero_inicial: number;
    numero_final: number;
    justificativa: string;
  }) {
    try {
      const response = await api.post('/api/nfe/inutilizacoes', payload);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Erro ao inutilizar numeração.');
    }
  },

  async consultarInutilizacao(id: string) {
    try {
      const response = await api.get(`/api/nfe/inutilizacoes/${id}`);
      return response.data;
    } catch (error: any) {
      throw new Error(error.response?.data?.message || 'Erro ao consultar inutilização.');
    }
  },

  getInutilizacaoDownloadUrl(tipo: 'pdf' | 'xml', id: string) {
    return `${SEFAZ_PROXY_URL}/api/nfe/inutilizacoes/${id}/${tipo}`;
  },

  // =========================================================================
  // NFC-e (MODELO 65 - CUPOM FISCAL)
  // =========================================================================

  // A MÁGICA DO ROTEAMENTO NFC-E
  async emitirNFCe(saleData: any, cnpjEmitente: string, ieEmitente?: string, provider: 'nuvem' | 'sefaz' = 'nuvem') {
    try {
        const url = provider === 'sefaz' ? '/api/emitir-nfce-sefaz' : '/api/emitir-nfce';
        const response = await api.post(url, {
            order: saleData,
            cnpj_emitente: cnpjEmitente,
            ie_emitente: ieEmitente
        });
        return response.data;
    } catch (error: any) {
        throw error;
    }
  },

  async cancelarNFCe(nfceId: string, justificativa: string) {
    try {
        const response = await api.post('/api/nfce/cancelar', {
            nfce_id: nfceId,
            justificativa
        });
        return response.data;
    } catch (error: any) {
        throw new Error(error.response?.data?.message || 'Erro ao cancelar NFC-e');
    }
  },

  // Helper para URL de Download (NFC-e)
  getProxyNfceDownloadUrl(tipo: 'pdf' | 'xml', idNuvem: string) {
      return `${SEFAZ_PROXY_URL}/api/nfce/download/${tipo}/${idNuvem}`;
  },

  // =========================================================================
  // CT-e (MODELO 57 - FRETES CONTRA O CNPJ E EMISSÃO) [NOVO]
  // =========================================================================

  // 1. Sincroniza a Sefaz buscando fretes emitidos contra o seu CNPJ
  async sincronizarCTes(cnpj: string, lastNsu: number = 0) {
    try {
      const response = await api.post('/api/sincronizar-sefaz-cte', { cnpj, last_nsu: lastNsu });
      return response.data;
    } catch (error) {
      console.error('Erro ao sincronizar CT-e:', error);
      return { status: 'error' };
    }
  },

  // 2. Busca no banco de dados os CT-es já sincronizados
  async consultarCTes(cnpj?: string, deepScan: boolean = false) {
    try {
      const response = await api.get('/api/consultar-ctes', {
        params: { cnpj, deep_scan: deepScan }
      });
      return response.data.data || [];
    } catch (error) {
      console.error('Erro ao consultar CT-es no banco:', error);
      throw error;
    }
  },

  // Helper para baixar XML ou DACTE do CT-e
  getProxyCteDownloadUrl(tipo: 'pdf' | 'xml', idNuvem: string) {
      return `${SEFAZ_PROXY_URL}/api/cte/download/${tipo}/${idNuvem}`;
  }
};
