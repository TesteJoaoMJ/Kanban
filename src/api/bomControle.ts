import axios from 'axios';

// Configuração da API
const apiBomControle = axios.create({
  baseURL: 'https://bomcontrole-proxy.onrender.com',
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json',
  }
});

// Configuração de Retry Otimizada
const MAX_RETRIES = 4;
const INITIAL_RETRY_DELAY = 2000;

// Função auxiliar para limpar strings de busca
const sanitizeSearchTerm = (term: string) => {
  if (!term) return '';
  // [CORREÇÃO] Removidos os parênteses () da regex para permitir buscas como "Produto (X)"
  return term.replace(/[\[\]{}]/g, '').trim();
};

// --- INTERCEPTORS ---

apiBomControle.interceptors.request.use(request => {
  return request;
});

apiBomControle.interceptors.response.use(
  response => response,
  async (error) => {
    const config = error.config;

    if (!config || config.__retryCount >= MAX_RETRIES) {
      if (error.code === 'ECONNABORTED' && error.message.includes('timeout')) {
        error.message = 'O servidor demorou muito para responder. Tente novamente.';
      }
      return Promise.reject(error);
    }

    config.__retryCount = config.__retryCount || 0;

    const status = error.response?.status;
    const shouldRetry =
      error.code === 'ECONNABORTED' ||
      error.code === 'ERR_NETWORK' ||
      !error.response ||
      (status === 429 || status === 500 || status === 502 || status === 503 || status === 504);

    if (shouldRetry) {
      config.__retryCount += 1;
      let backoff = INITIAL_RETRY_DELAY * Math.pow(2, config.__retryCount - 1);

      if (status === 429) {
          console.warn(`🛑 [BC API] Rate Limit (429). Esfriando por ${backoff + 2000}ms...`);
          backoff += 2000;
      } else {
          console.warn(`⚠️ [BC API] Instabilidade (${status || error.code}). Tentativa ${config.__retryCount}/${MAX_RETRIES}...`);
      }

      await new Promise(resolve => setTimeout(resolve, backoff));
      return apiBomControle(config);
    }

    return Promise.reject(error);
  }
);

// --- Definição de Tipos ---

export interface BomControleSaleItem {
  IdProduto: number;
  IdServico?: number;
  Quantidade: number;
  ValorUnitario: number;
  ValorDesconto?: number;
}

export interface BomControleDesconto {
  Percentual: number;
  DataFim: string;
}

export interface BomControleFormaPagamento {
  Boleto?: { Observacao?: string };
  DepositoConta?: { NumeroBanco: string; NumeroAgencia: string; NumeroConta: string; };
  Pix?: { EmiteQrCodePix: boolean };
  Outros?: { Nome: 'Dinheiro' | 'Deposito' | 'Cheque' | 'TransferenciaBancaria' | 'CartaoCredito' | 'CartaoDebito' | 'BoletoBancario' | 'DescontoEmFolha' | 'Outros' | 'DebitoConta'; };
}

export interface BomControleSalePayload {
  IdEmpresa: number;
  IdCliente: number;
  IdConta?: number;
  Itens: BomControleSaleItem[];
  Observacao?: string;
  Observacoes?: string;
  Data: string;
  PrimeiroVencimento: string;
  QuatidadeParcelas?: number;
  QuantidadeParcelas?: number;
  Desconto?: BomControleDesconto;
  FormaPagamento?: BomControleFormaPagamento;
  MovimentarEstoque?: boolean;
}

export interface BomControleAddress {
  TipoLogradouro: string; Logradouro: string; Numero: string; Complemento?: string;
  Bairro: string; Cidade: string; Uf: string; Cep: string;
}

export interface BomControleContact {
  Id?: number; Nome: string; Email: string; Telefone: string; Padrao: boolean; Cobranca: boolean;
}

export interface BomControleClientDetail {
  Id: number; TipoPessoa: string; PaisOrigem?: string; Bloqueado: boolean; DataCriacao?: string;
  PessoaFisica?: { Nome: string; Documento: string; Sexo?: string; DataNascimento?: string; } | null;
  PessoaJuridica?: { RazaoSocial: string; NomeFantasia: string; Documento: string; InscricaoEstadual?: string; } | null;
  Endereco?: BomControleAddress; Contatos?: BomControleContact[]; Nome?: string;
}

export interface BomControleCustomerPayload {
  IdEmpresa: number; IdVendedor: number; IdOrigem: number; Nome: string; TipoPessoa: 'Fisica' | 'Juridica';
  CpfCnpj: string; Email: string; Telefone: string; Enderecos: BomControleAddress[];
  Contatos: BomControleContact[]; PessoaFisica?: any; PessoaJuridica?: any;
}

interface CnpjDetails {
  razao_social: string; email: string | null; telefone: string | null; celular: string | null;
  cep: string | null; logradouro: string | null; numero: string | null; complemento: string | null;
  bairro: string | null; cidade: string | null; uf: string | null;
}

