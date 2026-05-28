import { defineStore } from 'pinia';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { v4 as uuidv4 } from 'uuid';
import type { PcpWorkflow, WorkflowNode, WorkflowEdge } from '@/types/dynamicPcp';

export const useDynamicPcpStore = defineStore('dynamicPcp', {
  state: () => ({
    workflows: [] as PcpWorkflow[],
    activeWorkflow: null as PcpWorkflow | null,
    loading: false,
    isSaving: false,
  }),

  actions: {
    async fetchWorkflows() {
      this.loading = true;
      try {
        const { data, error } = await supabase
          .from('pcp_workflows')
          .select('*')
          .order('created_at', { ascending: false });

        if (error) throw error;
        this.workflows = data || [];

        const active = this.workflows.find(w => w.is_active);
        if (active) {
          this.activeWorkflow = active;
        }
      } catch (error: any) {
        const appStore = useAppStore();
        appStore.showSnackbar('Erro ao carregar workflows: ' + error.message, 'error');
      } finally {
        this.loading = false;
      }
    },

    async loadWorkflow(id: string) {
      this.loading = true;
      try {
        const { data, error } = await supabase
          .from('pcp_workflows')
          .select('*')
          .eq('id', id)
          .single();

        if (error) throw error;
        this.activeWorkflow = data;
      } catch (error: any) {
        const appStore = useAppStore();
        appStore.showSnackbar('Erro ao carregar o workflow selecionado.', 'error');
      } finally {
        this.loading = false;
      }
    },

    async saveWorkflow(workflow: PcpWorkflow) {
      this.isSaving = true;
      const appStore = useAppStore();
      try {
        const payload = {
          id: workflow.id,
          name: workflow.name,
          version: workflow.version,
          is_active: workflow.is_active,
          nodes: workflow.nodes,
          edges: workflow.edges,
          updated_at: new Date().toISOString()
        };

        const { error } = await supabase
          .from('pcp_workflows')
          .upsert(payload);

        if (error) throw error;

        appStore.showSnackbar('Workflow salvo com sucesso no banco de dados.', 'success');
        await this.fetchWorkflows();
      } catch (error: any) {
        appStore.showSnackbar('Erro ao salvar workflow: ' + error.message, 'error');
      } finally {
        this.isSaving = false;
      }
    },

    async setActiveWorkflow(id: string) {
      this.loading = true;
      const appStore = useAppStore();
      try {
        // Desativa todos
        await supabase.from('pcp_workflows').update({ is_active: false }).neq('id', '0');
        // Ativa o selecionado
        const { error } = await supabase.from('pcp_workflows').update({ is_active: true }).eq('id', id);

        if (error) throw error;

        appStore.showSnackbar('Workflow ativado. O Motor PCP agora usará esta configuração.', 'success');
        await this.fetchWorkflows();
      } catch (error: any) {
        appStore.showSnackbar('Erro ao ativar workflow: ' + error.message, 'error');
      } finally {
        this.loading = false;
      }
    },

    // ============================================================================
    // A MÁGICA: Geração automática da estrutura paralela baseada no legado
    // ============================================================================
    async seedLegacyWorkflow() {
      const appStore = useAppStore();
      this.loading = true;

      try {
        const nodes: WorkflowNode[] = [];
        const edges: WorkflowEdge[] = [];

        // 1. NÓ DE ORIGEM (Leitura da tabela order_items)
        const sourceNodeId = uuidv4();
        nodes.push({
          id: sourceNodeId,
          type: 'SOURCE',
          ui_x: 50, ui_y: 300, width: 200, height: 100,
          data: {
            name: 'Banco de Dados: order_items',
            description: 'Traz os itens não finalizados e fantasmas',
            tableName: 'order_items',
            entryConditions: ["status != 'delivered'"],
            autoRefreshInterval: 30000 // 30s
          }
        });

        // 2. CRIAR AS ABAS (Baseado nas kpiTabs do ProductionControl.vue)
        const stages = [
          { title: 'Design', statuses: ['design_pending', 'customer_approval', 'approved_by_seller', 'approved_by_designer'], color: '#2196F3' },
          { title: 'PCP Geral', statuses: ['design_released'], color: '#9C27B0' },
          { title: 'Separação', statuses: ['waiting_separation', 'in_separation'], color: '#00BCD4' },
          { title: 'Impressão', statuses: ['waiting_print', 'printing'], color: '#FFC107' },
          { title: 'Calandra', statuses: ['printed', 'waiting_calandra', 'in_calandra', 'in_production'], color: '#FF9800' },
          { title: 'Faturamento', statuses: ['billing_pending'], color: '#455A64' },
          { title: 'Expedição', statuses: ['waiting_release', 'ready_for_delivery', 'completed'], color: '#4CAF50' }
        ];

        let prevStageId: string | null = null;
        const stageIds: Record<string, string> = {};

        stages.forEach((stage, index) => {
          const stageId = uuidv4();
          stageIds[stage.title] = stageId;

          nodes.push({
            id: stageId,
            type: 'STAGE',
            ui_x: 350 + (index * 300), ui_y: 100, width: 250, height: 120,
            data: {
              name: stage.title,
              title: stage.title,
              order: index + 1,
              color: stage.color,
              icon: 'mdi-view-column',
              mappedStatuses: stage.statuses,
              permissions: {
                viewRoles: ['admin', 'manager', 'pcp_operator', 'seller'],
                operateRoles: ['admin', 'manager', 'pcp_operator']
              },
              allowBatch: true,
              allowDragAndDrop: true,
              isFinalStage: stage.title === 'Expedição'
            }
          });

          // Conecta a Origem à primeira Aba
          if (index === 0) {
            edges.push({ id: uuidv4(), fromId: sourceNodeId, toId: stageId });
          }

          // Conecta a aba anterior à atual (fluxo linear padrão)
          if (prevStageId) {
            edges.push({ id: uuidv4(), fromId: prevStageId, toId: stageId });
          }
          prevStageId = stageId;
        });

        // 3. REGRAS DE ERRO / RETRABALHO (Exceção: Calandra -> Impressão)
        const reworkNodeId = uuidv4();
        nodes.push({
          id: reworkNodeId,
          type: 'REWORK',
          ui_x: 1250, ui_y: 400, width: 200, height: 120,
          data: {
            name: 'Reportar Falha na Calandra',
            description: 'Devolve o item para impressão com foto e justificativa.',
            requireJustification: true,
            requireAttachment: true,
            notifyRoles: ['admin', 'manager'],
            targetStatus: 'waiting_print', // Status no banco
            targetStageNodeId: stageIds['Impressão'] // Coluna visual
          }
        });

        // Conecta a aba Calandra ao nó de retrabalho
        edges.push({ id: uuidv4(), fromId: stageIds['Calandra'], toId: reworkNodeId, condition: 'on_error_click' });
        // Conecta o retrabalho de volta à Impressão
        edges.push({ id: uuidv4(), fromId: reworkNodeId, toId: stageIds['Impressão'] });

        // 4. FORMULÁRIO DE CALANDRA (Abertura de Produção)
        const formCalandraId = uuidv4();
        nodes.push({
          id: formCalandraId,
          type: 'FORM',
          ui_x: 1250, ui_y: 250, width: 220, height: 150,
          data: {
            name: 'Enviar para Calandra',
            fields: [
              { id: uuidv4(), name: 'machine', label: 'Máquina', type: 'select', isRequired: true, dataSource: 'custom', customOptions: ['Calandra 1', 'Calandra 2'] },
              { id: uuidv4(), name: 'operator', label: 'Operador', type: 'select', isRequired: true, dataSource: 'employees' }
            ]
          }
        });
        edges.push({ id: uuidv4(), fromId: stageIds['Calandra'], toId: formCalandraId, condition: 'on_start_production' });

        const newWorkflow: PcpWorkflow = {
          id: uuidv4(),
          name: 'PCP Legado (Clone de Produção)',
          version: '1.0.0',
          is_active: false, // Inicia inativo para o usuário revisar antes de ativar
          nodes,
          edges
        };

        // Salva diretamente
        await this.saveWorkflow(newWorkflow);
        appStore.showSnackbar('Modelo Legado (Clone) gerado com sucesso. Verifique no Builder.', 'success');

      } catch (error: any) {
        appStore.showSnackbar('Erro ao gerar Seed Legado: ' + error.message, 'error');
      } finally {
        this.loading = false;
      }
    },

    // ============================================================================
    // ASSISTENTE DE CRIAÇÃO (WIZARD)
    // ============================================================================
    async generateWizardWorkflow(nicheId: string | null, config: any) {
      this.loading = true;
      const appStore = useAppStore();

      try {
        const nodes: WorkflowNode[] = [];
        const edges: WorkflowEdge[] = [];
        let currentX = 50;
        let prevNodeId: string | null = null;

        const connect = (from: string, to: string, condition?: string) => {
          edges.push({ id: uuidv4(), fromId: from, toId: to, condition });
        };

        const addNode = (type: any, width: number, data: any, yOffset = 0) => {
          const id = uuidv4();
          nodes.push({
            id, type,
            ui_x: currentX, ui_y: 200 + yOffset,
            width, height: 120, data
          });
          currentX += width + 100; // Espaçamento automático visual
          return id;
        };

        // 1. NÓ DE ORIGEM (SOURCE)
        const sourceId = addNode('SOURCE', 220, {
          name: `Entrada: ${config.origin === 'erp' ? 'Pedidos ERP' : config.origin === 'ecommerce' ? 'Loja Virtual' : 'Lançamento Manual'}`,
          description: 'Captura novos itens automaticamente.',
          tableName: 'order_items',
          entryConditions: ["status = 'pending'"],
          autoRefreshInterval: 15000
        });
        prevNodeId = sourceId;

        // 2. APROVAÇÃO (Opcional)
        if (config.hasCustomerApproval) {
          const approvalId = addNode('STAGE', 250, {
            name: 'Aprovação Cliente', title: 'Aprovação', order: 1, color: '#3f51b5', icon: 'mdi-check-decagram',
            mappedStatuses: ['waiting_approval', 'customer_review'],
            permissions: { viewRoles: ['admin', 'seller'], operateRoles: ['admin', 'seller'] },
            allowBatch: false, allowDragAndDrop: true, isFinalStage: false
          });
          connect(prevNodeId, approvalId);
          prevNodeId = approvalId;
        }

        // 3. ETAPAS MACRO DINÂMICAS POR NICHO
        let macroStages = [];
        if (nicheId === 'confeccao' || nicheId === 'estamparia' || nicheId === 'textil') {
          macroStages = [
            { name: 'Corte', color: '#ff9800', statuses: ['cutting'] },
            { name: 'Produção / Costura', color: '#e91e63', statuses: ['sewing', 'production'] }
          ];
        } else if (nicheId === 'restaurante' || nicheId === 'padaria') {
          macroStages = [
            { name: 'Preparo / Cozinha', color: '#ff5722', statuses: ['cooking'] },
            { name: 'Montagem', color: '#8bc34a', statuses: ['assembling'] }
          ];
        } else if (nicheId === 'engenharia' || nicheId === 'tech') {
          macroStages = [
            { name: 'Planejamento', color: '#607d8b', statuses: ['planning'] },
            { name: 'Execução', color: '#009688', statuses: ['executing'] }
          ];
        } else {
          macroStages = [
            { name: 'Produção Inicial', color: '#2196f3', statuses: ['prod_stage_1'] },
            { name: 'Finalização', color: '#9c27b0', statuses: ['prod_stage_2'] }
          ];
        }

        // Gera as etapas de produção
        const stageNodeIds: Record<string, string> = {};
        macroStages.forEach((stage, idx) => {
          const stageId = addNode('STAGE', 250, {
            name: stage.name, title: stage.name, order: idx + 2, color: stage.color, icon: 'mdi-cog-outline',
            mappedStatuses: stage.statuses,
            permissions: { viewRoles: ['admin', 'operator'], operateRoles: ['operator'] },
            allowBatch: true, allowDragAndDrop: true, isFinalStage: false
          });
          stageNodeIds[stage.name] = stageId;
          connect(prevNodeId!, stageId);
          prevNodeId = stageId;

          // Se tiver formulário de apontamento, atrela à etapa de Produção principal
          if (config.hasMachineTracking && idx === 0) {
             const formId = uuidv4();
             nodes.push({
               id: formId, type: 'FORM', ui_x: currentX - 350, ui_y: 400, width: 220, height: 150,
               data: {
                 name: `Apontar ${stage.name}`,
                 fields: [
                   { id: uuidv4(), name: 'machine', label: 'Equipamento', type: 'select', isRequired: true, dataSource: 'custom', customOptions: ['Equipamento A', 'Equipamento B'] },
                   { id: uuidv4(), name: 'operator', label: 'Operador(a)', type: 'select', isRequired: true, dataSource: 'employees' }
                 ]
               }
             });
             // Conecta o Stage ao Form via trigger
             connect(stageId, formId, 'on_start_click');
          }
        });

        // 4. CONTROLE DE QUALIDADE E RETRABALHO
        if (config.hasQualityControl) {
          const qcId = addNode('STAGE', 250, {
            name: 'Controle de Qualidade', title: 'Inspeção', order: 98, color: '#f44336', icon: 'mdi-shield-check',
            mappedStatuses: ['quality_check'],
            permissions: { viewRoles: ['admin', 'manager'], operateRoles: ['manager', 'qc_inspector'] },
            allowBatch: false, allowDragAndDrop: true, isFinalStage: false
          });
          connect(prevNodeId!, qcId);
          prevNodeId = qcId;

          // Cria nó de Rework (Retrabalho)
          const reworkId = uuidv4();
          nodes.push({
             id: reworkId, type: 'REWORK', ui_x: currentX - 350, ui_y: 50, width: 200, height: 120,
             data: {
               name: 'Reprovar Item',
               description: 'Devolve item para correção',
               requireJustification: true, requireAttachment: true, notifyRoles: ['manager'],
               targetStatus: macroStages[0].statuses[0],
               targetStageNodeId: stageNodeIds[macroStages[0].name]
             }
          });
          connect(qcId, reworkId, 'on_reject');
          // Conecta retrabalho de volta para a primeira etapa produtiva
          connect(reworkId, stageNodeIds[macroStages[0].name]);
        }

        // 5. EXPEDIÇÃO E FATURAMENTO
        if (config.hasBilling) {
          const expId = addNode('STAGE', 250, {
            name: 'Expedição / Finalizado', title: 'Finalizados', order: 99, color: '#4caf50', icon: 'mdi-truck-check',
            mappedStatuses: ['ready_to_ship', 'completed'],
            permissions: { viewRoles: ['admin', 'shipping'], operateRoles: ['shipping'] },
            allowBatch: true, allowDragAndDrop: true, isFinalStage: true
          });
          connect(prevNodeId!, expId);
        }

        const newWorkflow: PcpWorkflow = {
          id: uuidv4(),
          name: `Fluxo Gerado: ${nicheId?.toUpperCase()} (${new Date().toLocaleDateString()})`,
          version: '1.0.0',
          is_active: false,
          nodes,
          edges
        };

        await this.saveWorkflow(newWorkflow);

      } catch (error: any) {
        throw new Error(error.message);
      } finally {
        this.loading = false;
      }
    }
  }
});
