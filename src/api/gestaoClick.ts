// src/api/gestaoClick.ts

const API_BASE_URL = 'https://mjprocess-proxy.onrender.com/api';

const getAuthHeaders = () => ({
  'Content-Type': 'application/json',
});

// Tipagens
type Endereco = { cep?: string; logradouro?: string; numero?: string; complemento?: string; bairro?: string; cidade_id?: string; nome_cidade?: string; estado?: string; }
type ClientPayload = { nome: string; tipo_pessoa: 'PF' | 'PJ' | 'ES'; cpf_cnpj?: string; email?: string; telefone?: string; celular?: string; enderecos?: { endereco: Endereco }[]; cpf?: string; cnpj?: string; vendedor_id?: number; };
type ClientResponse = { id: number; nome: string; [key: string]: any; }
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

// Tipagem para Financeiro (Pagamentos/Recebimentos)
export type FinancialPayload = {
  descricao: string;
  data_vencimento: string;
  valor: string;
  valor_total?: string;
  juros?: string;
  desconto?: string;
  centro_custo_id?: string;
  nome_centro_custo?: string;
  conta_bancaria_id?: string;
  nome_conta_bancaria?: string;
  forma_pagamento_id?: string;
  nome_forma_pagamento?: string;
  plano_contas_id?: string;
  nome_plano_conta?: string;
  entidade?: 'C' | 'F' | string; // C=Cliente, F=Fornecedor
  cliente_id?: string;
  nome_cliente?: string;
  fornecedor_id?: string;
  nome_fornecedor?: string;
  liquidado?: '0' | '1';
  data_liquidacao?: string;
  data_competencia?: string;
  loja_id?: number | string;
  observacoes?: string;
  [key: string]: any;
};

