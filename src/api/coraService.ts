import axios from 'axios';

// URL do seu NOVO Proxy no Render (Substitua pela URL gerada no Passo 1)
const PROXY_BASE_URL = 'https://cora-mj.onrender.com/api/cora';

export interface CoraConfig {
    clientId: string;
    cert: string; // Conteúdo do arquivo .pem
    key: string;  // Conteúdo do arquivo .key
}

export const coraService = {
  // Gera o Pix passando as credenciais no corpo da requisição
  async generatePix(data: {
    amount: number; // Centavos
    code: string;
    customer: { name: string; identity: string };
    config?: CoraConfig; // Credenciais do cliente (Opcional, se null usa as do Render)
  }) {
    try {
      const response = await axios.post(`${PROXY_BASE_URL}/pix`, data);
      return response.data;
    } catch (error: any) {
      console.error('Erro Service Cora:', error);
      const msg = error.response?.data?.error || error.message || 'Erro ao gerar Pix.';
      throw new Error(msg);
    }
  },

  // Consulta Status (Agora via POST para passar config segura)
  async checkStatus(id: string, config?: CoraConfig) {
    try {
      const response = await axios.post(`${PROXY_BASE_URL}/consult-invoice`, {
        id,
        config
      });
      return response.data; // { status: 'PAID', total_paid: ... }
    } catch (error: any) {
      // Falha silenciosa para não travar polling
      return null;
    }
  }
};
