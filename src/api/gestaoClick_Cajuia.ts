// src/api/gestaoClick_Cajuia.ts
// Este arquivo é uma CÓPIA do gestaoClick.ts, mas aponta para a LOJA "524728"

// O proxy é o MESMO do MJProcess
const API_BASE_URL = 'https://mjprocess-proxy.onrender.com/api';

const getAuthHeaders = () => ({
  'Content-Type': 'application/json',
});

// ID da Loja Cajuia
const CAJUIA_LOJA_ID = "524728";

// Tipagens (mantidas como no seu arquivo)
type Endereco = { cep?: string; logradouro?: string; numero?: string; complemento?: string; bairro?: string; cidade_id?: string; nome_cidade?: string; estado?: string; }
type ClientPayload = { nome: string; tipo_pessoa: 'PF' | 'PJ' | 'ES'; cpf_cnpj?: string; email?: string; telefone?: string; celular?: string; enderecos?: { endereco: Endereco }[]; cpf?: string; cnpj?: string; vendedor_id?: number; };
type ClientResponse = { id: number; nome: string; }
type Product = { id: string; nome: string; estoque: number | string; unidade: 'M' | 'KG' | string; movimenta_estoque: '0' | '1'; [key: string]: any; };
type Service = { id: string; nome: string; imagem_url?: string; [key: string]: any; };
type SaleStatus = { id: number; nome: string; };
type PaymentMethod = { id: string; nome: string; };
type SalePayload = {
  cliente_id: number;
  situacao_id: number;
  produtos: { produto: { produto_id: string; quantidade: number; valor_venda: string; } }[];
  servicos: { servico: { servico_id: string; quantidade: number; valor_venda: string; } }[];
  pagamentos?: { pagamento: { data_vencimento: string; valor: string; forma_pagamento_id: number | null } }[];
  vendedor_id?: number;
};

