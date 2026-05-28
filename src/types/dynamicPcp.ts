// src/types/dynamicPcp.ts

export type NodeType =
  | 'SOURCE'
  | 'STAGE'
  | 'STEP'
  | 'FORM'
  | 'DECISION'
  | 'REWORK'
  | 'OUTPUT'
  | 'AUDIT';

export interface WorkflowEdge {
  id: string;
  fromId: string;
  toId: string;
  condition?: string; // Expressão lógica opcional para o fio
}

export interface BaseNodeData {
  name: string;
  description?: string;
}

// A. NÓ DE ORIGEM DE DADOS
export interface SourceNodeData extends BaseNodeData {
  tableName: string; // ex: 'order_items'
  entryConditions: string[]; // ex: ["status = 'design_released'"]
  autoRefreshInterval: number; // em milissegundos, 0 para desativar
}

// B. NÓ DE ABA / COLUNA
export interface StageNodeData extends BaseNodeData {
  title: string;
  order: number;
  color: string;
  icon: string;
  mappedStatuses: string[]; // Statuses reais do banco que caem nesta aba
  permissions: {
    viewRoles: string[]; // Quem pode ver
    operateRoles: string[]; // Quem pode arrastar/clicar
  };
  allowBatch: boolean; // Aceita ações em lote
  allowDragAndDrop: boolean; // Aceita arrastar
  isFinalStage: boolean; // Se concluir esta aba finaliza o processo
}

// C. NÓ DE ETAPA INTERNA
export interface StepNodeData extends BaseNodeData {
  actionName: string; // Texto do botão
  stepType: 'button' | 'checklist' | 'quality_check' | 'approval';
  isMandatory: boolean;
  blocksProgression: boolean; // Impede que o item avance se não for feito
}

// D. NÓ DE FORMULÁRIO (Campos Dinâmicos)
export interface FormField {
  id: string;
  name: string; // Chave no banco/payload
  label: string;
  type: 'text' | 'textarea' | 'select' | 'multiselect' | 'date' | 'number' | 'boolean' | 'file';
  isRequired: boolean;
  dataSource?: 'clients' | 'suppliers' | 'employees' | 'products' | 'custom';
  customOptions?: string[]; // Usado se dataSource for 'custom'
}

export interface FormNodeData extends BaseNodeData {
  fields: FormField[];
}

// E. NÓ DE DECISÃO / DESVIO
export interface DecisionRule {
  id: string;
  condition: string; // Expressão avaliada. ex: "form.quality_passed == false"
  targetNodeId: string;
}

export interface DecisionNodeData extends BaseNodeData {
  rules: DecisionRule[];
  defaultTargetNodeId: string | null; // Se nenhuma regra bater, vai pra cá
}

// F. NÓ DE ERRO / RETRABALHO
export interface ReworkNodeData extends BaseNodeData {
  requireJustification: boolean;
  requireAttachment: boolean;
  notifyRoles: string[]; // Quem recebe alerta
  targetStatus: string; // Status que será forçado no banco (ex: 'waiting_print')
  targetStageNodeId: string | null; // Aba para qual o item deve voltar visualmente
}

// G. NÓ DE SAÍDA / DESTINO
export interface OutputNodeData extends BaseNodeData {
  destinationType: 'update_record' | 'send_to_billing' | 'finish_order' | 'return_to_design';
  finalStatus: string; // Novo status no banco
  payloadMappings: Record<string, string>; // O que salvar no banco
}

// H. NÓ DE LOG / AUDITORIA
export interface AuditNodeData extends BaseNodeData {
  eventName: string; // Nome da ação salva no log
  logLevel: 'info' | 'warning' | 'error' | 'critical';
  metadataTemplate: string[]; // Quais chaves do form incluir no payload de log
}

// União de todos os tipos de dados possíveis para um Nó
export type NodeData =
  | SourceNodeData
  | StageNodeData
  | StepNodeData
  | FormNodeData
  | DecisionNodeData
  | ReworkNodeData
  | OutputNodeData
  | AuditNodeData;

export interface WorkflowNode {
  id: string;
  type: NodeType;
  ui_x: number;
  ui_y: number;
  width: number;
  height: number;
  data: NodeData;
}

export interface PcpWorkflow {
  id: string;
  name: string;
  version: string;
  is_active: boolean;
  nodes: WorkflowNode[];
  edges: WorkflowEdge[];
  created_at?: string;
  updated_at?: string;
}
