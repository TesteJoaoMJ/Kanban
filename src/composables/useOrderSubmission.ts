import { ref, reactive } from 'vue';
import { supabase } from '@/api/supabase';
import { useAppStore } from '@/stores/app';
import { useUserStore } from '@/stores/user';
import { useMjCashSessionStore } from '@/stores/mjCashSession';
import { format } from 'date-fns';
import { useAuditLogger } from '@/composables/useAuditLogger';

export function useOrderSubmission() {
  const appStore = useAppStore();
  const userStore = useUserStore();
  const cashStore = useMjCashSessionStore();
  const { logSecureAction, logBusinessEvent } = useAuditLogger();

  const isSubmitting = ref(false);
  const showSubmittingModal = ref(false);
  const createdOrderId = ref<string | null>(null);

  const submissionStatus = reactive({
    step: 'idle' as 'idle' | 'validating' | 'uploading_files' | 'syncing_supabase' | 'finalizing' | 'success' | 'error',
    message: 'Iniciando...',
  });

  const userFriendlyMessage = ref('');
  const programmerMessage = ref('');

  const sanitizeName = (name: string) => {
    return name.replace(/\s/g, '_').replace(/[^\w.\-]/g, '');
  };

  // Resolve ID do método de pagamento localmente (UUID)
  const resolveMethodUuid = async (id: string | number | null, debugName: string) => {
      if (!id) return null;

      const strId = String(id);

      // Se já é UUID, retorna direto
      if (/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(strId)) {
          return strId;
      }

      // Procura primeiro pelo campo gestao_click_id (para legado)
      const { data } = await supabase
          .from('finance_payment_methods')
          .select('id')
          .eq('gestao_click_id', strId)
          .maybeSingle();

      if (data) return data.id;

      // Fallback por nome
      if (isNaN(Number(strId))) {
           const { data: byName } = await supabase
              .from('finance_payment_methods')
              .select('id')
              .ilike('name', strId)
              .maybeSingle();

           if (byName) return byName.id;
      }

      console.warn(`⚠️ [DEBUG] Método de pagamento não resolvido para: ${strId}`);
      return null;
  };

  const uploadFile = async (file: File | Blob, bucket: string, path: string): Promise<string> => {
    const { data, error } = await supabase.storage
        .from(bucket)
        .upload(path, file, { upsert: true });

    if (error) throw error;

    return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
  };

  const parseSubmissionError = (error: any) => {
    let userMsg = "Um erro inesperado ocorreu.";
    let devMsg = error.message || JSON.stringify(error);

    console.error("🔥 [RAW ERROR] Parse Error:", error);

    if (typeof error.message === 'string') {
      const msg = error.message.toLowerCase();

      if (msg.includes('estoque insuficiente')) {
          userMsg = "Estoque insuficiente para os itens.";
          devMsg = msg;
      }
      else if (msg.includes('timeout')) {
          userMsg = "O servidor demorou muito para responder.";
      }
      else if (msg.includes('400')) {
          userMsg = "Erro de validação (Divergência de valores ou dados incompletos).";
      }
      else if (msg.includes('permissão') || msg.includes('policy')) {
          userMsg = "Erro de Permissão: Seu usuário não tem permissão para esta ação.";
      }
      else if (msg.includes('invalid input syntax for type uuid')) {
          devMsg = `Erro de Tipo UUID: O sistema tentou salvar um ID numérico em um campo de texto. ${msg}`;
      }
    }

    return { userMsg, devMsg };
  };

  const sendErrorToWhatsApp = (userFullName: string, clientName: string, orderNumber: number | null, itemsLength: number, totalValue: number) => {
    try {
      const phone = '5515991876055';
      const messageParts = [
          "🔥 *ERRO CRÍTICO (DEBUG)* 🔥",
          `*Dev Msg:* ${programmerMessage.value}`
      ];
      const encodedMessage = encodeURIComponent(messageParts.join('\n'));
      window.open(`https://wa.me/${phone}?text=${encodedMessage}`, '_blank');
    } catch (e) {
        console.error(e);
    }
  };

  // =========================================================================
  // BAIXA LOCAL DE ESTOQUE (Supabase)
  // =========================================================================
  const processLocalStockDeduction = async (orderItems: any[], stockItems: any[]) => {
      console.group("📦 [DEBUG] Baixa de Estoque Local");

      const productQtyMap = new Map<string, number>();
      for (const item of orderItems) {
          // No NewOrder nós passamos o produto mapeando o nome para o campo 'nome'.
          const product = stockItems.find(p => p.fabric_type === item.fabric_type);
          if (product) {
              const currentQty = productQtyMap.get(product.id) || 0;
              productQtyMap.set(product.id, currentQty + (Number(item.quantity) || 0));
          }
      }

      const stockUpdatePromises = Array.from(productQtyMap.entries()).map(async ([productId, totalQtyToRemove]) => {
          try {
              const { data: stockItem } = await supabase
                  .from('stock')
                  .select('*')
                  .eq('id', productId)
                  .maybeSingle(); // <-- CORREÇÃO: Evita erro se retornar vazio ou duplicado

              if (stockItem) {
                  const currentLocalStock = Number(stockItem.available_meters || stockItem.quantity || 0);
                  const newLocalStock = currentLocalStock - totalQtyToRemove;

                  const updatePayload: any = { updated_at: new Date() };
                  if ('available_meters' in stockItem) updatePayload.available_meters = newLocalStock;
                  if ('quantity' in stockItem) updatePayload.quantity = newLocalStock;

                  if (Object.keys(updatePayload).length > 1) {
                      await supabase
                          .from('stock')
                          .update(updatePayload)
                          .eq('id', stockItem.id);
                  }

                if (stockItem.low_stock_threshold && newLocalStock < stockItem.low_stock_threshold) {
                    appStore.triggerLowStockAlert(stockItem.fabric_type, newLocalStock);

                    await logBusinessEvent(
                        'Estoque',
                        'STATUS_CHANGE',
                        `O sistema disparou automaticamente um alerta de ESTOQUE BAIXO para o tecido "${stockItem.fabric_type}". Restam apenas ${newLocalStock} metros (o limite de segurança é ${stockItem.low_stock_threshold}m).`,
                        {
                            fabric_type: stockItem.fabric_type,
                            current_stock: newLocalStock,
                            threshold: stockItem.low_stock_threshold
                        },
                        stockItem.id
                    );
                }
              }
          } catch (error) {
              console.error(`[DEBUG ESTOQUE] Falha ao baixar localmente o produto ${productId}:`, error);
          }
      });

      await Promise.all(stockUpdatePromises);
      console.log("✅ Baixa de estoque concluída no Supabase.");
      console.groupEnd();
  };

  // =========================================================================
  // SALVAMENTO COMPLETO NO SUPABASE
  // =========================================================================
  const completeSubmissionProcess = async (
      orderNumber: number,
      orderHeader: any,
      orderItems: any[],
      currentDraftId: string | null,
      paymentDetails: any,
      existingOrderId?: string | null,
      creditDetails?: any
  ) => {
      console.group("🚀 [DEBUG] completeSubmissionProcess");
      const userProfile = userStore.profile;
      let finalOrderId = existingOrderId;
      const processedDownPayments: any[] = [];

      // 1. Uploads de comprovantes
      if (paymentDetails.downPayments && paymentDetails.downPayments.length > 0) {
          submissionStatus.step = 'uploading_files';
          submissionStatus.message = 'Enviando comprovantes...';

          for (const dp of paymentDetails.downPayments) {
              let proofUrl = null;
              if (dp.file) {
                  const filePath = `proofs/${orderNumber}-${Date.now()}-${sanitizeName(dp.file.name)}`;
                  try {
                      proofUrl = await uploadFile(dp.file, 'proofs', filePath);
                  } catch (err) {
                      console.warn("⚠️ Falha no upload:", err);
                  }
              }
              processedDownPayments.push({ ...dp, proof_url: proofUrl });
          }
      }

      // 2. INSERÇÃO NA TABELA ORDERS
      if (!finalOrderId) {
          submissionStatus.step = 'syncing_supabase';
          submissionStatus.message = 'Salvando no banco de dados...';

          const totalOrderValueCalculated = orderItems.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.valor_unitario)), 0);
          const totalRealMeters = orderItems.reduce((acc, i) => acc + (Number(i.final_meters_for_db) || Number(i.quantity_meters) || 0), 0);

          const allItemsReady = orderItems.every(i => i.is_ready_for_billing);
          const workflowStatus = allItemsReady ? 'ready_for_delivery' : 'design_pending';

          let totalDownPaymentValue = paymentDetails.entry_value || 0;
          if (paymentDetails.downPayments) {
              totalDownPaymentValue = paymentDetails.downPayments.reduce((acc: number, dp: any) => acc + (Number(dp.value) || 0), 0);
          }

          const finalOrderStatus = (totalDownPaymentValue > 0) ? 'Parcialmente Faturado' : 'Em Aberto';

          let finalCustomerUuid = String(orderHeader.customer_id);
          const isUuid = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(finalCustomerUuid);

          // Fallback para caso ainda receba ID legado em algum lugar
          if (!isUuid) {
              const { data: existing } = await supabase.from('customers_mj').select('id').eq('gestao_click_id', finalCustomerUuid).maybeSingle();
              if (existing) finalCustomerUuid = existing.id;
          }

          const forecastDate = appStore.calculateForecastDate(new Date());
          const forecastDateStr = forecastDate ? format(forecastDate, 'yyyy-MM-dd') : null;

          const fullDetails = {
              entry_value: totalDownPaymentValue,
              downPayments: processedDownPayments,
              entry_method_id: paymentDetails.entry_method_id,
              credit_used_value: creditDetails?.value || 0,
              payment_method_id: paymentDetails.installment_payment_method_id,
              installments_schedule: paymentDetails.installments,
              observation: orderHeader.observation || '',
              forecast_delivery_date: forecastDateStr
          };

          const orderPayload = {
              order_number: orderNumber,
              customer_id: finalCustomerUuid,
              customer_name: orderHeader.customer_name,
              store_id: userStore.activeStoreId,
              cash_session_id: cashStore.currentSession?.id || null,
              total_value: totalOrderValueCalculated,
              quantity_meters: totalRealMeters,
              status: workflowStatus,
              financial_status: finalOrderStatus,
              is_invoiced: false,
              created_by: userProfile?.id,
              forecast_delivery_date: forecastDateStr,
              notes: orderHeader.observation || null,
              is_launch: true,
              details: fullDetails,
              has_down_payment: processedDownPayments.length > 0,
              down_payment_proof_url: processedDownPayments.length > 0 ? processedDownPayments[0].proof_url : null
          };

          const { data: orderData, error: orderError } = await supabase
              .from('orders')
              .insert(orderPayload)
              .select()
              .single();

          if (orderError) throw orderError;

          finalOrderId = orderData.id;

          // ==============================================================
          // CORREÇÃO: EXCLUSÃO IMEDIATA DO RASCUNHO (Fire-and-forget)
          // ==============================================================
          if (currentDraftId) {
                        const { error: deleteDraftErr } = await supabase
                            .from('order_drafts')
                            .delete()
                            .eq('id', currentDraftId);

                        if (deleteDraftErr) {
                            console.error("🔥 ERRO AO DELETAR RASCUNHO:", deleteDraftErr);
                        } else {
                            console.log("✅ Rascunho obliterado do banco.");
                        }
                    }

          await logBusinessEvent(
              'Vendas',
              'Criação',
              `Montou e registrou o Pedido #${orderNumber} no sistema para o cliente ${orderHeader.customer_name}.`,
              orderPayload,
              finalOrderId
          );

          // 3. Insere os Itens
          const itemsPayload = orderItems.map(i => {
              return {
                  order_id: finalOrderId,
                  stamp_ref: i.stamp_ref || 'AVULSO',
                  stamp_image_url: i.stamp_image_url,
                  fabric_type: i.fabric_type,
                  quantity_meters: i.final_meters_for_db || i.quantity_meters,
                  unit_of_measure: i.unit_of_measure || 'm',
                  quantity_unit: i.unit_of_measure === 'kg' ? i.quantity : null,
                  total_value_items: Number((Number(i.quantity) * Number(i.valor_unitario)).toFixed(2)),
                  status: i.is_ready_for_billing ? 'completed' : 'design_pending',
                  is_exclusive: false,
                  design_tag: i.design_tag || 'Desenvolvimento',
                  notes: i.observation || i.notes,
                  rendimento: i.rendimento
              };
          });

          const { error: itemsError } = await supabase.from('order_items').insert(itemsPayload);
          if (itemsError) throw itemsError;
      }

      // 4. LANÇAR FINANCEIRO NO SUPABASE
      console.group("💰 [DEBUG] Inserção Financeira");

      if (processedDownPayments.length > 0 && finalOrderId) {
          try {
              const { data: orderData, error: orderFetchError } = await supabase
                  .from('orders')
                  .select('customer_id')
                  .eq('id', finalOrderId)
                  .single();

              if (orderFetchError || !orderData) throw new Error("Falha catastrófica: Não foi possível recuperar o Cliente UUID.");

              const authoritativeCustomerUuid = orderData.customer_id;
              const { data: allComps } = await supabase.from('companies').select('id, cnpj');
              const mrJackyId = allComps?.find(c => c.cnpj && c.cnpj.replace(/\D/g, '') === '20631721000107')?.id || null;

              const { data: chart } = await supabase
                  .from('finance_chart_of_accounts')
                  .select('id')
                  .or('code.eq.1.01.001,name.ilike.%venda de produtos%')
                  .limit(1)
                  .maybeSingle();

              const safeChartId = chart?.id || null;

              let safeBankId = null;
              const { data: bank } = await supabase.from('finance_accounts').select('id').eq('is_active', true).limit(1).maybeSingle();
              if (bank) safeBankId = bank.id;
                  const receivablesPayload = await Promise.all(processedDownPayments.map(async (dp: any, idx: number) => {
                  const validMethodUuid = await resolveMethodUuid(dp.method_id, `Sinal ${idx+1}`);

                  return {
                      description: `Sinal ${idx + 1} - Pedido #${orderNumber}`,
                      value: Number(dp.value),
                      due_date: format(new Date(), 'yyyy-MM-dd'),
                      competence_date: new Date(),
                      payment_date: new Date(),
                      receipt_date: new Date(),
                      status: 'pago',
                      order_id: finalOrderId,
                      customer_id: authoritativeCustomerUuid,
                      // >>> USA OS IDs INJETADOS PELO NEWORDER.VUE <<<
                      chart_of_accounts_id: dp.chart_of_accounts_id || null,
                      bank_account_id: dp.bank_account_id || null,
                      payment_method_id: validMethodUuid,
                      created_by: userProfile?.id,
                      company_id: mrJackyId
                  };
              }));

              const { error: finError } = await supabase.from('finance_receivables').insert(receivablesPayload);

              if (finError) {
                  throw new Error("Erro ao salvar financeiro: " + finError.message);
              } else {
                  console.log("✅ Financeiro inserido com sucesso!");
                  await logBusinessEvent(
                      'Financeiro',
                      'Criação',
                      `Gerou ${receivablesPayload.length} título(s) a receber referentes ao Pedido #${orderNumber}.`,
                      receivablesPayload,
                      finalOrderId
                  );
              }

              if (cashStore.isSessionOpen && cashStore.currentSession) {
                  for (const dp of processedDownPayments) {
                      if (cashStore.isCashMethod(dp.method_id)) {
                          try {
                              await cashStore.registerMovement('sale_cash', Number(dp.value), `Entrada Pedido #${orderNumber}`, finalOrderId);
                          } catch (err) {
                              console.warn("Erro ao registrar movimento de caixa:", err);
                          }
                      }
                  }
              }

          } catch (innerErr) {
              console.error("❌ Exceção Financeira:", innerErr);
              throw innerErr;
          }
      }
      console.groupEnd();

      // Finalização
      submissionStatus.step = 'finalizing';
      submissionStatus.message = 'Finalizando...';

      submissionStatus.step = 'success';
      submissionStatus.message = `Pedido #${orderNumber} lançado com sucesso!`;
      createdOrderId.value = finalOrderId;
      isSubmitting.value = false;
      console.groupEnd();
  };

  const handleError = (error: any) => {
      console.error("🔥 [DEBUG] Handler de Erro:", error);
      const { userMsg, devMsg } = parseSubmissionError(error);

      userFriendlyMessage.value = userMsg;
      programmerMessage.value = devMsg;

      submissionStatus.step = 'error';
      submissionStatus.message = 'Falha no Lançamento';
      isSubmitting.value = false;
      console.groupEnd();
  };

  // =========================================================================
  // FUNÇÃO PRINCIPAL DE LAUNCH
  // =========================================================================
  const submitLaunch = async (
      currentOrderNumber: number,
      orderHeader: any,
      orderItems: any[],
      paymentDetails: any,
      salespeopleList: any[],
      saleStatuses: any[],
      products: any[],
      stockItems: any[],
      userProfile: any,
      currentDraftId: string | null,
      existingOrderId?: string,
      creditDetails: { value: number, gestaoMethodId: string | number | null } = { value: 0, gestaoMethodId: null }
  ) => {
    isSubmitting.value = true;
    showSubmittingModal.value = true;
    submissionStatus.step = 'idle';
    submissionStatus.message = 'Iniciando...';
    userFriendlyMessage.value = '';
    programmerMessage.value = '';

    console.group("🚀 [DEBUG] submitLaunch (NATIVO SUPABASE)");

    try {
      submissionStatus.step = 'validating';
      if (!orderHeader.customer_name) {
          throw new Error("Nome do cliente não encontrado.");
      }

      // 1. Processar a Baixa do Estoque (Local)
      await processLocalStockDeduction(orderItems, stockItems);

      // 2. Salva a Venda inteira no Supabase via Inserção Direta
      await completeSubmissionProcess(
          currentOrderNumber,
          orderHeader,
          orderItems,
          currentDraftId,
          paymentDetails,
          existingOrderId,
          creditDetails
      );

    } catch (error: any) {
        handleError(error);
    }
  };

  return {
      isSubmitting,
      showSubmittingModal,
      submissionStatus,
      userFriendlyMessage,
      programmerMessage,
      createdOrderId,
      submitLaunch,
      sendErrorToWhatsApp
  };
}