const gestaoApi = {

  async get(endpoint: string, params: Record<string, any> = {}): Promise<any> {
    const allData: any[] = [];
    let currentPage = 1;

    // Endpoints que exigem paginação exaustiva
    const isPaginatedInternalEndpoint = ['recebimentos', 'pagamentos', 'vendas', 'clientes', 'fornecedores', 'funcionarios'].includes(endpoint);

    // Se NÃO for endpoint de listagem longa, faz requisição simples
    if (!isPaginatedInternalEndpoint) {
        const url = new URL(`${API_BASE_URL}/${endpoint}`);
        Object.keys(params).forEach(key => url.searchParams.append(key, String(params[key])));
        try {
            const response = await fetch(url.toString(), { method: 'GET', headers: getAuthHeaders() });
            if (!response.ok) throw new Error(`Erro GET ${endpoint}: ${response.statusText}`);
            return await response.json();
        } catch (error) {
            console.error(`Falha API GestãoClick (${endpoint}):`, error);
            throw error;
        }
    }

    // --- LÓGICA DE PAGINAÇÃO CORRIGIDA ---
    const MAX_RETRIES = 3;

    while (true) {
        // Tenta pedir 100 itens por página
        const pageParams = { ...params, pagina: currentPage, itens_por_pagina: 100 };

        const url = new URL(`${API_BASE_URL}/${endpoint}`);
        Object.keys(pageParams).forEach(key => url.searchParams.append(key, String(pageParams[key])));

        let attempt = 0;
        let success = false;
        let responseData = null;

        while(attempt < MAX_RETRIES && !success) {
            try {
                const response = await fetch(url.toString(), { method: 'GET', headers: getAuthHeaders() });
                if (response.ok) {
                    responseData = await response.json();
                    success = true;
                } else {
                    throw new Error(`Status ${response.status}`);
                }
            } catch (e) {
                attempt++;
                console.warn(`[API] Erro pág ${currentPage} (Tentativa ${attempt}/${MAX_RETRIES}):`, e);
                await new Promise(r => setTimeout(r, 1000 * attempt));
            }
        }

        if (!success) {
            console.error(`[API] Falha crítica na página ${currentPage}. Retornando dados parciais.`);
            return { code: 206, status: 'partial_content', data: allData, message: 'Importação incompleta.' };
        }

        // Processa dados da página
        if (responseData && (responseData.status === 'success' || Array.isArray(responseData.data))) {
            const items = responseData.data || [];
            if (items.length > 0) {
                allData.push(...items);
                currentPage++;

                // CORREÇÃO: Verifica metadata para saber se há próxima página
                if (responseData.meta) {
                    if (!responseData.meta.proxima_pagina) break;
                } else {
                    // Fallback se não houver meta
                    if (items.length === 0) break;
                }
            } else {
                break; // Array vazio, acabou
            }
        } else {
            break; // Resposta inválida, para
        }

        // Pausa suave para não sobrecarregar
        await new Promise(r => setTimeout(r, 50));
    }

    return { code: 200, status: 'success', data: allData };
  },

  async post(endpoint: string, data: any): Promise<any> {
    const url = `${API_BASE_URL}/${endpoint}`;
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(data),
      });
      const responseData = await response.json();
       if (!response.ok || responseData.status !== 'success') {
         throw new Error(responseData?.msg || responseData?.erros?.[0] || `Erro ${response.status}`);
       }
      return responseData;
    } catch (error) {
      console.error(`Falha na API GestãoClick (POST ${endpoint}):`, error);
      throw error;
    }
  },

  async put(endpoint: string, data: any): Promise<any> {
    const url = `${API_BASE_URL}/${endpoint}`;
    try {
      const response = await fetch(url, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(data),
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

  async delete(endpoint: string): Promise<any> {
    const url = `${API_BASE_URL}/${endpoint}`;
    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: getAuthHeaders(),
      });
      const responseData = await response.json();
       if (!response.ok || responseData.status !== 'success') {
         throw new Error(responseData?.msg || responseData?.erros?.[0] || `Erro ${response.status}`);
       }
      return responseData;
    } catch (error) {
      console.error(`Falha na API GestãoClick (DELETE ${endpoint}):`, error);
      throw error;
    }
  },

  // --- CLIENTES & ENTIDADES ---

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
    return this.post('clientes', payload).then(res => res.data);
  },

  async buscarClientes(termo: string = '', pagina: number = 1): Promise<ClientResponse[]> {
    try {
      const params: any = { pagina: pagina };
      if (termo) params.nome = encodeURIComponent(termo);
      const response = await this.get('clientes', params);
      return response.data || [];
    } catch (error) { console.error('Erro em buscarClientes:', error); return []; }
  },

  async buscarFornecedores(termo: string = '', pagina: number = 1): Promise<any[]> {
    try {
      const params: any = { pagina: pagina };
      if (termo) params.nome = encodeURIComponent(termo);
      const response = await this.get('fornecedores', params);
      return response.data || [];
    } catch (error) { console.error('Erro em buscarFornecedores:', error); return []; }
  },

  async buscarFuncionarios(termo: string = '', pagina: number = 1): Promise<any[]> {
    try {
      const params: any = { pagina: pagina };
      if (termo) params.nome = encodeURIComponent(termo);
      const response = await this.get('funcionarios', params);
      return response.data || [];
    } catch (error) { console.error('Erro em buscarFuncionarios:', error); return []; }
  },

  // --- PRODUTOS & SERVIÇOS ---

  async buscarProdutos(): Promise<Product[]> {
    try {
      const responseData = await this.get('produtos');
      if (responseData.status !== 'success') { throw new Error(responseData?.msg || 'Erro ao buscar produtos da API externa.'); }
      return (responseData.data || []).filter((p: Product) => p.movimenta_estoque === '1');
    } catch (error) { console.error('Erro em buscarProdutos:', error); throw error; }
  },

  async buscarServicos(termo: string): Promise<Service[]> {
    if (!termo || termo.length < 2) return [];
    try {
      const responseData = await this.get('servicos', { nome: encodeURIComponent(termo) });
      if (responseData.status !== 'success') { throw new Error(responseData?.msg || 'Erro ao buscar serviços.'); }
      return responseData.data || [];
    } catch (error) { console.error('Erro em buscarServicos:', error); return []; }
  },

  async buscarFormasDePagamento(): Promise<PaymentMethod[]> {
    try {
      const responseData = await this.get('formas_pagamentos');
      if (responseData.status !== 'success') { throw new Error(responseData?.msg || 'Erro ao buscar formas.'); }
      return (responseData.data || []).map((item: any) => item.FormasPagamento);
    } catch (error) { console.error('Erro em buscarFormasDePagamento:', error); throw error; }
  },

  // --- VENDAS ---

  async buscarVendas(params: { data_inicio?: string; data_fim?: string; loja_id?: number } = {}): Promise<any[]> {
    try {
      // Força o ID da loja que você especificou, mas permite sobrescrever se necessário
      const queryParams = { loja_id: 523283, ...params };
      const response = await this.get('vendas', queryParams);
      return response.data || [];
    } catch (error) {
      console.error('Erro ao buscar vendas do GestãoClick:', error);
      return [];
    }
  },

  async cadastrarVenda(vendaData: SalePayload): Promise<any> {
    return this.post('vendas', vendaData).then(res => res.data);
  },

  async getVendaByCodigo(codigo: number): Promise<any> {
    const response = await this.get('vendas', { codigo: codigo });
    if (response && response.data && response.data.length > 0) return response.data[0];
    return null;
  },

  async verificarVendaPorCodigo(codigo: number): Promise<boolean> {
    try { const responseData = await this.get('vendas', { codigo }); return responseData.status === 'success' && Array.isArray(responseData.data) && responseData.data.length > 0; } catch (error) { return false; }
  },

  // --- FINANCEIRO: RECEBIMENTOS ---

  async buscarRecebimentos(params: { data_inicio?: string; data_fim?: string; loja_id?: number } = {}): Promise<any[]> {
    try {
      const response = await this.get('recebimentos', params);
      return (response.data || []);
    } catch (error) { console.error('Erro ao buscar recebimentos:', error); return []; }
  },

  async cadastrarRecebimento(data: FinancialPayload): Promise<any> {
    return this.post('recebimentos', data);
  },

  async updateRecebimento(id: string, data: FinancialPayload): Promise<any> {
    return this.put(`recebimentos/${id}`, data);
  },

  async deletarRecebimento(id: string): Promise<any> {
    return this.delete(`recebimentos/${id}`);
  },

  // --- FINANCEIRO: PAGAMENTOS ---

  async buscarPagamentos(params: { data_inicio?: string; data_fim?: string; loja_id?: number } = {}): Promise<any[]> {
    try {
      const response = await this.get('pagamentos', params);
      return (response.data || []);
    } catch (error) { console.error('Erro ao buscar pagamentos:', error); return []; }
  },

  async cadastrarPagamento(data: FinancialPayload): Promise<any> {
    return this.post('pagamentos', data);
  },

  async updatePagamento(id: string, data: FinancialPayload): Promise<any> {
    return this.put(`pagamentos/${id}`, data);
  },

  async deletarPagamento(id: string): Promise<any> {
    return this.delete(`pagamentos/${id}`);
  },

  // --- AUXILIARES ---

  async buscarCidades(estadoId: number): Promise<{id: string, nome: string}[]> {
    try { const responseData = await this.get('cidades', { estado_id: estadoId }); return responseData.data || []; } catch (error) { return []; }
  },

  async buscarEstados(): Promise<{id: string, sigla: string}[]> {
    try { const responseData = await this.get('estados'); return responseData.data || []; } catch (error) { return []; }
  },

  async getSituacoesVenda(): Promise<SaleStatus[]> {
    try { const data = await this.get('situacoes_vendas'); return data.data || []; } catch (error) { throw error; }
  },

  async buscarProdutoPorId(id: string): Promise<any> {
    try { const responseData = await this.get(`produtos/${id}`); if (responseData.status !== 'success') throw new Error(responseData?.msg); return responseData.data; } catch (error) { throw error; }
  },

  async atualizarEstoqueProduto(produtoId: string, novoEstoque: number): Promise<any> {
    try { const produto = await this.buscarProdutoPorId(produtoId); const payload = { ...produto, estoque: novoEstoque.toString() }; return await this.put(`produtos/${produtoId}`, payload); } catch (error) { throw error; }
  },

  async cadastrarServico(nomeServico: string): Promise<{ id: string; nome: string }> {
    try {
      const payload = { nome: nomeServico, valor_venda: "0.00" };
      return this.post('servicos', payload).then(res => res.data);
    } catch (error) { throw error; }
  },

  async buscarServicoPorId(id: string): Promise<any> {
    try { const responseData = await this.get(`servicos/${id}`); if (responseData.status !== 'success') throw new Error('Erro buscar serviço'); return responseData.data; } catch (error) { throw error; }
  },

  async atualizarServico(servicoId: string, novoNome: string): Promise<any> {
    try { const servicoAtual = await this.buscarServicoPorId(servicoId); const payload = { ...servicoAtual, nome: novoNome }; return this.put(`servicos/${servicoId}`, payload); } catch (error) { throw error; }
  },
};

export { gestaoApi };