// --- Funções da API ---

export const fetchProductsBC = async (query: string, idEmpresa = 2) => {
  const cleanQuery = sanitizeSearchTerm(query);
  try {
    const response = await apiBomControle.get('/ProdutoServico/Pesquisar', {
      params: {
        'request.idEmpresa': idEmpresa,
        'request.produto': true,
        'request.servico': false,
        'request.venda': true,
        'request.textoPesquisa': cleanQuery,
        'request.paginacao.itensPorPagina': 50,
        'request.paginacao.numeroDaPagina': 1,
        '_t': Date.now()
      },
    });
    return response.data?.Itens || [];
  } catch (error) {
    console.error('Erro ao buscar produtos:', error);
    return [];
  }
};

export const fetchCustomersBC = async (query: string, page = 1, pageSize = 50, idEmpresa = 2) => {
  const cleanQuery = sanitizeSearchTerm(query);
  try {
    const response = await apiBomControle.get('/Cliente/Pesquisar', {
      params: {
        'request.idEmpresa': idEmpresa,
        'request.textoPesquisa': cleanQuery,
        'request.paginacao.itensPorPagina': pageSize,
        'request.paginacao.numeroDaPagina': page,
        '_t': Date.now()
      },
    });
    if (Array.isArray(response.data)) return response.data;
    if (response.data?.Itens) return response.data.Itens;
    return [];
  } catch (error) {
    console.error('Erro ao buscar clientes (BC):', error);
    throw error;
  }
};

export const getCustomerBC = async (id: number): Promise<BomControleClientDetail> => {
  try {
    const response = await apiBomControle.get(`/Cliente/Obter/${id}`);
    return response.data;
  } catch (error) {
    console.error(`Erro ao obter cliente ${id}:`, error);
    throw error;
  }
};

export const fetchSalesBC = async () => {
  try {
    const response = await apiBomControle.get('/Venda/Pesquisar', {
      params: {
        'request.idEmpresa': 2,
        'request.paginacao.itensPorPagina': 100,
        'request.paginacao.numeroDaPagina': 1
      },
    });
    if (Array.isArray(response.data)) return response.data;
    if (response.data?.Itens) return response.data.Itens;
    return [];
  } catch (error) { return []; }
};

export const createSaleBC = async (payload: BomControleSalePayload) => {
  try {
    const safePayload = {
        ...payload,
        Observacao: payload.Observacoes || payload.Observacao
    };
    const response = await apiBomControle.post('/Venda/CriarVendaProdutoServico', safePayload);
    return response.data;
  } catch (error: any) { throw error; }
};

export const getSaleStatusBC = async (saleId: number) => {
  try {
    const response = await apiBomControle.get(`/Venda/Obter/${saleId}`);
    return response.data;
  } catch (error) { return null; }
};

export const createCustomerBC = async (payload: BomControleCustomerPayload) => {
  try {
    const response = await apiBomControle.post('/Cliente/Criar', payload);
    return response.data;
  } catch (error) {
    console.error('Erro ao criar cliente:', error);
    throw error;
  }
};

export const updateAddressBC = async (id: number, address: BomControleAddress) => {
  try {
    const response = await apiBomControle.put(`/Cliente/AlterarEndereco/${id}`, address);
    return response.data;
  } catch (error) {
    console.error(`Erro ao atualizar endereço ${id}:`, error);
    throw error;
  }
};

export const updateContactsBC = async (id: number, contacts: BomControleContact[]) => {
  try {
    const response = await apiBomControle.put(`/Cliente/AlterarContatos/${id}`, { Contatos: contacts });
    return response.data;
  } catch (error) {
    console.error(`Erro ao atualizar contatos ${id}:`, error);
    throw error;
  }
};

export const blockCustomerBC = async (id: number, bloquear: boolean) => {
  try {
    const response = await apiBomControle.put(`/Cliente/AlterarBloqueio/${id}`, { Bloquear: bloquear });
    return response.data;
  } catch (error) {
    console.error('Erro ao bloquear cliente:', error);
    throw error;
  }
};

export const fetchCnpjDetailsBC = async (cnpj: string): Promise<CnpjDetails> => {
  try {
    const cleanedCnpj = cnpj.replace(/[^0-9]/g, '');
    if (cleanedCnpj.length !== 14) throw new Error('CNPJ inválido.');
    const response = await apiBomControle.get('/Cnpj/Consultar', { params: { cnpj: cleanedCnpj } });
    if (response.data?.status === 'error' || !response.data) throw new Error('Consulta de CNPJ falhou.');
    return response.data;
  } catch (error) {
    console.error('Erro ao consultar CNPJ:', error);
    const msg = axios.isAxiosError(error) ? error.message : (error as Error).message;
    throw new Error(msg);
  }
};