const gestaoApiCajuia = {

  // GET não precisa de loja_id, pois usa a chave da conta
  async get(endpoint: string, params: Record<string, any> = {}): Promise<any> {
    const allData: any[] = [];
    let currentPage = 1;
    // Endpoints que sabemos que precisam de paginação para trazer tudo
    const isPaginatedEndpoint = ['recebimentos', 'pagamentos', 'vendas'].includes(endpoint);

    if (!isPaginatedEndpoint) {
        const url = new URL(`${API_BASE_URL}/${endpoint}`);
        Object.keys(params).forEach(key => url.searchParams.append(key, String(params[key])));
        try {
            const response = await fetch(url.toString(), { method: 'GET', headers: getAuthHeaders() });
            if (!response.ok) throw new Error(`Erro na requisição GET para ${endpoint}: ${response.statusText}`);
            return await response.json();
        } catch (error) {
            console.error(`Falha na API GestãoClick (GET ${endpoint}):`, error);
            throw error;
        }
    }

    // Lógica de Paginação (copiada e expandida para vendas)
    while (true) {
        const pageParams = { ...params, pagina: currentPage };
        const url = new URL(`${API_BASE_URL}/${endpoint}`);
        Object.keys(pageParams).forEach(key => url.searchParams.append(key, String(pageParams[key])));

        try {
            const response = await fetch(url.toString(), { method: 'GET', headers: getAuthHeaders() });
            if (!response.ok) throw new Error(`Erro na requisição paginada para ${endpoint}: ${response.statusText}`);

            const responseData = await response.json();

            if (responseData.status === 'success' && responseData.data && responseData.data.length > 0) {
                allData.push(...responseData.data);

                // Verifica se chegou ao fim (total da pagina < limite ou meta info)
                // A API do Gestão geralmente retorna 'meta'
                if (responseData.meta) {
                    if (currentPage >= Math.ceil(responseData.meta.total_registros / responseData.meta.limite_por_pagina)) {
                        break;
                    }
                } else if (responseData.data.length < 10) {
                    // Fallback se não tiver meta: se veio menos itens que o padrão, acabou
                    break;
                }

                currentPage++;
            } else {
                break;
            }
        } catch (error) {
            console.error(`Falha na API GestãoClick (GET Paginado ${endpoint}, página ${currentPage}):`, error);
            // Retorna o que conseguiu até agora em caso de erro parcial
            return { code: 500, status: 'error_partial', data: allData, message: (error as Error).message };
        }
    }

    return { code: 200, status: 'success', data: allData };
  },

  // PUT não parece ser usado no seu fluxo de PDV, mas se for, adicione loja_id
  async put(endpoint: string, data: any): Promise<any> {
    const url = `${API_BASE_URL}/${endpoint}`;

    // Injeta o loja_id no payload
    const payloadWithLoja = { ...data, loja_id: CAJUIA_LOJA_ID };

    try {
      const response = await fetch(url, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(payloadWithLoja),
      });
      const responseData = await response.json();
       if (!response.ok || responseData.status !== 'success') {
         throw new Error(responseData?.msg || responseData?.erros?.[0] || `Erro ${response.status}`);
       }
      return responseData;
    } catch (error) {
      console.error(`Falha na API GestãoClick (PUT ${endpoint}):`, error);
      throw error;
    }
  },

  // ==========================================
  // MÉTODOS ESPECÍFICOS
  // ==========================================

  // ATUALIZADO: Buscar Vendas com suporte a TIPO
  async buscarVendas(params: { data_inicio: string; data_fim: string; loja_id?: string; tipo?: string }): Promise<any[]> {
      try {
          // Força o ID da loja Cajuia se não vier
          const finalParams = { ...params, loja_id: params.loja_id || CAJUIA_LOJA_ID };
          const result = await this.get('vendas', finalParams);
          return result.data || [];
      } catch (error) {
          console.error("Erro ao buscar vendas Cajuia:", error);
          return [];
      }
  },

  async buscarPagamentos(params: any): Promise<any[]> {
      try {
          const result = await this.get('pagamentos', params);
          return result.data || [];
      } catch (error) {
          console.error("Erro pagamentos Cajuia:", error);
          return [];
      }
  },

  async buscarRecebimentos(params: any): Promise<any[]> {
      try {
          const result = await this.get('recebimentos', params);
          return result.data || [];
      } catch (error) {
           console.error("Erro recebimentos Cajuia:", error);
           return [];
      }
  },

  async cadastrarCliente(clienteData: ClientPayload): Promise<ClientResponse> {
    const payload: Partial<ClientPayload> = {};
    for (const key in clienteData) {
      const value = clienteData[key as keyof ClientPayload];
      if (Array.isArray(value) && value.length === 0) continue;
      if (typeof value === 'object' && value !== null && !Array.isArray(value) && Object.keys(value).length === 0) continue;
      if (value !== null && value !== '') { (payload as any)[key] = value; }
    }
    if (payload.cpf_cnpj) {
        if (payload.tipo_pessoa === 'PF') payload.cpf = payload.cpf_cnpj;
        else payload.cnpj = payload.cpf_cnpj;
        delete payload.cpf_cnpj;
    }

    // Injeta o loja_id
    const payloadWithLoja = { ...payload, loja_id: CAJUIA_LOJA_ID };

    try {
      const response = await fetch(`${API_BASE_URL}/clientes`, {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify(payloadWithLoja)
      });
      const responseData = await response.json();
      if (!response.ok || responseData.status !== 'success') { throw new Error(responseData?.msg || responseData?.erros?.[0] || `Erro ${response.status}`); }
      return responseData.data;
    } catch (error) { console.error('Erro em cadastrarCliente (Cajuia):', error); throw error; }
  },

  async cadastrarVenda(vendaData: SalePayload): Promise<any> {
    // Injeta o loja_id
    const payloadWithLoja = { ...vendaData, loja_id: CAJUIA_LOJA_ID };

    try {
      const response = await fetch(`${API_BASE_URL}/vendas`, {
          method: 'POST',
          headers: getAuthHeaders(),
          body: JSON.stringify(payloadWithLoja)
      });
      const responseData = await response.json();
      if (!response.ok || responseData.status !== 'success') {
          const apiMessage = responseData?.message || responseData?.msg || (responseData.erros && responseData.erros.join(', ')) || 'A API não retornou uma mensagem de erro específica.';
          throw new Error(`[ERRO DA API GESTÃO CLICK] ${apiMessage}`);
      }
      return responseData.data;
    } catch (error) {
        console.error('Erro detalhado em cadastrarVenda (Cajuia):', error);
        throw error;
    }
  },

  async buscarClientes(termo: string): Promise<ClientResponse[]> {
    if (!termo || termo.length < 2) return [];
    try {
      // GET não precisa de loja_id, a chave já é da conta
      const response = await this.get('clientes', { nome: encodeURIComponent(termo) });
      return response.data || [];
    } catch (error) { console.error('Erro em buscarClientes (Cajuia):', error); return []; }
  },

  async buscarProdutos(): Promise<Product[]> {
    try {
      const responseData = await this.get('produtos');
      if (responseData.status !== 'success') { throw new Error(responseData?.msg || 'Erro ao buscar produtos da API externa.'); }
      return (responseData.data || []);
    } catch (error) { console.error('Erro em buscarProdutos (Cajuia):', error); throw error; }
  },

  async buscarFormasDePagamento(): Promise<PaymentMethod[]> {
    try {
      const responseData = await this.get('formas_pagamentos');
      if (responseData.status !== 'success') { throw new Error(responseData?.msg || 'Erro ao buscar formas de pagamento.'); }
      return (responseData.data || []).map((item: any) => item.FormasPagamento);
    } catch (error) { console.error('Erro em buscarFormasDePagamento (Cajuia):', error); throw error; }
  },

  async getSituacoesVenda(): Promise<SaleStatus[]> {
    try {
      const data = await this.get('situacoes_vendas');
      return data.data || [];
    } catch (error) { console.error('Erro em getSituacoesVenda (Cajuia):', error); throw error; }
  },

  async listarLojas(): Promise<{id: string, nome: string}[]> {
    try {
      const response = await this.get('lojas');
      return response.data || [];
    } catch (error) { console.error('Erro em listarLojas (Cajuia):', error); return []; }
  },
};

export { gestaoApiCajuia };
