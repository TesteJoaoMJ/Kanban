import axios from 'axios';

// URL do seu Proxy no Render
const PROXY_BASE_URL = 'https://cora-proxy-n2fp.onrender.com/api/cora';

// --- Interfaces Completas conforme Documentação Cora ---

export interface CoraCustomer {
    name: string;
    email?: string;
    document: {
        identity: string;
        type: 'CPF' | 'CNPJ';
    };
    address?: {
        street: string;
        number: string;
        district: string;
        city: string;
        state: string;
        zip_code: string;
        complement?: string;
    };
}

export interface CoraServiceItem {
    name: string;
    description?: string;
    amount: number; // Em centavos
}

export interface CoraPaymentTerms {
    due_date: string; // YYYY-MM-DD
    fine?: {
        amount?: number; // Centavos (prioritário)
        rate?: number;   // Percentual (0-100)
        date?: string;   // Data início multa
    };
    interest?: {
        rate: number;    // Percentual (0-100)
    };
    discount?: {
        type: 'FIXED' | 'PERCENT';
        value: number;
    };
}

export interface CoraBoletoPayload {
    code: string;
    customer: CoraCustomer;
    services: CoraServiceItem[];
    payment_terms: CoraPaymentTerms;
    payment_forms: string[]; // ['BANK_SLIP', 'PIX']
    notification?: {
        name: string;
        channels: Array<{
            channel: 'EMAIL' | 'SMS';
            contact: string;
            rules: string[]; // ex: ['NOTIFY_ON_DUE_DATE']
        }>;
    };
}

// Interfaces para Extrato
export interface CoraStatementParams {
  start: string;
  end: string;
  page?: number;
  perPage?: number;
  type?: 'CREDIT' | 'DEBIT';
  transaction_type?: 'TRANSFER' | 'PAYMENT' | 'PIX' | 'FEE';
  aggr?: boolean;
}

export interface CoraTransaction {
  id: string;
  type: 'CREDIT' | 'DEBIT';
  description: string;
  counterParty: {
    name: string;
    identity: string;
  };
}

export interface CoraEntry {
  id: string;
  type: 'CREDIT' | 'DEBIT';
  amount: number;
  createdAt: string;
  transaction: CoraTransaction;
}

export interface CoraHeader {
  businessName: string;
  businessDocument: string;
}

export interface CoraAggregations {
  creditTotal: number;
  debitTotal: number;
}

export interface CoraStatementResponse {
  start: { date: string; balance: number };
  end: { date: string; balance: number };
  header: CoraHeader;
  aggregations?: CoraAggregations;
  entries: CoraEntry[];
}

// --- API Service Completo ---

export const coraApi = {
  // Helper para montar headers com logs para debug
  _getHeaders(clientId?: string) {
      const headers: Record<string, string> = {};

      console.log(`[CoraProxy::_getHeaders] Preparando headers...`);

      if (clientId) {
          headers['x-cora-client-id'] = clientId;
          console.log(`[CoraProxy::_getHeaders] ✅ Header 'x-cora-client-id' definido: ${clientId}`);
      } else {
          console.warn(`[CoraProxy::_getHeaders] ⚠️ NENHUM 'clientId' recebido. Usará o padrão do backend.`);
      }

      return headers;
  },

  // 1. Gerar Pix (Rota Simplificada /pix)
  async generatePix(data: any, clientId?: string) {
    try {
      console.log(`[CoraProxy::generatePix] Iniciando request...`);
      const headers = this._getHeaders(clientId);

      const response = await axios.post(`${PROXY_BASE_URL}/pix`, data, { headers });

      console.log(`[CoraProxy::generatePix] Sucesso. Status: ${response.status}`);
      return response.data;
    } catch (error: any) {
      console.error('[CoraProxy::generatePix] Erro:', error);
      const msg = error.response?.data?.error || error.message || 'Erro ao gerar Pix.';
      throw new Error(msg);
    }
  },

  // 2. Gerar Boleto (Rota Completa /invoices)
  async generateBoleto(data: CoraBoletoPayload, clientId?: string) {
    try {
      console.log(`[CoraProxy::generateBoleto] Iniciando request para /invoices...`);
      const headers = this._getHeaders(clientId);

      // ATENÇÃO: A rota aqui DEVE ser /invoices para bater com o backend
      const response = await axios.post(`${PROXY_BASE_URL}/invoices`, data, { headers });

      console.log(`[CoraProxy::generateBoleto] Sucesso. Status: ${response.status}`);
      return response.data;
    } catch (error: any) {
      console.error('[CoraProxy::generateBoleto] Erro na requisição:', error);

      // Tratamento detalhado de erros da Cora
      let errorMsg = 'Erro ao emitir boleto.';

      if (error.response) {
          // Erro vindo do backend/Cora
          const status = error.response.status;
          const data = error.response.data;

          console.error('[CoraProxy::generateBoleto] Detalhes do erro:', JSON.stringify(data, null, 2));

          if (status === 404) {
              errorMsg = 'Rota /invoices não encontrada no Proxy Backend. Verifique o deploy.';
          } else if (data.details && Array.isArray(data.details)) {
              // Formata erros de validação da Cora
              errorMsg = data.details.map((d: any) => `${d.message}`).join(' | ');
          } else if (data.message) {
              errorMsg = data.message;
          } else if (data.error) {
              errorMsg = data.error;
          }
      } else {
          // Erro de rede ou configuração
          errorMsg = error.message;
      }

      throw new Error(errorMsg);
    }
  },

  // 3. Checar Status (Rota /invoices/:id)
  async checkStatus(id: string, clientId?: string) {
    try {
      console.log(`[CoraProxy::checkStatus] Verificando ID: ${id}`);
      const headers = this._getHeaders(clientId);

      const response = await axios.get(`${PROXY_BASE_URL}/invoices/${id}`, { headers });

      return response.data;
    } catch (error: any) {
      console.warn('[CoraProxy::checkStatus] Falha silenciosa:', error.message);
      return null;
    }
  },

  // 4. Consulta de Extrato Bancário
  async getBankStatement(params: CoraStatementParams, clientId?: string): Promise<CoraStatementResponse> {
    try {
      console.group('🚀 [CoraProxy::getBankStatement] Requisição');

      const queryParams = {
        aggr: true,
        ...params
      };

      const headers = this._getHeaders(clientId);
      const url = `${PROXY_BASE_URL}/bank-statement/statement`;

      console.log('Config:', { url, headers, queryParams });

      const response = await axios.get<CoraStatementResponse>(url, {
        params: queryParams,
        headers: headers
      });

      console.log('Resposta Header:', response.data?.header);
      console.groupEnd();
      return response.data;

    } catch (error: any) {
      console.error('❌ [CoraProxy::getBankStatement] Erro:', error.message);
      if (error.response) {
          console.error('Dados Erro:', error.response.data);
      }
      const msg = error.response?.data?.message || error.message || 'Erro ao buscar extrato.';
      throw new Error(msg);
    }
  }
};
