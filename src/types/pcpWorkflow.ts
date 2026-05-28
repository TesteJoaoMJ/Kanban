// src/types/pcpWorkflow.ts

export type StepType = 'status_update' | 'dropdown_select' | 'form_input' | 'quality_check';
export type DataSource = 'clients' | 'suppliers' | 'employees' | 'stock' | 'custom';

export interface PcpStep {
  id: string;
  name: string;
  type: StepType;
  order: number;
  // Se for dropdown, de onde vem os dados?
  dataSource?: DataSource;
  customOptions?: string[]; // Se dataSource for 'custom'
  // Configuração de Rota de Erro (Retrabalho)
  hasErrorRoute?: boolean;
  rejectTargetStageId?: string; // Para qual aba volta se der erro
  requireJustification?: boolean; // Exige texto justificando
  requireAttachment?: boolean; // Exige foto/anexo do erro
}

export interface PcpStage {
  id: string;
  name: string;
  order: number;
  color: string;
  isFinal: boolean;
  nextStageId?: string; // Para onde vai quando todas as etapas concluírem
  steps: PcpStep[]; // Etapas internas desta aba
}

// Representa o item de produção transitando nas abas
export interface PcpItem {
  id: string;
  order_id: string;
  current_stage_id: string;
  current_step_id: string;
  status: string;
  step_data: Record<string, any>; // Salva as escolhas feitas nos dropdowns, forms, etc.
}
