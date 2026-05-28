

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_jsonschema" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."access_status_enum" AS ENUM (
    'active',
    'revalidation_required',
    'blocked'
);


ALTER TYPE "public"."access_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."cajuia_account_nature" AS ENUM (
    'ativo',
    'passivo',
    'patrimonio',
    'receita',
    'despesa'
);


ALTER TYPE "public"."cajuia_account_nature" OWNER TO "postgres";


CREATE TYPE "public"."finance_status" AS ENUM (
    'Provisionado',
    'em_aberto',
    'pago',
    'em_atraso',
    'parcialmente_pago',
    'cancelado',
    'faturado',
    'atrasado'
);


ALTER TYPE "public"."finance_status" OWNER TO "postgres";


CREATE TYPE "public"."order_item_payload" AS (
	"fabric_type" "text",
	"stamp_ref" "text",
	"quantity_meters" numeric,
	"stamp_image_url" "text",
	"design_tag" "text",
	"notes" "text",
	"quantity_unit" numeric,
	"unit_of_measure" "text",
	"rendimento" numeric
);


ALTER TYPE "public"."order_item_payload" OWNER TO "postgres";


CREATE TYPE "public"."risk_flag_enum" AS ENUM (
    'none',
    'low',
    'medium',
    'high'
);


ALTER TYPE "public"."risk_flag_enum" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'user',
    'guest',
    'vendedor',
    'designer',
    'producao',
    'super_admin',
    'financeiro',
    'impressor',
    'faturador'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_business_days"("start_date" "date", "number_of_days" integer) RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  new_date date := start_date;
  days_added integer := 0;
  step integer := CASE WHEN number_of_days > 0 THEN 1 ELSE -1 END;
  target_days integer := abs(number_of_days);
BEGIN
  WHILE days_added < target_days LOOP
    new_date := new_date + step;
    -- No PostgreSQL, Domingo é 0 (usando EXTRACT(DOW FROM ...))
    IF EXTRACT(DOW FROM new_date) <> 0 THEN
      days_added := days_added + 1;
    END IF;
  END LOOP;
  RETURN new_date;
END;
$$;


ALTER FUNCTION "public"."add_business_days"("start_date" "date", "number_of_days" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_group_members"("p_channel_id" bigint, "p_new_member_ids" "uuid"[]) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  is_admin boolean;
  member_id uuid;
  current_user_name text;
  added_names text;
BEGIN
  current_user_id := auth.uid();
  
  SELECT current_user_id = ANY(admin_ids) INTO is_admin FROM public.channels WHERE id = p_channel_id;
  IF NOT is_admin THEN RAISE EXCEPTION 'Acesso negado.'; END IF;

  FOREACH member_id IN ARRAY p_new_member_ids LOOP
      INSERT INTO public.channel_members (channel_id, profile_id) VALUES (p_channel_id, member_id) ON CONFLICT DO NOTHING;
  END LOOP;
  
  -- Busca os nomes para criar a mensagem dinâmica
  SELECT full_name INTO current_user_name FROM public.profiles WHERE id = current_user_id;
  SELECT string_agg(full_name, ', ') INTO added_names FROM public.profiles WHERE id = ANY(p_new_member_ids);

  INSERT INTO public.messages (channel_id, profile_id, content, message_type)
  VALUES (p_channel_id, current_user_id, COALESCE(current_user_name, 'Alguém') || ' adicionou ' || COALESCE(added_names, 'novos membros') || ' ao grupo.', 'system');
END;
$$;


ALTER FUNCTION "public"."add_group_members"("p_channel_id" bigint, "p_new_member_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."adiantar_item_producao"("p_item_id" "uuid", "p_admin_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_order_id uuid;
  uncompleted_items_count int;
BEGIN
  -- 1. Atualiza o status do item específico para 'completed'
  UPDATE public.order_items
  SET status = 'completed'
  WHERE id = p_item_id
  RETURNING order_id INTO v_order_id;

  -- 2. Insere um log para registrar a ação de adiantamento do item
  INSERT INTO public.order_logs (order_id, profile_id, log_type, description, metadata)
  VALUES (v_order_id, p_admin_id, 'STATUS_CHANGE', 'Item adiantado para entrega pelo administrador.', jsonb_build_object('item_id', p_item_id));

  -- 3. Verifica se AINDA EXISTEM outros itens do mesmo pedido que NÃO estão 'completed'
  SELECT count(*)
  INTO uncompleted_items_count
  FROM public.order_items
  WHERE order_id = v_order_id AND status <> 'completed';

  -- 4. Se a contagem de itens não finalizados for ZERO, então o pedido "pai" pode ser finalizado
  IF uncompleted_items_count = 0 THEN
    UPDATE public.orders
    SET status = 'completed'
    WHERE id = v_order_id;

    -- Log opcional para o pedido pai
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (v_order_id, p_admin_id, 'STATUS_CHANGE', 'Todos os itens foram concluídos. Pedido movido para a fila de entrega.');
  END IF;
END;
$$;


ALTER FUNCTION "public"."adiantar_item_producao"("p_item_id" "uuid", "p_admin_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."adiantar_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  admin_name TEXT;
BEGIN
  -- 1. Obter o nome do administrador para o log
  SELECT full_name INTO admin_name FROM public.profiles WHERE id = p_admin_id;

  -- 2. Atualizar o status do pedido para 'completed'
  -- Isso fará com que ele apareça na tela de agendamento de entrega
  UPDATE public.orders
  SET status = 'completed'
  WHERE id = p_order_id;

  -- 3. Inserir um log no histórico do pedido registrando a ação
  INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
  VALUES (p_order_id, p_admin_id, 'STATUS_CHANGE', 'Pedido adiantado para entrega pelo administrador: ' || COALESCE(admin_name, 'ID ' || p_admin_id::text));

END;
$$;


ALTER FUNCTION "public"."adiantar_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_manage_security"("p_user_id" "uuid", "p_action" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF p_action = 'reset' THEN
        -- 1. Zera o perfil
        UPDATE security_profiles
        SET risk_score = 0,
           risk_flag = 'none',
           access_status = 'active',
           blocked_until = NULL,
           risk_reason = 'Perdoado pelo Administrador'
        WHERE user_id = p_user_id;

        -- 2. Limpa o histórico de infrações para o motor não re-avaliar o passado e bloquear de novo
        DELETE FROM security_events_log
        WHERE user_id = p_user_id;

    ELSIF p_action = 'block' THEN
        -- 1. Bloqueio absoluto
        UPDATE security_profiles
        SET risk_score = 100,
           risk_flag = 'high',
           access_status = 'blocked',
           blocked_until = NOW() + INTERVAL '24 hours',
           risk_reason = 'Bloqueio Manual via Painel'
        WHERE user_id = p_user_id;

        -- 2. Morte imediata da Chave VIP
        UPDATE public_leads
        SET temp_auth_code = NULL,
            temp_auth_expires_at = NULL
        WHERE id = p_user_id;
    END IF;
END;
$$;


ALTER FUNCTION "public"."admin_manage_security"("p_user_id" "uuid", "p_action" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."approve_order_and_schedule"("p_order_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    order_fabric_type text;
    order_quantity numeric;
    current_stock numeric;
    final_status text;
    fabric_limit integer;
BEGIN
    SELECT o.details ->> 'fabric_type', o.quantity_meters, s.available_meters
    INTO order_fabric_type, order_quantity, current_stock
    FROM public.orders o
    LEFT JOIN public.stock s ON s.fabric_type = (o.details ->> 'fabric_type')
    WHERE o.id = p_order_id;

    IF current_stock < 0 THEN
        final_status := 'pending_stock';
        UPDATE public.orders SET status = final_status WHERE id = p_order_id;
    ELSE
        fabric_limit := CASE
            WHEN order_fabric_type = 'Fluity' THEN 3000
            WHEN order_fabric_type = 'Tule' THEN 3000
            WHEN order_fabric_type = 'Crepinho' THEN 2000
            WHEN order_fabric_type = 'Creponado' THEN 2000
            ELSE 10000 -- Limite padrão para outros tecidos
        END;
        
        -- Tenta agendar, mas se o próximo dia disponível estourar o limite, o status será 'scheduling_pending'
        SELECT public.schedule_order_with_limits(p_order_id, order_fabric_type, order_quantity, fabric_limit) INTO final_status;
    END IF;

    RETURN final_status;
END;
$$;


ALTER FUNCTION "public"."approve_order_and_schedule"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."are_all_items_in_stock"("p_order_payload" "jsonb") RETURNS boolean
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    item RECORD;
    stock_level NUMERIC;
BEGIN
    -- Itera sobre cada item dentro do array 'order_items' do JSON
    FOR item IN SELECT * FROM jsonb_to_recordset(p_order_payload->'order_items') AS x(
        fabric_type TEXT,
        quantity NUMERIC
    )
    LOOP
        -- Para cada item, busca o estoque correspondente na tabela 'stock'
        SELECT available_meters INTO stock_level
        FROM public.stock
        WHERE fabric_type = item.fabric_type;

        -- Se o estoque não for encontrado ou se a quantidade pedida for maior que o estoque
        IF stock_level IS NULL OR item.quantity > stock_level THEN
            -- Retorna 'false' imediatamente, pois pelo menos um item não tem estoque
            RETURN FALSE;
        END IF;
    END LOOP;

    -- Se o loop terminar sem retornar 'false', significa que todos os itens têm estoque
    RETURN TRUE;
END;
$$;


ALTER FUNCTION "public"."are_all_items_in_stock"("p_order_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cajuia_get_account_config"("config_key" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    acc_id UUID;
BEGIN
    SELECT account_id INTO acc_id
    FROM public.cajuia_accounting_configs
    WHERE key = config_key;
    
    RETURN acc_id;
END;
$$;


ALTER FUNCTION "public"."cajuia_get_account_config"("config_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cajuia_get_period_balance"("p_start_date" "date", "p_end_date" "date") RETURNS TABLE("account_id" "uuid", "account_code" "text", "account_name" "text", "nature" "text", "parent_id" "uuid", "is_synthetic" boolean, "total_debit" numeric, "total_credit" numeric, "balance" numeric)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    WITH account_totals AS (
        -- Soma os lançamentos do período agrupados por conta
        SELECT 
            ji.account_id,
            SUM(ji.debit) as sum_debit,
            SUM(ji.credit) as sum_credit
        FROM public.cajuia_journal_items ji
        JOIN public.cajuia_journal_entries je ON ji.journal_entry_id = je.id
        WHERE je.transaction_date BETWEEN p_start_date AND p_end_date
        GROUP BY ji.account_id
    )
    SELECT 
        a.id,
        a.code,
        a.name,
        a.nature::text,
        a.parent_id,
        a.is_synthetic,
        COALESCE(t.sum_debit, 0) as total_debit,
        COALESCE(t.sum_credit, 0) as total_credit,
        -- Cálculo do Saldo baseado na natureza (Ativo/Despesa = Devedora, Passivo/Receita = Credora)
        CASE 
            WHEN a.nature IN ('ativo', 'despesa') THEN COALESCE(t.sum_debit, 0) - COALESCE(t.sum_credit, 0)
            ELSE COALESCE(t.sum_credit, 0) - COALESCE(t.sum_debit, 0)
        END as balance
    FROM public.cajuia_accounts a
    LEFT JOIN account_totals t ON a.id = t.account_id
    ORDER BY a.code;
END;
$$;


ALTER FUNCTION "public"."cajuia_get_period_balance"("p_start_date" "date", "p_end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cajuia_post_sale_to_ledger"("target_order_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_order RECORD;
    v_journal_id UUID;
    
    -- IDs das Contas (buscados dinamicamente)
    v_acc_revenue UUID;   -- Receita de Vendas
    v_acc_asset UUID;     -- Ativo (Caixa/Banco/Clientes a Receber)
    v_acc_discount UUID;  -- Despesa de Descontos
    v_acc_cogs UUID;      -- CMV (Custo da Mercadoria Vendida) - Opcional
    v_acc_inventory UUID; -- Estoque - Opcional
    
    -- Valores
    v_net_value NUMERIC;
    
BEGIN
    -- 1. Buscar dados do pedido
    SELECT * INTO v_order FROM public.cajuia_orders WHERE id = target_order_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido Cajuia % não encontrado', target_order_id;
    END IF;

    -- 2. Carregar Configurações Contábeis (O "De-Para" do usuário)
    v_acc_revenue   := cajuia_get_account_config('default_revenue_account');
    v_acc_asset     := cajuia_get_account_config('default_asset_account'); -- Ex: "Caixa" ou "Contas a Receber"
    v_acc_discount  := cajuia_get_account_config('default_discount_account');
    
    -- Validação: Se o usuário não configurou, não podemos adivinhar.
    IF v_acc_revenue IS NULL OR v_acc_asset IS NULL THEN
        RAISE EXCEPTION 'Configuração contábil incompleta. Configure as contas padrão para Venda e Ativo.';
    END IF;

    -- 3. Criar Cabeçalho no Livro Diário
    INSERT INTO public.cajuia_journal_entries (
        transaction_date,
        description,
        origin_type,
        origin_id,
        created_by
    ) VALUES (
        CURRENT_DATE,
        'Venda PDV #' || v_order.order_number || ' - ' || COALESCE(v_order.customer_name, 'Consumidor'),
        'pdv_sale',
        v_order.id,
        auth.uid()
    ) RETURNING id INTO v_journal_id;

    -- 4. Lançamentos (Partidas Dobradas)
    
    -- A) Lançar a Entrada no Ativo (Débito no Caixa/Banco)
    -- Lança o valor TOTAL pago (Bruto ou Líquido, dependendo da sua regra. Aqui usarei Total da Nota)
    INSERT INTO public.cajuia_journal_items (journal_entry_id, account_id, debit, credit, history)
    VALUES (v_journal_id, v_acc_asset, v_order.total_value, 0, 'Recebimento Venda #' || v_order.order_number);

    -- B) Lançar a Receita (Crédito na Receita)
    -- Se tiver desconto, a receita bruta é lançada, e o desconto entra como despesa (método bruto)
    -- OU lança-se apenas o líquido (método líquido). Vamos usar o método BRUTO que é mais correto contabilmente.
    
    -- Como sua tabela 'cajuia_orders' atual talvez não tenha campo 'discount_value' separado explícito no nível root, 
    -- vou assumir lançamento simples pelo Total. 
    -- *Nota: Se você adicionar coluna de desconto na cajuia_orders, descomente a lógica abaixo.*
    
    INSERT INTO public.cajuia_journal_items (journal_entry_id, account_id, debit, credit, history)
    VALUES (v_journal_id, v_acc_revenue, 0, v_order.total_value, 'Receita de Venda #' || v_order.order_number);

    -- Exemplo de lógica futura para Desconto (se existir a coluna v_order.discount_amount > 0):
    /*
    IF v_order.discount_amount > 0 THEN
       -- Ajusta a Receita para ser Valor + Desconto (Bruto)
       -- Debita a conta de Despesa de Desconto
       INSERT INTO public.cajuia_journal_items (journal_entry_id, account_id, debit, credit)
       VALUES (v_journal_id, v_acc_discount, v_order.discount_amount, 0);
    END IF;
    */

END;
$$;


ALTER FUNCTION "public"."cajuia_post_sale_to_ledger"("target_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_delivery_forecast"("p_op_date" "date") RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  completion_date date;
  forecast_date date;
  work_days_added integer := 0;
BEGIN
  -- ETAPA 1: Calcular a data de finalização da produção (3 dias úteis após a data de emissão)
  -- Dias úteis são de Segunda a Sábado.
  completion_date := p_op_date;
  WHILE work_days_added < 3 LOOP
    completion_date := completion_date + 1;
    -- DOW: 0=Domingo, 1=Segunda, ..., 6=Sábado. Ignoramos o Domingo.
    IF EXTRACT(DOW FROM completion_date) != 0 THEN
      work_days_added := work_days_added + 1;
    END IF;
  END LOOP;

  -- ETAPA 2: Encontrar o próximo dia de entrega válido (Terça, Quinta ou Sábado)
  -- Começa a procurar a partir da data em que a produção termina.
  forecast_date := completion_date;
  LOOP
    -- DOW: 2=Terça, 4=Quinta, 6=Sábado
    IF EXTRACT(DOW FROM forecast_date) IN (2, 4, 6) THEN
      -- Se a data de finalização já for um dia de entrega, ou se encontrámos a próxima data válida, retorna o resultado.
      RETURN forecast_date;
    END IF;
    -- Se não for um dia válido, avança para o dia seguinte e continua a procurar.
    forecast_date := forecast_date + 1;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."calculate_delivery_forecast"("p_op_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_finalize_order"("p_order_id" "uuid", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_all_items_approved boolean;
BEGIN
    -- Verifica se TODOS os itens do pedido estão em um estado "aprovado"
    SELECT bool_and(status IN ('approved_by_designer', 'approved_by_seller'))
    INTO v_all_items_approved
    FROM public.order_items
    WHERE order_id = p_order_id;

    -- Se todos os itens foram aprovados, chama o agendador automático
    IF v_all_items_approved THEN
        -- *** ESTA É A INTEGRAÇÃO CRUCIAL ***
        PERFORM public.schedule_order_automatically(p_order_id);

        -- Log
        INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
        VALUES (p_order_id, p_profile_id, 'STATUS_CHANGE', 'Todos os itens aprovados. Pedido enviado para a fila de produção e agendado automaticamente.');
    END IF;
END;
$$;


ALTER FUNCTION "public"."check_and_finalize_order"("p_order_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_and_release_scheduled_orders"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    scheduled_rec RECORD;
    item_rec RECORD;
    can_be_released BOOLEAN;
    edge_function_url TEXT := 'https://drprfuinwglmzquqtqzq.supabase.co/functions/v1/release-order-and-sync';
    secret_key TEXT;
BEGIN
    -- Só continua se o estoque AUMENTOU, para otimização.
    IF NEW.available_meters <= OLD.available_meters THEN
        RETURN NEW;
    END IF;

    -- Pega o segredo do Vault (agora com a permissão correta).
    SELECT decrypted_secret INTO secret_key FROM vault.decrypted_secrets WHERE name = 'INTERNAL_API_SECRET';
    IF secret_key IS NULL THEN
        RAISE WARNING 'Segredo INTERNAL_API_SECRET não encontrado no Vault. Liberação automática não pode prosseguir.';
        RETURN NEW;
    END IF;

    -- Itera sobre os pedidos aguardando estoque.
    FOR scheduled_rec IN
        SELECT id, original_order_payload FROM public.scheduled_orders WHERE status = 'awaiting_stock'
    LOOP
        can_be_released := TRUE;

        -- Checa cada item do pedido, respeitando a unidade de medida (kg vs m).
        FOR item_rec IN SELECT * FROM jsonb_to_recordset(scheduled_rec.original_order_payload->'order_items') AS x(fabric_type TEXT, quantity_unit NUMERIC, unit_of_measure TEXT)
        LOOP
            IF NOT EXISTS (
                SELECT 1 FROM public.stock s
                WHERE s.fabric_type = item_rec.fabric_type
                  AND s.unit_of_measure = item_rec.unit_of_measure
                  AND s.available_meters >= item_rec.quantity_unit
            ) THEN
                can_be_released := FALSE;
                EXIT; -- Se um único item não tiver estoque, o pedido inteiro continua bloqueado.
            END IF;
        END LOOP;

        -- Se TODOS os itens tiverem estoque...
        IF can_be_released THEN
            -- ...chama a Edge Function para fazer a liberação completa (MJProcess + GestãoClick).
            PERFORM net.http_post(
                url := edge_function_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'x-internal-secret', secret_key
                ),
                body := jsonb_build_object('scheduled_order_id', scheduled_rec.id),
                timeout_milliseconds := 15000 -- Aumentado para 15 segundos para dar tempo para a API do GestãoClick responder.
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_and_release_scheduled_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_channel_lock_before_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_is_locked BOOLEAN;
    v_user_role TEXT;
BEGIN
    SELECT is_locked INTO v_is_locked FROM public.channels WHERE id = NEW.channel_id;
    
    IF v_is_locked THEN
        SELECT role INTO v_user_role FROM public.profiles WHERE id = auth.uid();
        IF v_user_role NOT IN ('admin', 'super_admin') THEN
            RAISE EXCEPTION 'Este canal está bloqueado pela administração.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_channel_lock_before_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_parent_order_completion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id UUID;
    v_total_items INT;
    v_completed_items INT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        v_order_id := NEW.order_id;
    ELSE
        v_order_id := OLD.order_id;
    END IF;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'completed')
    INTO v_total_items, v_completed_items
    FROM public.order_items
    WHERE order_id = v_order_id;

    IF v_total_items > 0 AND v_total_items = v_completed_items THEN
        UPDATE public.orders
        SET status = 'completed'
        WHERE id = v_order_id;

        INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
        VALUES (v_order_id, NULL, 'STATUS_CHANGE', 'Todos os itens do lançamento foram concluídos na produção. Pronto para agendamento de entrega.');
        
        -- >>> INÍCIO DA CORREÇÃO: Notificar Vendedor <<<
        PERFORM public.notify_seller_about_order_completion(v_order_id);
        -- >>> FIM DA CORREÇÃO <<<

    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_parent_order_completion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_premium_context"("p_email" "text", "p_context" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_lead_id uuid;
  v_auth_context jsonb;
  v_real_ip text;
  v_final_context jsonb;
  v_score integer := 0;
BEGIN
  -- 1. Puxa o IP In-hackeável da conexão (Ignora AdBlock, ignora navegador)
  v_real_ip := split_part(current_setting('request.headers', true)::json->>'x-forwarded-for', ',', 1);
  IF v_real_ip IS NULL OR v_real_ip = '' THEN
    v_real_ip := 'IP_DESCONHECIDO';
  END IF;

  v_final_context := p_context || jsonb_build_object('ip', v_real_ip);

  SELECT id, authorized_context INTO v_lead_id, v_auth_context
  FROM public.public_leads
  WHERE email = p_email LIMIT 1;

  IF v_lead_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Lead não encontrado');
  END IF;

  -- Se não tem contexto salvo, deixa passar (será salvo na validação principal)
  IF v_auth_context IS NULL OR v_auth_context::text = '{}'::text THEN
    RETURN jsonb_build_object('status', 'ok');
  END IF;

  -- 2. POLÍCIA DO AUTO-LOGIN: Compara o contexto atual com a assinatura gravada
  IF (v_real_ip) != (v_auth_context->>'ip') THEN v_score := v_score + 30; END IF;
  IF (v_final_context->>'user_agent') != (v_auth_context->>'user_agent') THEN v_score := v_score + 25; END IF;
  IF (v_final_context->>'fingerprint') != (v_auth_context->>'fingerprint') THEN v_score := v_score + 40; END IF;

  -- 3. EXECUTA A QUEIMA E BLOQUEIO SE HOUVER DIVERGÊNCIA
  IF v_score >= 50 THEN
    UPDATE public.public_leads
    SET access_status = 'blocked', risk_flag = 'high', blocked_reason = 'Divergência Crítica durante Auto-Login', blocked_at = now(), temp_auth_code = null
    WHERE id = v_lead_id;

    INSERT INTO public.premium_access_events (lead_id, user_email, event_type, risk_score, metadata_json)
    VALUES (v_lead_id, p_email, 'suspicious_access_detected', v_score, v_final_context);

    RETURN jsonb_build_object('status', 'blocked', 'message', 'ACESSO BLOQUEADO: Mudança drástica de dispositivo detectada. Sua chave foi revogada.');

  ELSIF v_score >= 21 AND v_score < 50 THEN
    UPDATE public.public_leads
    SET access_status = 'revalidation_required', risk_flag = 'medium', temp_auth_code = null
    WHERE id = v_lead_id;

    INSERT INTO public.premium_access_events (lead_id, user_email, event_type, risk_score, metadata_json)
    VALUES (v_lead_id, p_email, 'revalidation_required', v_score, v_final_context);

    RETURN jsonb_build_object('status', 'revalidation_required', 'message', 'REVALIDAÇÃO: Mudança de rede detectada. Por segurança, sua chave foi cancelada. Solicite uma nova.');
  END IF;

  -- Se for a mesma pessoa no mesmo PC, só atualiza o IP e deixa entrar sem queimar a chave
  UPDATE public.public_leads SET last_ip = v_real_ip WHERE id = v_lead_id;
  RETURN jsonb_build_object('status', 'ok');
END;
$$;


ALTER FUNCTION "public"."check_premium_context"("p_email" "text", "p_context" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_stale_presences"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Atualiza para 'offline' todos os usuários cujo status não é 'offline'
  -- e cuja última aparição foi há mais de 2 minutos.
  -- O canal de presença do Supabase geralmente detecta uma desconexão em ~30-60 segundos.
  -- Usar 2 minutos nos dá uma margem de segurança.
  UPDATE public.user_presences
  SET status = 'offline'
  WHERE
    status <> 'offline' AND
    last_seen < NOW() - INTERVAL '2 minutes';
END;
$$;


ALTER FUNCTION "public"."cleanup_stale_presences"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."concluir_todos_itens_pedido"("p_order_id" "uuid", "p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Etapa 1: Atualiza o status de todos os itens do pedido para 'completed'
    UPDATE public.order_items
    SET status = 'completed'
    WHERE order_id = p_order_id;

    -- Etapa 2: Atualiza o status do pedido principal para 'completed'
    UPDATE public.orders
    SET status = 'completed'
    WHERE id = p_order_id;

    -- Etapa 3: Insere o registro de log com os nomes de coluna corretos
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_user_id, 'manual_completion', 'Todos os itens foram marcados como concluídos manualmente pelo usuário.');

END;
$$;


ALTER FUNCTION "public"."concluir_todos_itens_pedido"("p_order_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."confirmar_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_completion_date DATE;
    v_delivery_date DATE;
BEGIN
    -- Obter a data de conclusão da produção do pedido
    SELECT production_date INTO v_completion_date
    FROM public.orders
    WHERE id = p_order_id;

    -- Se não houver data de produção, assume-se a data de hoje como base
    IF v_completion_date IS NULL THEN
        v_completion_date := CURRENT_DATE;
    END IF;

    -- Calcular a data de entrega final (3 dias úteis após a produção)
    v_delivery_date := public.add_business_days(v_completion_date, 3);

    -- Atualiza o status do pedido para 'delivered'
    UPDATE public.orders
    SET status = 'delivered'
    WHERE id = p_order_id;

    -- Atualiza o registro de agendamento com a data de confirmação e a data de entrega efetiva
    UPDATE public.production_schedule
    SET
        delivery_confirmed_at = now(),
        actual_delivery_date = v_delivery_date
    WHERE order_id = p_order_id;

    -- Adiciona um log no histórico do pedido
    INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_profile_id, 'STATUS_CHANGE', 'Entrega confirmada e status alterado para Entregue.');

END;
$$;


ALTER FUNCTION "public"."confirmar_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_cajuia_order"("p_vendedor_id" "uuid", "p_customer_id" "text", "p_customer_name" "text", "p_total_value" numeric, "p_payment_method" "text", "p_gestaoclick_sale_id" "text", "p_order_items" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_new_order_id uuid;
    v_item jsonb;
    v_product_id uuid;
    v_quantity int;
    v_current_stock int;
BEGIN
    -- 1. Criar o pedido principal
    INSERT INTO public.cajuia_orders (
        vendedor_id, customer_id, customer_name, total_value, payment_method, gestaoclick_sale_id
    ) VALUES (
        p_vendedor_id, p_customer_id, p_customer_name, p_total_value, p_payment_method, p_gestaoclick_sale_id
    ) RETURNING id INTO v_new_order_id;

    -- 2. Iterar sobre os itens, salvar e abater o estoque
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_product_id := (v_item->>'product_id')::uuid;
        v_quantity := (v_item->>'quantity')::int;

        -- Inserir o item no pedido
        INSERT INTO public.cajuia_order_items (
            order_id, product_id, product_name, quantity, unit_price, total_price
        ) VALUES (
            v_new_order_id,
            v_product_id,
            v_item->>'product_name',
            v_quantity,
            (v_item->>'unit_price')::numeric,
            (v_item->>'total_price')::numeric
        );

        -- Abater o estoque (com verificação)
        SELECT quantity_in_stock INTO v_current_stock
        FROM public.cajuia_products
        WHERE id = v_product_id;

        IF v_current_stock < v_quantity THEN
            RAISE EXCEPTION 'Estoque insuficiente para o produto: %', v_item->>'product_name';
        END IF;

        UPDATE public.cajuia_products
        SET quantity_in_stock = quantity_in_stock - v_quantity
        WHERE id = v_product_id;
    END LOOP;

    -- 3. Retornar o ID do pedido criado
    RETURN v_new_order_id;
END;
$$;


ALTER FUNCTION "public"."create_cajuia_order"("p_vendedor_id" "uuid", "p_customer_id" "text", "p_customer_name" "text", "p_total_value" numeric, "p_payment_method" "text", "p_gestaoclick_sale_id" "text", "p_order_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_channel_with_participants"("p_name" "text", "p_created_by" "uuid", "p_is_private_dm" boolean, "p_participant_ids" "uuid"[]) RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_channel_id BIGINT;
    new_channel_record RECORD;
BEGIN
    -- 1. Cria o novo canal
    INSERT INTO public.channels (name, created_by, is_private_dm)
    VALUES (p_name, p_created_by, p_is_private_dm)
    RETURNING id INTO new_channel_id;

    -- 2. Insere todos os participantes na tabela de junção
    INSERT INTO public.channel_participants (channel_id, user_id)
    SELECT new_channel_id, unnest(p_participant_ids);

    -- 3. Retorna os detalhes do canal recém-criado
    SELECT * INTO new_channel_record FROM public.channels WHERE id = new_channel_id;

    RETURN row_to_json(new_channel_record);
END;
$$;


ALTER FUNCTION "public"."create_channel_with_participants"("p_name" "text", "p_created_by" "uuid", "p_is_private_dm" boolean, "p_participant_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_design_items_from_pending_order"("p_order_payload" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    -- Declara uma variável para armazenar o ID do pedido principal (que ainda não foi criado)
    -- Isso é um placeholder, pois os itens de design são criados "órfãos" inicialmente.
    -- Vamos usar um UUID nulo temporariamente.
    temp_order_id UUID := '00000000-0000-0000-0000-000000000000';
    item RECORD;
BEGIN
    FOR item IN SELECT * FROM jsonb_to_recordset(p_order_payload->'order_items') AS x(
        fabric_type TEXT,
        stamp_ref TEXT,
        quantity_meters NUMERIC,
        stamp_image_url TEXT,
        design_tag TEXT,
        notes TEXT,
        status TEXT,
        total_value_items NUMERIC
    )
    LOOP
        -- Se o item for de Desenvolvimento ou Alteração, insere ele na tabela de itens
        IF item.design_tag IN ('Desenvolvimento', 'Alteração') THEN
            INSERT INTO public.order_items (
                order_id,
                fabric_type,
                stamp_ref,
                quantity_meters,
                stamp_image_url,
                design_tag,
                notes,
                status,
                total_value_items,
                -- Marca o item como aguardando estoque para diferenciá-lo no Kanban
                has_insufficient_stock
            )
            VALUES (
                temp_order_id, -- Usamos o ID temporário
                item.fabric_type,
                item.stamp_ref,
                item.quantity_meters,
                item.stamp_image_url,
                item.design_tag,
                item.notes,
                'design_pending_stock', -- Um status novo e específico
                item.total_value_items,
                TRUE -- Flag indicando que depende de estoque
            );
        END IF;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."create_design_items_from_pending_order"("p_order_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_design_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_design_items" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_group_id UUID;
    item JSONB;
    new_order_id UUID;
    item_notes TEXT;
BEGIN
    -- Criar um grupo para o pedido se houver mais de um item
    IF jsonb_array_length(p_design_items) > 1 THEN
        INSERT INTO public.order_groups DEFAULT VALUES RETURNING id INTO new_group_id;
    END IF;

    -- Iterar sobre cada item do pedido de design
    FOR item IN SELECT * FROM jsonb_array_elements(p_design_items)
    LOOP
        item_notes := COALESCE(item->>'item_notes', '') || ' | OBS GERAL: ' || p_general_notes;

        INSERT INTO public.orders (customer_name, created_by, store_id, quantity_meters, status, design_tag, group_id, details)
        VALUES (
            p_customer_name,
            p_created_by,
            p_store_id,
            (item->>'quantity_meters')::NUMERIC,
            'design_pending',
            item->>'design_tag',
            new_group_id,
            jsonb_build_object(
                'fabric_type', item->>'fabric_type',
                'stamp_details', item_notes
            )
        ) RETURNING id INTO new_order_id;

        -- Registrar no log
        INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
        VALUES (new_order_id, p_created_by, 'ORDER_CREATED', 'Pedido criado para a fila de design com a tag: ' || (item->>'design_tag'));

        -- Atualizar estoque
        UPDATE public.stock
        SET available_meters = available_meters - (item->>'quantity_meters')::NUMERIC
        WHERE fabric_type = item->>'fabric_type';
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."create_design_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_design_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  new_request_id uuid;
  next_dev_code_int integer;
  formatted_dev_code text;
  designer_profile record;
BEGIN
  -- 1. Obter o próximo código sequencial para o desenvolvimento
  SELECT nextval('design_requests_dev_code_seq') INTO next_dev_code_int;
  formatted_dev_code := 'DEV-' || lpad(next_dev_code_int::text, 4, '0');

  -- 2. Inserir a solicitação principal na tabela
  INSERT INTO design_requests (general_notes, store_id, design_items, created_by, dev_code)
  VALUES (p_general_notes, p_store_id, p_design_items, p_created_by, formatted_dev_code)
  RETURNING id INTO new_request_id;

  -- 3. Buscar todos os designers e criar uma notificação para cada um
  FOR designer_profile IN
    SELECT id FROM profiles WHERE role = 'designer'
  LOOP
    INSERT INTO notifications (recipient_id, sender_id, content, redirect_url)
    VALUES (
      designer_profile.id,                         -- O ID do designer que receberá
      p_created_by,                                -- O ID de quem criou a solicitação
      'Nova solicitação (' || formatted_dev_code || ') para design.', -- O conteúdo da notificação
      '/design/kanban'                             -- URL para onde o designer será levado
    );
  END LOOP;

  -- 4. Retornar o código gerado para o frontend
  RETURN formatted_dev_code;
END;
$$;


ALTER FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid", "p_request_type" "text" DEFAULT 'development'::"text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_dev_code text;
BEGIN
  -- Gera um código único baseado no timestamp (Ex: DEV-1709...)
  v_dev_code := 'DEV-' || floor(extract(epoch from now()));

  INSERT INTO public.design_requests (
    dev_code,
    general_notes,
    store_id,
    design_items,
    created_by,
    status,
    request_type -- Nova coluna
  ) VALUES (
    v_dev_code,
    p_general_notes,
    p_store_id,
    p_design_items,
    p_created_by,
    'design_pending', -- Sempre inicia como pendente
    p_request_type
  );

  RETURN v_dev_code;
END;
$$;


ALTER FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid", "p_request_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[]) RETURNS TABLE("channel_id" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_channel_id BIGINT;
    member_id UUID;
BEGIN
    -- Adiciona a coluna is_group se ela não existir
    ALTER TABLE public.channels ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE;

    -- Cria o novo canal
    INSERT INTO public.channels (name, is_group, created_by)
    VALUES (channel_name, TRUE, auth.uid())
    RETURNING id INTO new_channel_id;

    -- Adiciona o usuário atual como membro
    INSERT INTO public.channel_members (channel_id, profile_id)
    VALUES (new_channel_id, auth.uid());

    -- Adiciona os outros membros
    FOREACH member_id IN ARRAY member_ids
    LOOP
        INSERT INTO public.channel_members (channel_id, profile_id)
        VALUES (new_channel_id, member_id);
    END LOOP;

    RETURN QUERY SELECT new_channel_id;
END;
$$;


ALTER FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[], "p_admin_ids" "uuid"[] DEFAULT '{}'::"uuid"[], "p_moderator_ids" "uuid"[] DEFAULT '{}'::"uuid"[]) RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_channel_id bigint;
  current_user_id uuid;
  final_admin_ids uuid[];
  member_id uuid;
  all_members uuid[];
BEGIN
  -- Pega o ID do usuário que está criando o grupo
  current_user_id := auth.uid();
  
  -- LÓGICA DE SEGURANÇA: Garante que o criador do grupo SEMPRE faça parte dos admins
  IF current_user_id = ANY(p_admin_ids) THEN
      final_admin_ids := p_admin_ids;
  ELSE
      final_admin_ids := array_append(p_admin_ids, current_user_id);
  END IF;

  -- 1. INSERE O CANAL NA TABELA CHANNELS
  INSERT INTO public.channels (
    name, 
    created_by, 
    type, 
    is_group, 
    is_private_dm,
    admin_ids,
    moderator_ids
  )
  VALUES (
    channel_name, 
    current_user_id, 
    'group', 
    true, 
    false,
    final_admin_ids,
    p_moderator_ids
  ) RETURNING id INTO new_channel_id;

  -- 2. GARANTE QUE O CRIADOR ESTÁ NA LISTA GERAL DE MEMBROS
  all_members := member_ids;
  IF NOT current_user_id = ANY(all_members) THEN
      all_members := array_append(all_members, current_user_id);
  END IF;

  -- 3. INSERE TODOS OS PARTICIPANTES NA TABELA CHANNEL_MEMBERS
  FOREACH member_id IN ARRAY all_members
  LOOP
      INSERT INTO public.channel_members (channel_id, profile_id)
      VALUES (new_channel_id, member_id)
      ON CONFLICT DO NOTHING; -- Previne erros caso o ID esteja duplicado no array
  END LOOP;

  -- 4. INSERE UMA MENSAGEM DE SISTEMA PARA INICIAR O CHAT (Opcional, mas recomendado)
  INSERT INTO public.messages (channel_id, profile_id, content, message_type)
  VALUES (new_channel_id, current_user_id, 'Grupo criado', 'system');

  RETURN new_channel_id;
END;
$$;


ALTER FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[], "p_admin_ids" "uuid"[], "p_moderator_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_launch_order"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb"[]) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_order_id uuid;
    new_order_number integer;
    item_data jsonb;
    v_fabric_type text;
    v_quantity_to_debit numeric;
    total_quantity_meters numeric := 0; 
BEGIN
    -- Lógica original mantida...
    FOREACH item_data IN ARRAY p_order_items
    LOOP
        total_quantity_meters := total_quantity_meters + (item_data->>'quantity_meters')::numeric;
    END LOOP;

    INSERT INTO public.orders (
        customer_name, created_by, store_id, has_down_payment,
        down_payment_proof_url, status, order_number, quantity_meters
    )
    VALUES (
        p_customer_name, p_created_by, p_store_id, p_has_down_payment,
        p_down_payment_proof_url, 'design_pending', get_next_order_number(), total_quantity_meters
    )
    RETURNING id, order_number INTO new_order_id, new_order_number;

    -- Itera sobre os itens
    FOREACH item_data IN ARRAY p_order_items
    LOOP
        v_fabric_type := item_data->>'fabric_type';

        IF (item_data->>'unit_of_measure') = 'kg' THEN
            v_quantity_to_debit := (item_data->>'quantity_unit')::numeric;
        ELSE
            v_quantity_to_debit := (item_data->>'quantity_meters')::numeric;
        END IF;

        -- ====================================================================
        --                            INÍCIO DA CORREÇÃO
        -- ====================================================================
        INSERT INTO public.order_items (
            order_id, fabric_type, stamp_ref, quantity_meters, stamp_image_url,
            design_tag, notes, quantity_unit, unit_of_measure, rendimento, status,
            total_value_items -- <<-- CAMPO ADICIONADO
        ) VALUES (
            new_order_id, v_fabric_type, item_data->>'stamp_ref', (item_data->>'quantity_meters')::numeric,
            item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
            (item_data->>'quantity_unit')::numeric, item_data->>'unit_of_measure',
            (item_data->>'rendimento')::numeric, item_data->>'status',
            (item_data->>'total_value_items')::numeric -- <<-- VALOR ADICIONADO
        );
        -- ====================================================================
        --                             FIM DA CORREÇÃO
        -- ====================================================================

        UPDATE public.stock
        SET available_meters = available_meters - v_quantity_to_debit
        WHERE fabric_type = v_fabric_type;
    END LOOP;

    RETURN new_order_number;
END;
$$;


ALTER FUNCTION "public"."create_launch_order"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_launch_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    new_order_id uuid;
    item_data jsonb;
    v_fabric_type text;
    v_quantity_to_debit numeric;
    total_quantity_meters numeric := 0;
BEGIN
    -- 1. Calcula a metragem total a partir do JSON.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        total_quantity_meters := total_quantity_meters + (item_data->>'quantity_meters')::numeric;
    END LOOP;

    -- 2. Insere o pedido usando o NÚMERO RECEBIDO (p_order_number)
    INSERT INTO public.orders (
        order_number, -- <-- USA O PARÂMETRO
        customer_name,
        created_by,
        store_id,
        has_down_payment,
        down_payment_proof_url,
        status,
        total_value,
        quantity_meters
    )
    VALUES (
        p_order_number, -- <-- USA O PARÂMETRO
        p_customer_name,
        p_created_by,
        p_store_id,
        p_has_down_payment,
        p_down_payment_proof_url,
        'design_pending',
        p_total_value,
        total_quantity_meters
    )
    RETURNING id INTO new_order_id; -- Captura o ID do novo pedido

    -- 3. Itera e insere os itens, debitando o estoque.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_fabric_type := item_data->>'fabric_type';

        -- Lógica para debitar estoque (KG vs Metro)
        IF (item_data->>'unit_of_measure') = 'kg' THEN
            v_quantity_to_debit := (item_data->>'quantity_unit')::numeric;
        ELSE
            v_quantity_to_debit := (item_data->>'quantity_meters')::numeric;
        END IF;

        -- Insere o item do pedido.
        INSERT INTO public.order_items (
            order_id, fabric_type, stamp_ref, quantity_meters, stamp_image_url,
            design_tag, notes, quantity_unit, unit_of_measure, rendimento, status, total_value_items
        ) VALUES (
            new_order_id, v_fabric_type, item_data->>'stamp_ref', (item_data->>'quantity_meters')::numeric,
            item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
            (item_data->>'quantity_unit')::numeric, item_data->>'unit_of_measure',
            (item_data->>'rendimento')::numeric, item_data->>'status', (item_data->>'total_value_items')::numeric
        );

        -- Debita o estoque.
        UPDATE public.stock
        SET available_meters = available_meters - v_quantity_to_debit
        WHERE fabric_type = v_fabric_type;

    END LOOP;

    -- 4. Retorna o ID do pedido criado, como o frontend espera.
    RETURN new_order_id;
END;
$$;


ALTER FUNCTION "public"."create_launch_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_order_and_update_stock"("p_customer_name" "text", "p_quantity_meters" numeric, "p_details" "jsonb", "p_store_id" "uuid", "p_created_by" "uuid", "p_value" numeric, "p_has_down_payment" boolean, "p_down_payment_proof_url" "text") RETURNS TABLE("result_order_id" "uuid")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_fabric_type TEXT;
    new_order_id UUID;
BEGIN
    -- 1. Insere o novo pedido com o status inicial 'design_pending'
    INSERT INTO public.orders (
        customer_name, quantity_meters, details, store_id, created_by,
        value, has_down_payment, down_payment_proof_url, status
    )
    VALUES (
        p_customer_name, p_quantity_meters, p_details, p_store_id, p_created_by,
        p_value, p_has_down_payment, p_down_payment_proof_url, 'design_pending'
    )
    RETURNING id INTO new_order_id;

    -- 2. Debita o estoque, permitindo que o valor fique negativo
    v_fabric_type := p_details ->> 'fabric_type';
    UPDATE public.stock
    SET available_meters = available_meters - p_quantity_meters
    WHERE fabric_type = v_fabric_type;

    -- 3. Adiciona um log claro da criação e do débito inicial
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (new_order_id, p_created_by, 'ORDER_CREATED', 'Pedido criado e ' || p_quantity_meters || 'm de ' || v_fabric_type || ' debitado(s) do estoque.');

    -- 4. Retorna o ID do pedido criado
    RETURN QUERY SELECT new_order_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;


ALTER FUNCTION "public"."create_order_and_update_stock"("p_customer_name" "text", "p_quantity_meters" numeric, "p_details" "jsonb", "p_store_id" "uuid", "p_created_by" "uuid", "p_value" numeric, "p_has_down_payment" boolean, "p_down_payment_proof_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    item_data jsonb;
    v_fabric_type text;
    v_quantity_meters numeric;
    current_stock_level numeric;
    has_insufficient_stock boolean := false;
    insufficient_fabrics text[] := ARRAY[]::text[];
    new_order_id uuid;
    new_order_number integer;
    total_quantity_meters numeric := 0;
BEGIN
    -- 1. Verificar estoque para todos os itens PRIMEIRO
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_fabric_type := item_data->>'fabric_type';
        v_quantity_meters := (item_data->>'quantity_meters')::numeric;
        total_quantity_meters := total_quantity_meters + v_quantity_meters;

        SELECT available_meters INTO current_stock_level
        FROM public.stock
        WHERE fabric_type = v_fabric_type;

        IF current_stock_level IS NULL OR current_stock_level < v_quantity_meters THEN
            has_insufficient_stock := true;
            insufficient_fabrics := array_append(insufficient_fabrics, v_fabric_type);
        END IF;
    END LOOP;

    -- 2. Se NÃO houver estoque suficiente para QUALQUER item...
    IF has_insufficient_stock THEN
        -- ...insere na tabela de agendados e NÃO mexe no estoque nem no GestãoClick.
        INSERT INTO public.scheduled_orders (created_by, original_order_payload)
        VALUES (
            p_created_by,
            jsonb_build_object(
                'customer_name', p_customer_name,
                'store_id', p_store_id,
                'has_down_payment', p_has_down_payment,
                'down_payment_proof_url', p_down_payment_proof_url,
                'order_items', p_order_items,
                'total_value', p_total_value,
                'insufficient_fabrics', insufficient_fabrics
            )
        );
        -- Retorna um status indicando que foi agendado
        RETURN jsonb_build_object('status', 'scheduled', 'message', 'Pedido agendado por falta de estoque.');

    -- 3. Se TIVER estoque para TUDO...
    ELSE
        -- ...executa a lógica original de criação de pedido.
        SELECT nextval('orders_order_number_seq') INTO new_order_number;

        INSERT INTO public.orders (
            order_number, customer_name, created_by, store_id, has_down_payment,
            down_payment_proof_url, status, total_value, quantity_meters, is_launch
        ) VALUES (
            new_order_number, p_customer_name, p_created_by, p_store_id, p_has_down_payment,
            p_down_payment_proof_url, 'design_pending', p_total_value, total_quantity_meters, true
        ) RETURNING id INTO new_order_id;

        FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
        LOOP
            INSERT INTO public.order_items (
                order_id, fabric_type, stamp_ref, quantity_meters, stamp_image_url,
                design_tag, notes, unit_of_measure, rendimento, status, total_value_items
            ) VALUES (
                new_order_id, item_data->>'fabric_type', item_data->>'stamp_ref', (item_data->>'quantity_meters')::numeric,
                item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
                item_data->>'unit_of_measure', (item_data->>'rendimento')::numeric, 'design_pending', (item_data->>'total_value_items')::numeric
            );

            -- Debita o estoque
            UPDATE public.stock
            SET available_meters = available_meters - (item_data->>'quantity_meters')::numeric
            WHERE fabric_type = item_data->>'fabric_type';
        END LOOP;

        -- **AQUI você colocaria a chamada para o GestãoClick no futuro, quando mover a lógica**
        
        RETURN jsonb_build_object('status', 'created', 'order_number', new_order_number);
    END IF;
END;
$$;


ALTER FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric, "p_customer_id" integer, "p_observation" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    item_data jsonb;
    v_fabric_type text;
    v_quantity numeric;
    v_unit text;
    has_insufficient_stock boolean := false;
    insufficient_fabrics text[] := ARRAY[]::text[];
    new_order_id uuid;
    new_order_number integer;
    total_quantity_meters numeric := 0;
BEGIN
    -- 1. Verifica o estoque para cada item
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_fabric_type := item_data->>'fabric_type';
        v_quantity := (item_data->>'quantity_unit')::numeric;
        v_unit := item_data->>'unit_of_measure';
        total_quantity_meters := total_quantity_meters + (item_data->>'quantity_meters')::numeric;

        IF NOT EXISTS (
            SELECT 1 FROM public.stock s
            WHERE s.fabric_type = v_fabric_type AND s.unit_of_measure = v_unit AND s.available_meters >= v_quantity
        ) THEN
            has_insufficient_stock := true;
            insufficient_fabrics := array_append(insufficient_fabrics, v_fabric_type);
        END IF;
    END LOOP;

    -- 2. Se o estoque for insuficiente, agenda o pedido
    IF has_insufficient_stock THEN
        INSERT INTO public.scheduled_orders (created_by, original_order_payload)
        VALUES (
            p_created_by,
            jsonb_build_object(
                'customer_id', p_customer_id,
                'customer_name', p_customer_name,
                'store_id', p_store_id,
                'has_down_payment', p_has_down_payment,
                'down_payment_proof_url', p_down_payment_proof_url,
                'order_items', p_order_items,
                'total_value', p_total_value,
                'observation', p_observation,
                'insufficient_fabrics', insufficient_fabrics
            )
        );
        RETURN jsonb_build_object('status', 'scheduled', 'message', 'Pedido agendado por falta de estoque.');
    
    -- 3. Se o estoque estiver OK, cria o pedido normalmente
    ELSE
        SELECT nextval('orders_order_number_seq') INTO new_order_number;

        INSERT INTO public.orders (
            order_number, customer_name, created_by, store_id, has_down_payment, customer_id,
            down_payment_proof_url, status, total_value, quantity_meters, is_launch
        ) VALUES (
            new_order_number, p_customer_name, p_created_by, p_store_id, p_has_down_payment, p_customer_id,
            p_down_payment_proof_url, 'design_pending', p_total_value, total_quantity_meters, true
        ) RETURNING id INTO new_order_id;

        FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
        LOOP
            INSERT INTO public.order_items (
                order_id, fabric_type, stamp_ref, stamp_ref_id, quantity_meters, stamp_image_url,
                design_tag, notes, unit_of_measure, rendimento, status, total_value_items, quantity_unit, gestao_click_product_id
            ) VALUES (
                new_order_id, item_data->>'fabric_type', item_data->>'stamp_ref', item_data->>'stamp_ref_id', (item_data->>'quantity_meters')::numeric,
                item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
                item_data->>'unit_of_measure', (item_data->>'rendimento')::numeric, 'design_pending', (item_data->>'total_value_items')::numeric, (item_data->>'quantity_unit')::numeric,
                item_data->>'gestao_click_product_id'
            );

            UPDATE public.stock
            SET available_meters = available_meters - (item_data->>'quantity_unit')::numeric
            WHERE fabric_type = item_data->>'fabric_type' AND unit_of_measure = item_data->>'unit_of_measure';
        END LOOP;
        
        RETURN jsonb_build_object('status', 'created', 'order_number', new_order_number);
    END IF;
END;
$$;


ALTER FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric, "p_customer_id" integer, "p_observation" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_production_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_fabric_type" "text", "p_quantity_meters" numeric) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    new_order_id UUID;
BEGIN
    -- Inserir o pedido principal
    INSERT INTO public.orders (customer_name, created_by, store_id, quantity_meters, status, details)
    VALUES (
        p_customer_name,
        p_created_by,
        p_store_id,
        p_quantity_meters,
        'production_queue',
        jsonb_build_object(
            'fabric_type', p_fabric_type,
            'stamp_details', p_general_notes
        )
    ) RETURNING id INTO new_order_id;

    -- Registrar no log
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (new_order_id, p_created_by, 'ORDER_CREATED', 'Pedido criado e enviado direto para a produção.');

    -- Atualizar estoque
    UPDATE public.stock
    SET available_meters = available_meters - p_quantity_meters
    WHERE fabric_type = p_fabric_type;
END;
$$;


ALTER FUNCTION "public"."create_production_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_fabric_type" "text", "p_quantity_meters" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_ready_delivery_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    new_order_id uuid;
    item_data jsonb;
    v_fabric_type text;
    v_quantity_to_debit numeric;
    total_quantity_meters numeric := 0;
BEGIN
    -- 1. Calcula a metragem total a partir do JSON.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        total_quantity_meters := total_quantity_meters + (item_data->>'quantity_meters')::numeric;
    END LOOP;

    -- 2. Insere o pedido com o status 'ready_for_delivery'
    INSERT INTO public.orders (
        order_number,
        customer_name,
        created_by,
        store_id,
        has_down_payment,
        down_payment_proof_url,
        status, -- <-- STATUS FIXO PARA PRONTA ENTREGA
        total_value,
        quantity_meters
    )
    VALUES (
        p_order_number,
        p_customer_name,
        p_created_by,
        p_store_id,
        p_has_down_payment,
        p_down_payment_proof_url,
        'ready_for_delivery', -- <-- VALOR FIXO
        p_total_value,
        total_quantity_meters
    )
    RETURNING id INTO new_order_id;

    -- 3. Itera e insere os itens, debitando o estoque.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_order_items)
    LOOP
        v_fabric_type := item_data->>'fabric_type';

        IF (item_data->>'unit_of_measure') = 'kg' THEN
            v_quantity_to_debit := (item_data->>'quantity_unit')::numeric;
        ELSE
            v_quantity_to_debit := (item_data->>'quantity_meters')::numeric;
        END IF;

        INSERT INTO public.order_items (
            order_id, fabric_type, stamp_ref, quantity_meters, stamp_image_url,
            design_tag, notes, quantity_unit, unit_of_measure, rendimento, status, total_value_items
        ) VALUES (
            new_order_id, v_fabric_type, item_data->>'stamp_ref', (item_data->>'quantity_meters')::numeric,
            item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
            (item_data->>'quantity_unit')::numeric, item_data->>'unit_of_measure',
            (item_data->>'rendimento')::numeric, item_data->>'status', (item_data->>'total_value_items')::numeric
        );

        UPDATE public.stock
        SET available_meters = available_meters - v_quantity_to_debit
        WHERE fabric_type = v_fabric_type;

    END LOOP;

    -- 4. Retorna o ID do pedido criado.
    RETURN new_order_id;
END;
$$;


ALTER FUNCTION "public"."create_ready_delivery_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_user_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  -- Insere uma nova linha na tabela public.profiles, usando o id e o email do novo usuário.
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;


ALTER FUNCTION "public"."create_user_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."designer_complete_development"("p_request_id" "uuid", "p_final_art_url" "text", "p_new_stamp_name" "text", "p_designer_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  new_stamp_bigint_id bigint; -- CORRIGIDO: A variável agora é do tipo bigint.
  request_info record;
BEGIN
  -- Obtém o ID do vendedor que solicitou o desenvolvimento.
  SELECT created_by INTO request_info FROM design_requests WHERE id = p_request_id;

  -- 1. Insere a nova estampa na biblioteca e captura o ID (bigint) gerado.
  INSERT INTO stamp_library (name, image_url, created_by, is_approved)
  VALUES (p_new_stamp_name, p_final_art_url, p_designer_id, false)
  RETURNING id INTO new_stamp_bigint_id;

  -- 2. Atualiza a solicitação de desenvolvimento com a arte final e o ID da nova estampa.
  UPDATE design_requests
  SET
    status = 'pending_approval',
    final_art_url = p_final_art_url,
    new_stamp_id = new_stamp_bigint_id
  WHERE id = p_request_id;

  -- 3. Notifica o vendedor original.
  IF request_info.created_by IS NOT NULL THEN
    INSERT INTO notifications (recipient_id, sender_id, content, redirect_url)
    VALUES (
      request_info.created_by,
      p_designer_id,
      'O desenvolvimento "' || p_new_stamp_name || '" está pronto para sua avaliação.',
      '/approvals'
    );
  END IF;
END;
$$;


ALTER FUNCTION "public"."designer_complete_development"("p_request_id" "uuid", "p_final_art_url" "text", "p_new_stamp_name" "text", "p_designer_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dismiss_all_notifications"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Insere um registro de dispensa para todas as notificações destinadas ao usuário atual
  -- que ainda não foram dispensadas por ele.
  INSERT INTO public.user_notification_dismissals (user_id, notification_id)
  SELECT auth.uid(), n.id
  FROM public.notifications n
  WHERE
    (n.recipient_id = auth.uid() OR n.recipient_id IS NULL)
    AND NOT EXISTS (
      SELECT 1
      FROM public.user_notification_dismissals und
      WHERE und.notification_id = n.id AND und.user_id = auth.uid()
    );
END;
$$;


ALTER FUNCTION "public"."dismiss_all_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."execute_sql"("query_text" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result_json jsonb;
BEGIN
  -- VERIFICAÇÃO DE SEGURANÇA:
  -- Garante que a query comece com SELECT (ignorando espaços e maiúsculas/minúsculas)
  -- E proíbe 'INTO' para evitar 'SELECT ... INTO new_table'
  IF NOT (query_text ~* '^\s*SELECT') OR (query_text ~* '\sINTO\s') THEN
    RAISE EXCEPTION 'Query inválida. Apenas consultas SELECT são permitidas.';
  END IF;

  -- Executa a query e agrega os resultados em um único JSON array
  EXECUTE 'SELECT jsonb_agg(t) FROM (' || query_text || ') t'
  INTO result_json;

  -- Retorna o JSON. Se a query não retornar linhas, jsonb_agg retorna NULL.
  RETURN COALESCE(result_json, '[]'::jsonb);

EXCEPTION
  -- Em caso de erro (ex: sintaxe SQL errada), retorna um objeto de erro JSON
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'error', SQLERRM,
      'sql_state', SQLSTATE
    );
END;
$$;


ALTER FUNCTION "public"."execute_sql"("query_text" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."extract_required_stock"("p_order_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  SELECT jsonb_agg(
    jsonb_build_object(
      'fabric_type', item->>'fabric_type',
      'required_quantity', (item->>'quantity')::numeric
    )
  )
  FROM jsonb_array_elements(p_order_payload->'order_items') AS item;
$$;


ALTER FUNCTION "public"."extract_required_stock"("p_order_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."faturar_pedido"("p_order_id" "uuid", "p_chart_of_accounts_id" "uuid", "p_bank_account_id" "uuid", "p_payment_method_id" "uuid", "p_due_date" "date", "p_competence_date" "date") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_order record;
  v_customer_id uuid;
  v_receivable_id uuid;
BEGIN
  -- 1. Buscar o pedido e travar a linha para evitar faturamento duplo
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE; -- Trava a linha

  -- 2. Verificar se o pedido existe
  IF v_order IS NULL THEN
    RAISE EXCEPTION 'Pedido não encontrado.';
  END IF;

  -- 3. Verificar se já foi faturado
  IF v_order.is_invoiced = true THEN
    RAISE EXCEPTION 'Este pedido já foi faturado em %', v_order.invoiced_at;
  END IF;

  -- 4. Buscar o ID do cliente (Sua tabela 'orders' parece ter só 'customer_name')
  --    (Você já tem a tabela 'customers' no seu schema)
  SELECT id INTO v_customer_id
  FROM public.customers
  WHERE name = v_order.customer_name
  LIMIT 1;

  -- 5. Criar a Conta a Receber
  INSERT INTO public.finance_receivables
    (description, value, due_date, competence_date, order_id, customer_id, 
     chart_of_accounts_id, bank_account_id, payment_method_id, created_by, store_id, employee_id)
  VALUES
    ('Referente ao Pedido #' || v_order.order_number, 
     v_order.total_value, 
     p_due_date, 
     p_competence_date, 
     v_order.id, 
     v_customer_id,
     p_chart_of_accounts_id,
     p_bank_account_id,
     p_payment_method_id,
     v_order.created_by,
     v_order.store_id,
     v_order.created_by -- Assumindo que o 'employee_id' é o criador do pedido
    )
  RETURNING id INTO v_receivable_id;

  -- 6. Atualizar o pedido como faturado
  UPDATE public.orders
  SET 
    is_invoiced = true,
    invoiced_at = now()
    -- (Opcional) status = 'faturado'
  WHERE id = p_order_id;

  -- 7. Retornar sucesso
  RETURN json_build_object(
    'success', true, 
    'message', 'Pedido faturado com sucesso.', 
    'receivable_id', v_receivable_id
  );
EXCEPTION
  WHEN others THEN
    RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."faturar_pedido"("p_order_id" "uuid", "p_chart_of_accounts_id" "uuid", "p_bank_account_id" "uuid", "p_payment_method_id" "uuid", "p_due_date" "date", "p_competence_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."faturar_recebivel"("p_receivable_id" "uuid") RETURNS json
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_receivable record;
BEGIN
  -- 1. Verifica se quem está chamando é Admin
  IF (get_my_role() <> 'admin'::text) THEN
    RAISE EXCEPTION 'Apenas administradores podem faturar.';
  END IF;

  -- 2. Busca o recebível
  SELECT * INTO v_receivable
  FROM public.finance_receivables
  WHERE id = p_receivable_id;

  -- 3. Verifica se pode faturar
  IF v_receivable.status <> 'Provisionado' THEN
    RAISE EXCEPTION 'Apenas recebíveis "Provisionados" podem ser faturados. Status atual: %', v_receivable.status;
  END IF;

  -- 4. ATUALIZA O STATUS para "Em Aberto"
  UPDATE public.finance_receivables
  SET status = 'em_aberto'
  WHERE id = p_receivable_id;

  RETURN json_build_object('success', true, 'message', 'Recebível faturado com sucesso.');
EXCEPTION
  WHEN others THEN
    RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."faturar_recebivel"("p_receivable_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status" "text" DEFAULT 'design_pending'::"text" NOT NULL,
    "customer_name" "text",
    "details" "jsonb",
    "quantity_meters" numeric NOT NULL,
    "store_id" "uuid",
    "designer_id" "uuid",
    "production_date" "date",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "value" numeric DEFAULT 0,
    "group_id" "uuid",
    "design_tag" "text",
    "has_down_payment" boolean DEFAULT false,
    "down_payment_proof_url" "text",
    "is_launch" boolean DEFAULT false,
    "order_number" integer NOT NULL,
    "sales_order_pdf_url" "text",
    "billed_at" timestamp with time zone,
    "actual_delivery_date" "date",
    "delivery_confirmed_at" timestamp with time zone,
    "forecast_delivery_date" "date",
    "total_value" numeric(10,2) DEFAULT 0 NOT NULL,
    "receipt_pdf_url" "text",
    "is_invoiced" boolean DEFAULT false,
    "invoiced_at" timestamp with time zone,
    "cash_session_id" "uuid",
    "financial_status" "text" DEFAULT 'Em Aberto'::"text",
    "customer_id" "uuid",
    "notes" "text",
    "invoiced_by" "uuid",
    "billing_alert" boolean DEFAULT false,
    "billing_queue_visible" boolean DEFAULT false NOT NULL,
    "nfe_number" "text",
    "nfe_key" "text",
    "fiscal_type" "text"
);


ALTER TABLE "public"."orders" OWNER TO "postgres";


COMMENT ON COLUMN "public"."orders"."is_launch" IS 'Se TRUE, este pedido é um "lançamento pai" e seus detalhes estão na tabela order_items.';



COMMENT ON COLUMN "public"."orders"."billed_at" IS 'Timestamp de quando o pedido foi faturado e liberado para agendamento de entrega.';



COMMENT ON COLUMN "public"."orders"."actual_delivery_date" IS 'Data agendada para a entrega do pedido.';



COMMENT ON COLUMN "public"."orders"."delivery_confirmed_at" IS 'Timestamp de quando a entrega foi confirmada.';



COMMENT ON COLUMN "public"."orders"."fiscal_type" IS 'Tipo da nota emitida: NFe ou NFCe';



CREATE OR REPLACE FUNCTION "public"."fetch_approval_group"("p_group_key" "text") RETURNS SETOF "public"."orders"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.orders
    WHERE (orders.group_id::text = p_group_key OR orders.id::text = p_group_key)
      AND orders.status = 'customer_approval';
END;
$$;


ALTER FUNCTION "public"."fetch_approval_group"("p_group_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_or_create_dm_channel"("p_user1_id" "uuid", "p_user2_id" "uuid") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_channel_id BIGINT;
    v_participants UUID[];
BEGIN
    -- Garante uma ordem consistente para os participantes para evitar DMs duplicadas
    IF p_user1_id < p_user2_id THEN
        v_participants := ARRAY[p_user1_id, p_user2_id];
    ELSE
        v_participants := ARRAY[p_user2_id, p_user1_id];
    END IF;

    -- Tenta encontrar um canal de DM existente entre os dois usuários
    SELECT id INTO v_channel_id
    FROM public.channels
    WHERE is_private_dm = TRUE
      AND dm_participant_ids @> v_participants
      AND dm_participant_ids <@ v_participants;

    -- Se o canal não for encontrado, cria um novo
    IF v_channel_id IS NULL THEN
        INSERT INTO public.channels (name, description, created_by, type, is_private_dm, dm_participant_ids)
        VALUES (
            'DM',
            'Conversa privada',
            p_user1_id,
            'dm',
            TRUE,
            v_participants
        ) RETURNING id INTO v_channel_id;

        -- Adiciona ambos os usuários como membros do novo canal
        INSERT INTO public.channel_members (channel_id, profile_id)
        VALUES (v_channel_id, p_user1_id), (v_channel_id, p_user2_id);
    END IF;

    RETURN v_channel_id;
END;
$$;


ALTER FUNCTION "public"."find_or_create_dm_channel"("p_user1_id" "uuid", "p_user2_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."forcar_conclusao_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Atualiza todos os itens do pedido para 'completed'
    UPDATE public.order_items
    SET status = 'completed'
    WHERE order_id = p_order_id;

    -- Atualiza o status geral do pedido para 'completed'
    UPDATE public.orders
    SET status = 'completed'
    WHERE id = p_order_id;

    -- Adiciona um registro no log
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_admin_id, 'STATUS_CHANGE', 'Produção forçada para "Concluído" pelo administrador.');
END;
$$;


ALTER FUNCTION "public"."forcar_conclusao_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."func_set_purchase_codigo"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Só puxa o número se vier vazio
  IF NEW.codigo IS NULL THEN
    IF NEW.purchase_type = 'product' THEN
      NEW.codigo := nextval('purchases_product_seq');
    ELSIF NEW.purchase_type = 'service' THEN
      NEW.codigo := nextval('purchases_service_seq');
    ELSE
      NEW.codigo := nextval('purchases_product_seq');
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."func_set_purchase_codigo"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_op_number"("p_item_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_op_number int;
BEGIN
    -- Verifica se o item já tem um número de OP
    SELECT op_number INTO v_op_number
    FROM public.order_items
    WHERE id = p_item_id;

    -- Se já tiver um número, apenas o retorna
    IF v_op_number IS NOT NULL THEN
        RETURN v_op_number;
    END IF;

    -- Se não tiver, encontra o maior número existente, soma 1 e o atribui ao item
    LOOP
        v_op_number := (SELECT COALESCE(MAX(op_number), 0) + 1 FROM public.order_items);
        
        UPDATE public.order_items
        SET op_number = v_op_number
        WHERE id = p_item_id AND op_number IS NULL;

        -- Se a atualização foi bem-sucedida (nenhuma outra transação pegou o número antes), sai do loop
        IF FOUND THEN
            RETURN v_op_number;
        END IF;
        
        -- Se não, o loop tenta novamente com o próximo número disponível
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."generate_op_number"("p_item_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_premium_access_code"("p_email" "text", "p_admin_id" "uuid" DEFAULT NULL::"uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_lead_id uuid;
  v_raw_code text;
BEGIN
  -- Usamos atribuição direta (:=) em vez de SELECT INTO para não confundir o parser do SQL Editor
  v_lead_id := (SELECT id FROM public.public_leads WHERE email = p_email LIMIT 1);
  
  IF v_lead_id IS NULL THEN
    RAISE EXCEPTION 'Lead não encontrado.';
  END IF;

  -- Gerar código criptográfico forte de 8 caracteres (Ex: A9K2M8XZ)
  v_raw_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));

  -- Atualizar o Lead
  UPDATE public.public_leads
  SET 
    temp_auth_code = v_raw_code,
    temp_auth_expires_at = now() + interval '24 hours',
    access_status = 'pending_validation',
    auth_code_requested = false
  WHERE id = v_lead_id;

  -- Trilha de Auditoria
  INSERT INTO public.premium_access_events (lead_id, user_email, event_type, reason)
  VALUES (v_lead_id, p_email, 'temp_code_generated', CASE WHEN p_admin_id IS NOT NULL THEN 'Manual by Admin' ELSE 'Auto Request' END);

  RETURN v_raw_code;
END;
$$;


ALTER FUNCTION "public"."generate_premium_access_code"("p_email" "text", "p_admin_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_all_channel_members"("p_channel_id" bigint) RETURNS TABLE("profile_id" "uuid", "full_name" "text", "avatar_url" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY 
    SELECT cm.profile_id, p.full_name, p.avatar_url
    FROM public.channel_members cm 
    JOIN public.profiles p ON cm.profile_id = p.id
    WHERE cm.channel_id = p_channel_id;
END;
$$;


ALTER FUNCTION "public"."get_all_channel_members"("p_channel_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_all_sellers_performance"("start_date" "date", "end_date" "date") RETURNS TABLE("seller_id" "uuid", "full_name" "text", "avatar_url" "text", "total_sold" numeric, "orders_count" bigint, "avg_ticket" numeric, "goal_value" numeric, "goal_progress" numeric)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as seller_id,
        p.full_name,
        p.avatar_url,
        COALESCE(SUM(o.total_value), 0) as total_sold,
        COUNT(DISTINCT o.id) as orders_count,
        CASE WHEN COUNT(DISTINCT o.id) > 0 THEN COALESCE(SUM(o.total_value), 0) / COUNT(DISTINCT o.id) ELSE 0 END as avg_ticket,
        COALESCE(sg.goal_value, 0) as goal_value,
        CASE WHEN COALESCE(sg.goal_value, 0) > 0 THEN (COALESCE(SUM(o.total_value), 0) / sg.goal_value) * 100 ELSE 0 END as goal_progress
    FROM
        public.profiles p
    LEFT JOIN
        public.orders o ON p.id = o.created_by AND o.created_at BETWEEN start_date AND end_date
    LEFT JOIN
        public.sales_goals sg ON p.id = sg.seller_id AND sg.year = EXTRACT(YEAR FROM start_date) AND sg.month = EXTRACT(MONTH FROM start_date)
    WHERE
        p.role = 'vendedor'
    GROUP BY
        p.id, sg.goal_value
    ORDER BY
        total_sold DESC;
END;
$$;


ALTER FUNCTION "public"."get_all_sellers_performance"("start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_all_users_with_status"("p_exclude_user_id" "uuid") RETURNS TABLE("id" "uuid", "full_name" "text", "avatar_url" "text", "role" "text", "status" "text", "last_seen" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.avatar_url,
    p.role::TEXT, -- <<-- CORREÇÃO APLICADA AQUI
    COALESCE(up.status, 'offline') AS status,
    up.last_seen
  FROM
    public.profiles p
  LEFT JOIN
    public.user_presences up ON p.id = up.user_id
  WHERE
    p.id <> p_exclude_user_id
  ORDER BY
    CASE
      WHEN up.status = 'online' THEN 1
      WHEN up.status = 'away' THEN 2
      ELSE 3
    END,
    p.full_name;
END;
$$;


ALTER FUNCTION "public"."get_all_users_with_status"("p_exclude_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_and_increment_order_number"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_order_number INT;
BEGIN
  UPDATE public.app_config
  SET value = jsonb_set(
    value,
    '{last_order_number}',
    to_jsonb((value->>'last_order_number')::INT + 1)
  )
  WHERE key = 'order_counter'
  RETURNING (value->>'last_order_number')::INT INTO new_order_number;
  
  RETURN new_order_number;
END;
$$;


ALTER FUNCTION "public"."get_and_increment_order_number"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_app_usage_ranking"("p_user_id" "uuid", "p_date" "date") RETURNS TABLE("application_name" "text", "total_seconds" numeric, "classification" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  -- [IMPORTANTE!] Altere este valor para corresponder ao intervalo (em segundos)
  -- em que a atividade do usuário é registrada.
  activity_interval_seconds int := 10; 
  start_time timestamptz;
  end_time timestamptz;
BEGIN
  -- Define o intervalo de data e hora para o dia inteiro (baseado no timezone da sessão)
  start_time := p_date::timestamptz;
  end_time := start_time + interval '1 day';

  RETURN QUERY
  WITH ranked_apps AS (
    SELECT
      ua.application_name,
      -- Calcula o tempo total multiplicando o número de logs pelo intervalo
      (COUNT(*) * activity_interval_seconds) AS calculated_total_seconds,
      -- Encontra a classificação mais frequente (moda) para este app
      mode() WITHIN GROUP (ORDER BY ua.classification) AS most_common_classification
    FROM
      public.user_activity AS ua
    WHERE
      ua.user_id = p_user_id
      AND ua.created_at >= start_time
      AND ua.created_at < end_time
      AND ua.application_name IS NOT NULL
    GROUP BY
      ua.application_name
  )
  SELECT
    ra.application_name,
    ra.calculated_total_seconds::numeric,
    ra.most_common_classification
  FROM
    ranked_apps AS ra
  ORDER BY
    ra.calculated_total_seconds DESC
  LIMIT 5;

END;
$$;


ALTER FUNCTION "public"."get_app_usage_ranking"("p_user_id" "uuid", "p_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_comprehensive_report_data"("start_date" "text" DEFAULT NULL::"text", "end_date" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result jsonb;
    start_timestamp timestamptz;
    end_timestamp timestamptz;
BEGIN
    -- Converte as datas de texto para timestamp
    start_timestamp := to_timestamp(start_date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    end_timestamp := to_timestamp(end_date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');

    -- Unifica todos os itens de pedidos no período
    WITH all_items_in_range AS (
        SELECT
            oi.id,
            o.id AS order_id,
            o.order_number,
            o.customer_name,
            p_creator.full_name AS creator_name,
            p_creator.id as creator_id,
            o.designer_id as designer_id,
            oi.fabric_type,
            oi.stamp_ref,
            oi.quantity_meters,
            oi.status,
            o.created_at,
            oi.created_at as item_created_at,
            ps.scheduled_date,
            (SELECT log.created_at FROM public.order_logs log WHERE log.order_id = o.id AND log.description ILIKE '%' || oi.stamp_ref || '%' AND log.description ILIKE '%aprovada%' ORDER BY log.created_at DESC LIMIT 1) as approval_date
        FROM public.order_items oi
        JOIN public.orders o ON oi.order_id = o.id
        LEFT JOIN public.profiles p_creator ON o.created_by = p_creator.id
        LEFT JOIN public.production_schedule ps ON ps.order_item_id = oi.id
        WHERE (start_timestamp IS NULL OR o.created_at >= start_timestamp)
          AND (end_timestamp IS NULL OR o.created_at <= end_timestamp)
    )
    SELECT jsonb_build_object(
        'kpis', (
            SELECT jsonb_build_object(
                'total_meters', SUM(quantity_meters),
                'total_items', COUNT(id),
                'active_sellers', COUNT(DISTINCT creator_id)
            ) FROM all_items_in_range
        ),
        'sales_by_seller', (
            SELECT jsonb_agg(s) FROM (
                SELECT 
                    creator_name as seller, 
                    COUNT(id) as items_count,
                    SUM(quantity_meters) as total_meters
                FROM all_items_in_range
                WHERE creator_name IS NOT NULL
                GROUP BY creator_name
                ORDER BY items_count DESC
            ) s
        ),
        'meters_by_fabric', (
            SELECT jsonb_agg(f) FROM (
                SELECT fabric_type as fabric, SUM(quantity_meters) as meters
                FROM all_items_in_range
                WHERE fabric_type IS NOT NULL
                GROUP BY fabric_type
                ORDER BY meters DESC
                LIMIT 5
            ) f
        ),
        'design_performance', (
             SELECT jsonb_agg(d) FROM (
                SELECT 
                    p_designer.full_name as designer, 
                    COUNT(i.id) as items_completed,
                    AVG(EXTRACT(EPOCH FROM (i.approval_date - i.item_created_at)) / 3600) as avg_hours_to_approval
                FROM all_items_in_range i
                JOIN public.profiles p_designer ON i.designer_id = p_designer.id
                WHERE i.designer_id IS NOT NULL AND i.status NOT IN ('design_pending', 'changes_requested')
                GROUP BY p_designer.full_name
            ) d
        ),
        'production_by_machine', (
             SELECT jsonb_agg(m) FROM (
                SELECT 
                    CASE 
                        WHEN fabric_type IN ('Creponado', 'Tule', 'Fluity', 'Canelado', 'Suplex', 'Chiffon', 'Liganet') THEN 'MESA'
                        ELSE 'CORRIDA'
                    END as machine,
                    SUM(quantity_meters) as meters
                FROM all_items_in_range
                WHERE status IN ('in_printing', 'in_cutting', 'completed')
                GROUP BY machine
            ) m
        ),
        'all_items_table', (SELECT jsonb_agg(t) FROM (
            SELECT id, order_number, customer_name, creator_name, fabric_type, stamp_ref, quantity_meters, created_at, status
            FROM all_items_in_range
            ORDER BY created_at DESC
        ) t)
    ) INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_comprehensive_report_data"("start_date" "text", "end_date" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_crm_overview_data"("start_date" "date", "end_date" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    -- Declaração de todas as variáveis que vamos usar
    kpis JSONB;
    sales_trend JSONB;
    top_fabrics JSONB;
    top_sellers JSONB;
    top_customers JSONB;
BEGIN
    -- 1. Cálculo dos KPIs Principais
    SELECT jsonb_build_object(
        'total_revenue', COALESCE(SUM(o.total_value), 0),
        'total_orders', COUNT(o.id),
        'new_customers', (SELECT COUNT(DISTINCT customer_name) FROM public.orders WHERE created_at BETWEEN start_date AND end_date AND customer_name NOT IN (SELECT DISTINCT customer_name FROM public.orders WHERE created_at < start_date)),
        'avg_ticket', CASE WHEN COUNT(o.id) > 0 THEN COALESCE(SUM(o.total_value), 0) / COUNT(o.id) ELSE 0 END
    )
    INTO kpis
    FROM public.orders o
    WHERE o.created_at BETWEEN start_date AND end_date;

    -- 2. Dados para o Gráfico de Tendência de Vendas (agrupado por dia)
    SELECT jsonb_agg(data)
    INTO sales_trend
    FROM (
        SELECT DATE_TRUNC('day', o.created_at)::DATE as day, SUM(o.total_value) as total_revenue
        FROM public.orders o
        WHERE o.created_at BETWEEN start_date AND end_date
        GROUP BY day
        ORDER BY day
    ) as data;

    -- 3. Dados para o Gráfico de Bases (Tecidos) Mais Pedidas
    SELECT jsonb_agg(data)
    INTO top_fabrics
    FROM (
        WITH all_items AS (
            SELECT (details->>'fabric_type')::TEXT as fabric, quantity_meters FROM public.orders WHERE is_launch = false AND created_at BETWEEN start_date AND end_date
            UNION ALL
            SELECT fabric_type as fabric, quantity_meters FROM public.order_items oi JOIN public.orders o ON oi.order_id = o.id WHERE o.created_at BETWEEN start_date AND end_date
        )
        SELECT fabric, SUM(quantity_meters) as total_meters
        FROM all_items
        WHERE fabric IS NOT NULL
        GROUP BY fabric
        ORDER BY total_meters DESC
        LIMIT 6
    ) as data;

    -- 4. Ranking de Top Vendedores
    SELECT jsonb_agg(data)
    INTO top_sellers
    FROM (
        SELECT p.full_name as seller_name, p.avatar_url, SUM(o.total_value) as total_sold
        FROM public.orders o
        JOIN public.profiles p ON o.created_by = p.id
        WHERE o.created_at BETWEEN start_date AND end_date
        GROUP BY p.id, p.full_name, p.avatar_url
        ORDER BY total_sold DESC
        LIMIT 5
    ) as data;

    -- 5. Ranking de Top Clientes
    SELECT jsonb_agg(data)
    INTO top_customers
    FROM (
        SELECT customer_name, SUM(total_value) as total_purchased, COUNT(id) as total_orders
        FROM public.orders
        WHERE created_at BETWEEN start_date AND end_date
        GROUP BY customer_name
        ORDER BY total_purchased DESC
        LIMIT 5
    ) as data;

    -- Monta o JSON final com todos os resultados
    RETURN jsonb_build_object(
        'kpis', kpis,
        'sales_trend', sales_trend,
        'top_fabrics', top_fabrics,
        'top_sellers', top_sellers,
        'top_customers', top_customers
    );
END;
$$;


ALTER FUNCTION "public"."get_crm_overview_data"("start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_delivery_forecast_date"("p_order_items" "jsonb") RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    latest_production_date date;
    completion_date date;
    delivery_date date;
BEGIN
    -- 1. Encontra a data de início da produção mais tardia entre todos os itens,
    --    considerando a capacidade diária da fábrica.
    SELECT MAX(p_date)
    INTO latest_production_date
    FROM (
        SELECT schedule_production_for_item(
            item_data->>'fabric_type',
            (item_data->>'quantity_meters')::numeric
        ) as p_date
        FROM jsonb_array_elements(p_order_items) AS item_data
    ) AS production_dates;

    IF latest_production_date IS NULL THEN
        latest_production_date := current_date;
    END IF;

    -- 2. CORREÇÃO APLICADA AQUI: Adiciona 2 dias úteis à data de início.
    --    (Dia 1 é a própria data de início, então +2 dias resulta em um total de 3 dias de produção)
    completion_date := public.add_business_days(latest_production_date, 2);

    -- 3. Encontra o próximo dia de entrega válido (Ter, Qui ou Sáb) a partir da data de conclusão.
    delivery_date := public.get_next_delivery_day(completion_date);

    RETURN delivery_date;
END;
$$;


ALTER FUNCTION "public"."get_delivery_forecast_date"("p_order_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_design_kanban_items"() RETURNS TABLE("item_id" "uuid", "order_id" "uuid", "order_number" integer, "customer_name" "text", "creator_name" "text", "fabric_type" "text", "stamp_ref" "text", "status" "text", "notes" "text", "stamp_image_url" "text", "created_at" timestamp with time zone, "is_pending_stock" boolean)
    LANGUAGE "sql" STABLE
    AS $$
    -- Parte 1: Itens de pedidos reais que estão no design
    SELECT
        oi.id AS item_id,
        o.id AS order_id,
        o.order_number,
        o.customer_name,
        p.full_name AS creator_name,
        oi.fabric_type,
        oi.stamp_ref,
        oi.status,
        oi.notes,
        oi.stamp_image_url,
        oi.created_at,
        false AS is_pending_stock
    FROM
        public.orders o
    JOIN
        public.order_items oi ON o.id = oi.order_id
    JOIN
        public.profiles p ON o.created_by = p.id
    WHERE
        oi.status IN ('design_pending', 'customer_approval', 'changes_requested', 'finalizing')

    UNION ALL

    -- Parte 2: Itens da nova fila de design (pedidos pendentes)
    SELECT
        dq.id AS item_id,
        NULL AS order_id, -- Não tem ID de pedido ainda
        NULL AS order_number, -- Não tem número de pedido ainda
        dq.customer_name,
        p.full_name AS creator_name,
        dq.fabric_type,
        dq.stamp_ref,
        dq.status,
        dq.notes,
        dq.stamp_image_url,
        dq.created_at,
        true AS is_pending_stock
    FROM
        public.design_queue dq
    JOIN
        public.profiles p ON dq.created_by = p.id;
$$;


ALTER FUNCTION "public"."get_design_kanban_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_detailed_report_data"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    result jsonb;
BEGIN
    -- CTE to unify all items, whether from single orders or launch orders
    WITH all_order_items AS (
        -- Items from LAUNCH orders
        SELECT
            oi.id,
            o.id AS order_id,
            o.order_number,
            o.customer_name,
            p.full_name AS creator_name,
            p.id as creator_id,
            oi.fabric_type,
            oi.stamp_ref,
            oi.quantity_meters,
            oi.status,
            o.created_at,
            o.is_launch,
            (SELECT price_se_cash FROM price_list pl WHERE pl.name = oi.fabric_type LIMIT 1) as price -- Simplified price logic
        FROM
            public.order_items oi
        JOIN
            public.orders o ON oi.order_id = o.id
        JOIN
            public.profiles p ON o.created_by = p.id
        WHERE
            o.is_launch = true

        UNION ALL

        -- Items from LEGACY (single) orders
        SELECT
            o.id, -- Use order id as item id for legacy
            o.id AS order_id,
            o.order_number,
            o.customer_name,
            p.full_name AS creator_name,
            p.id as creator_id,
            (o.details->>'fabric_type')::text as fabric_type,
            (o.details->>'stamp_details')::text as stamp_ref,
            o.quantity_meters,
            o.status,
            o.created_at,
            o.is_launch,
            (SELECT price_se_cash FROM price_list pl WHERE pl.name = (o.details->>'fabric_type')::text LIMIT 1) as price
        FROM
            public.orders o
        JOIN
            public.profiles p ON o.created_by = p.id
        WHERE
            o.is_launch = false
    )
    SELECT jsonb_build_object(
        'all_items', (SELECT jsonb_agg(items) FROM all_order_items items)
    ) INTO result;

    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_detailed_report_data"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_full_order_details_for_sync"("p_order_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    order_details JSONB;
BEGIN
    SELECT jsonb_build_object(
        'order', row_to_json(o),
        'creator', row_to_json(p),
        'items', (SELECT jsonb_agg(row_to_json(oi)) FROM public.order_items oi WHERE oi.order_id = o.id)
    )
    INTO order_details
    FROM public.orders o
    JOIN public.profiles p ON o.created_by = p.id
    WHERE o.id = p_order_id;

    RETURN order_details;
END;
$$;


ALTER FUNCTION "public"."get_full_order_details_for_sync"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_full_production_schedule"() RETURNS TABLE("order_id" "uuid", "customer_name" "text", "quantity_meters" numeric, "status" "text", "is_launch" boolean, "production_date" "date", "is_ghost" boolean, "created_by_name" "text", "order_items" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id as order_id,
        o.customer_name,
        o.quantity_meters,
        o.status,
        o.is_launch,
        -- Se já tiver uma data de produção, use-a. Senão, estime 3 dias úteis a partir de hoje como previsão.
        COALESCE(o.production_date, public.add_business_days(CURRENT_DATE, 3)) as production_date,
        -- É um fantasma se o status NÃO for 'completed'
        (o.status <> 'completed') as is_ghost,
        p.full_name as created_by_name,
        -- Agrega os itens do pedido em um array JSON
        (SELECT jsonb_agg(oi.*) FROM public.order_items oi WHERE oi.order_id = o.id) as order_items
    FROM
        public.orders o
    JOIN
        public.profiles p ON o.created_by = p.id
    WHERE
        o.status IN ('design_pending', 'in_design', 'customer_approval', 'production_queue', 'in_printing', 'in_cutting', 'completed');
END;
$$;


ALTER FUNCTION "public"."get_full_production_schedule"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_inactive_customers"("inactive_since_days" integer) RETURNS TABLE("customer_name" "text", "last_order_date" "date", "days_since_last_order" integer, "last_seller_name" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    WITH last_orders AS (
        SELECT
            o.customer_name,
            MAX(o.created_at)::DATE as last_order,
            (
                SELECT p.full_name
                FROM public.orders o2
                JOIN public.profiles p ON o2.created_by = p.id
                WHERE o2.customer_name = o.customer_name
                ORDER BY o2.created_at DESC
                LIMIT 1
            ) as last_seller
        FROM public.orders o
        GROUP BY o.customer_name
    )
    SELECT
        lo.customer_name,
        lo.last_order,
        (CURRENT_DATE - lo.last_order) as days_inactive,
        lo.last_seller
    FROM last_orders lo
    WHERE (CURRENT_DATE - lo.last_order) > inactive_since_days
    ORDER BY days_inactive DESC;
END;
$$;


ALTER FUNCTION "public"."get_inactive_customers"("inactive_since_days" integer) OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fabric_type" "text" NOT NULL,
    "available_meters" numeric DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "meters_per_roll" numeric,
    "unit_of_measure" "text",
    "base_price" numeric,
    "rendimento" numeric(10,2),
    "gestao_click_id" "text",
    "low_stock_threshold" numeric,
    "last_alerted_at" timestamp with time zone,
    "verification" boolean DEFAULT false,
    "is_ready_delivery" boolean DEFAULT false,
    "ncm" "text" DEFAULT '54075100'::"text",
    "include_in_kpi" boolean DEFAULT true,
    "barcode" "text",
    "cfop" "text" DEFAULT '5102'::"text",
    "tab_id" "uuid",
    "visible_in_sales" boolean DEFAULT true,
    "alert_enabled" boolean DEFAULT true,
    "target_tab" character varying(50) DEFAULT 'production'::character varying
);


ALTER TABLE "public"."stock" OWNER TO "postgres";


COMMENT ON COLUMN "public"."stock"."rendimento" IS 'Quantos metros o tecido rende por quilo (m/kg).';



COMMENT ON COLUMN "public"."stock"."low_stock_threshold" IS 'Limite mínimo em que um alerta de estoque baixo deve ser disparado.';



COMMENT ON COLUMN "public"."stock"."last_alerted_at" IS 'Timestamp de quando o último alerta para este item foi enviado.';



CREATE OR REPLACE FUNCTION "public"."get_low_stock_items"() RETURNS SETOF "public"."stock"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT * FROM public.stock 
  WHERE available_meters <= low_stock_threshold 
  AND alert_enabled = true;
$$;


ALTER FUNCTION "public"."get_low_stock_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_machine_type_for_fabric"("fabric_type_arg" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Converte o nome do tecido para minúsculas e remove espaços extras
    fabric_type_arg := trim(lower(fabric_type_arg));
    
    IF fabric_type_arg IN (
        'tecido creponado', 'malha tulle', 'malha fluity', 'malha canelada', 
        'malha suplex', 'tecido chiffon', 'malha liganet'
    ) THEN
        RETURN 'MESA';
    ELSE
        RETURN 'CORRIDA';
    END IF;
END;
$$;


ALTER FUNCTION "public"."get_machine_type_for_fabric"("fabric_type_arg" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_cajuia_role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
    SELECT role FROM public.cajuia_permissions WHERE user_id = auth.uid()
$$;


ALTER FUNCTION "public"."get_my_cajuia_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_channels"() RETURNS TABLE("id" bigint, "created_at" timestamp with time zone, "name" "text", "description" "text", "created_by" "uuid", "icon" "text", "color" "text", "icon_image_url" "text", "is_private_dm" boolean, "other_participant" json, "is_locked" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.created_at, c.name, c.description, c.created_by, c.icon, c.color, c.icon_image_url, c.is_private_dm,
        CASE WHEN c.is_private_dm THEN (SELECT json_build_object('id', p.id, 'full_name', p.full_name, 'avatar_url', p.avatar_url) FROM profiles p WHERE p.id <> auth.uid() AND p.id = ANY(c.dm_participant_ids) LIMIT 1) ELSE NULL END AS other_participant,
        c.is_locked
    FROM channels c
    WHERE c.is_deleted = false AND (c.id IN (SELECT cm.channel_id FROM channel_members cm WHERE cm.profile_id = auth.uid()) OR c.created_by = auth.uid() OR (c.is_private_dm = true AND c.dm_participant_ids @> ARRAY[auth.uid()]));
END;
$$;


ALTER FUNCTION "public"."get_my_channels"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_channels_with_unread_and_preview"() RETURNS TABLE("id" bigint, "created_at" timestamp with time zone, "name" "text", "description" "text", "created_by" "uuid", "icon_image_url" "text", "is_private_dm" boolean, "other_participant" json, "unread_count" bigint, "last_message_content" "text", "last_message_created_at" timestamp with time zone, "is_locked" boolean)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    _user_id uuid := auth.uid();
    _channel_ids_found bigint[];
    _channel_count int;
BEGIN
    SELECT array_agg(cm.channel_id), count(cm.channel_id)
    INTO _channel_ids_found, _channel_count
    FROM public.channel_members cm
    WHERE cm.profile_id = _user_id;

    IF _channel_count = 0 OR _channel_count IS NULL THEN RETURN; END IF;

    RETURN QUERY
    WITH user_channels AS (
        SELECT cm.channel_id, cm.last_read_at FROM public.channel_members cm WHERE cm.profile_id = _user_id
    ),
    last_messages AS (
        SELECT m.channel_id, m.content, m.created_at, ROW_NUMBER() OVER(PARTITION BY m.channel_id ORDER BY m.created_at DESC) as rn
        FROM public.messages m WHERE m.channel_id IN (SELECT channel_id FROM user_channels)
    )
    SELECT
        c.id, c.created_at,
        CASE WHEN c.is_private_dm THEN (SELECT p.full_name FROM public.profiles p JOIN public.channel_members cm ON p.id = cm.profile_id WHERE cm.channel_id = c.id AND cm.profile_id <> _user_id LIMIT 1) ELSE c.name END AS name,
        c.description, c.created_by,
        CASE WHEN c.is_private_dm THEN (SELECT p.avatar_url FROM public.profiles p JOIN public.channel_members cm ON p.id = cm.profile_id WHERE cm.channel_id = c.id AND cm.profile_id <> _user_id LIMIT 1) ELSE c.icon_image_url END AS icon_image_url,
        c.is_private_dm,
        (SELECT json_build_object('id', p.id, 'full_name', p.full_name, 'avatar_url', p.avatar_url) FROM public.profiles p JOIN public.channel_members cm ON p.id = cm.profile_id WHERE cm.channel_id = c.id AND cm.profile_id <> _user_id LIMIT 1) AS other_participant,
        (SELECT COUNT(*) FROM public.messages m WHERE m.channel_id = c.id AND (uc.last_read_at IS NULL OR m.created_at > uc.last_read_at) AND m.profile_id <> _user_id) AS unread_count,
        lm.content AS last_message_content, lm.created_at AS last_message_created_at,
        c.is_locked
    FROM public.channels c
    JOIN user_channels uc ON c.id = uc.channel_id
    LEFT JOIN last_messages lm ON c.id = lm.channel_id AND lm.rn = 1
    WHERE c.is_deleted = false
    ORDER BY lm.created_at DESC NULLS LAST;
END;
$$;


ALTER FUNCTION "public"."get_my_channels_with_unread_and_preview"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_claim"("claim" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN nullif(current_setting('request.jwt.claims', true), '')::jsonb -> claim;
END;
$$;


ALTER FUNCTION "public"."get_my_claim"("claim" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_role"() RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT role::text FROM public.profiles WHERE id = auth.uid()
$$;


ALTER FUNCTION "public"."get_my_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_next_business_day"("from_date" "date") RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    next_day date;
BEGIN
    next_day := from_date + interval '1 day';
    -- Se o próximo dia for domingo (day of week = 0), adiciona mais um dia para ser segunda.
    IF extract(dow from next_day) = 0 THEN
        next_day := next_day + interval '1 day';
    END IF;
    RETURN next_day;
END;
$$;


ALTER FUNCTION "public"."get_next_business_day"("from_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_next_delivery_day"("from_date" "date") RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  new_date date := from_date + 1;
BEGIN
  LOOP
    -- Terça = 2, Quinta = 4, Sábado = 6
    IF EXTRACT(DOW FROM new_date) IN (2, 4, 6) THEN
      RETURN new_date;
    END IF;
    new_date := new_date + 1;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."get_next_delivery_day"("from_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_next_order_number"() RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  next_number integer;
  max_order integer;
  max_draft integer;
BEGIN
  -- 1. Pega o maior número de pedido já efetivado
  SELECT COALESCE(MAX(order_number), 0) INTO max_order FROM orders;
  
  -- 2. Pega o maior número reservado na tabela de rascunhos
  SELECT COALESCE(MAX(reserved_order_number), 0) INTO max_draft FROM order_drafts;

  -- 3. Compara os dois. O próximo número será o MAIOR deles + 1
  IF max_order >= max_draft THEN
    next_number := max_order + 1;
  ELSE
    next_number := max_draft + 1;
  END IF;

  RETURN next_number;
END;
$$;


ALTER FUNCTION "public"."get_next_order_number"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_orders_with_attachments"() RETURNS TABLE("id" "uuid", "order_number" integer, "customer_name" "text", "created_at" timestamp with time zone, "down_payment_proof_url" "text", "creator" json, "order_payments" json)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.order_number,
        o.customer_name,
        o.created_at,
        o.down_payment_proof_url,
        json_build_object('full_name', p.full_name) as creator,
        (
            SELECT json_agg(json_build_object('receipt_url', op.receipt_url, 'payment_type', op.payment_type))
            FROM public.order_payments op
            WHERE op.order_id = o.id AND op.receipt_url IS NOT NULL
        ) as order_payments
    FROM
        public.orders o
    LEFT JOIN
        public.profiles p ON o.created_by = p.id
    WHERE
        o.down_payment_proof_url IS NOT NULL
        OR
        EXISTS (
            SELECT 1
            FROM public.order_payments op
            WHERE op.order_id = o.id AND op.receipt_url IS NOT NULL
        )
    ORDER BY
        o.created_at DESC;
END;
$$;


ALTER FUNCTION "public"."get_orders_with_attachments"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_pending_stock_orders"() RETURNS TABLE("id" "uuid", "status" "text", "created_at" timestamp with time zone, "customer_name" "text", "total_value" numeric, "creator_name" "text", "items" "jsonb")
    LANGUAGE "sql" STABLE
    AS $$
    SELECT
        pso.id,
        pso.status,
        pso.created_at,
        pso.original_payload->>'customer_name' AS customer_name,
        (pso.original_payload->>'total_value')::numeric AS total_value,
        prof.full_name AS creator_name,
        pso.original_payload->'order_items' AS items
    FROM
        public.pending_stock_orders pso
    JOIN
        public.profiles prof ON prof.id = pso.created_by
    WHERE
        pso.status = 'awaiting_stock';
$$;


ALTER FUNCTION "public"."get_pending_stock_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_productive_sites_ranking"("p_user_id" "uuid", "p_date" "date") RETURNS TABLE("window_title" "text", "total_seconds" numeric)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  -- [IMPORTANTE!] Certifique-se de que este valor é o mesmo da função anterior.
  activity_interval_seconds int := 10;
  start_time timestamptz;
  end_time timestamptz;
BEGIN
  start_time := p_date::timestamptz;
  end_time := start_time + interval '1 day';

  RETURN QUERY
  WITH ranked_sites AS (
    SELECT
      ua.window_title,
      -- Calcula o tempo total
      (COUNT(*) * activity_interval_seconds) AS calculated_total_seconds
    FROM
      public.user_activity AS ua
    WHERE
      ua.user_id = p_user_id
      AND ua.created_at >= start_time
      AND ua.created_at < end_time
      -- Filtra apenas por atividade produtiva
      AND ua.classification = 'produtivo'
      -- Filtra por nomes de processos de navegadores comuns
      AND ua.application_name IN (
        'Google Chrome', 'chrome.exe',
        'Microsoft Edge', 'msedge.exe',
        'Firefox', 'firefox.exe',
        'Safari', 'safari.exe',
        'Brave', 'brave.exe'
      )
      AND ua.window_title IS NOT NULL
    GROUP BY
      ua.window_title
  )
  SELECT
    rs.window_title,
    rs.calculated_total_seconds::numeric
  FROM
    ranked_sites AS rs
  -- Ignora títulos genéricos ou vazios que podem poluir o gráfico
  WHERE
    rs.window_title NOT IN ('Nova guia', 'New Tab') 
    AND rs.window_title != ''
  ORDER BY
    rs.calculated_total_seconds DESC
  LIMIT 5;

END;
$$;


ALTER FUNCTION "public"."get_productive_sites_ranking"("p_user_id" "uuid", "p_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_sales_by_region"("start_date" "date", "end_date" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result JSONB;
BEGIN
    -- Mapeamento de vendedor para região (ajuste conforme necessário)
    WITH seller_regions AS (
        SELECT id,
               CASE
                   WHEN full_name IN ('Beatriz Garcia', 'Marcos Levi', 'Juci', 'Fernanda Garcia', 'João Vitor') THEN 'Sudoeste'
                   WHEN full_name IN ('Elda', 'Sueli') THEN 'Nordeste'
                   ELSE 'Outros'
               END as region
        FROM public.profiles
    )
    SELECT jsonb_build_object(
        'Sudoeste', COALESCE(SUM(CASE WHEN sr.region = 'Sudoeste' THEN o.total_value ELSE 0 END), 0),
        'Nordeste', COALESCE(SUM(CASE WHEN sr.region = 'Nordeste' THEN o.total_value ELSE 0 END), 0)
    )
    INTO result
    FROM public.orders o
    JOIN seller_regions sr ON o.created_by = sr.id
    WHERE o.created_at BETWEEN start_date AND end_date;

    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_sales_by_region"("start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_sales_orders_list"() RETURNS TABLE("id" "uuid", "order_number" integer, "customer_name" "text", "created_at" timestamp with time zone, "total_value" numeric, "status" "text", "is_invoiced" boolean, "created_by" "uuid", "creator_full_name" "text", "item_count" bigint, "products_summary" "text", "total_meters" numeric, "order_items_json" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Lógica de segurança manual
  IF (get_my_role() = 'admin'::text) THEN
    -- 1. SE FOR ADMIN: Retorna todos os pedidos
    RETURN QUERY
    SELECT
      o.id, o.order_number, o.customer_name, o.created_at, o.total_value,
      o.status, o.is_invoiced, o.created_by, p.full_name as creator_full_name,
      COUNT(oi.id) as item_count,
      STRING_AGG(oi.fabric_type, ', ') as products_summary,
      SUM(oi.quantity_meters) as total_meters,
      jsonb_agg(jsonb_build_object('fabric', oi.fabric_type, 'meters', oi.quantity_meters)) as order_items_json
    FROM
      public.orders o
      LEFT JOIN public.profiles p ON o.created_by = p.id
      LEFT JOIN public.order_items oi ON o.id = oi.order_id
    GROUP BY o.id, p.full_name
    ORDER BY o.order_number DESC;
  ELSE
    -- 2. SE FOR VENDEDOR: Retorna SÓ os dele
    RETURN QUERY
    SELECT
      o.id, o.order_number, o.customer_name, o.created_at, o.total_value,
      o.status, o.is_invoiced, o.created_by, p.full_name as creator_full_name,
      COUNT(oi.id) as item_count,
      STRING_AGG(oi.fabric_type, ', ') as products_summary,
      SUM(oi.quantity_meters) as total_meters,
      jsonb_agg(jsonb_build_object('fabric', oi.fabric_type, 'meters', oi.quantity_meters)) as order_items_json
    FROM
      public.orders o
      LEFT JOIN public.profiles p ON o.created_by = p.id
      LEFT JOIN public.order_items oi ON o.id = oi.order_id
    WHERE
      o.created_by = auth.uid()
    GROUP BY o.id, p.full_name
    ORDER BY o.order_number DESC;
  END IF;
END;
$$;


ALTER FUNCTION "public"."get_sales_orders_list"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_sales_rankings"("start_date" "date", "end_date" "date") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN (
        SELECT jsonb_build_object(
            'top_sellers', (
                SELECT jsonb_agg(seller_ranking)
                FROM (
                    SELECT
                        p.full_name as seller_name,
                        p.avatar_url, -- <<< CORREÇÃO APLICADA AQUI
                        SUM(o.total_value) as total_sold
                    FROM public.orders o
                    JOIN public.profiles p ON o.created_by = p.id
                    WHERE o.created_at BETWEEN start_date AND end_date
                    GROUP BY p.full_name, p.avatar_url -- <<< E AQUI
                    ORDER BY total_sold DESC
                    LIMIT 10
                ) as seller_ranking
            ),
            'top_customers', (
                SELECT jsonb_agg(customer_ranking)
                FROM (
                    SELECT
                        customer_name,
                        SUM(total_value) as total_purchased,
                        COUNT(id) as total_orders
                    FROM public.orders
                    WHERE created_at BETWEEN start_date AND end_date
                    GROUP BY customer_name
                    ORDER BY total_purchased DESC
                    LIMIT 10
                ) as customer_ranking
            )
        )
    );
END;
$$;


ALTER FUNCTION "public"."get_sales_rankings"("start_date" "date", "end_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_stock_audit_filters"() RETURNS json
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    users_list json;
    fabrics_list json;
BEGIN
    -- Busca todos os nomes de usuários únicos que aparecem nos logs de estoque
    SELECT json_agg(DISTINCT u.full_name) INTO users_list
    FROM public.stock_movements sm
    JOIN public.users u ON sm.user_id = u.id
    WHERE u.full_name IS NOT NULL;

    -- Busca todos os tipos de tecidos únicos que aparecem nos logs de estoque
    SELECT json_agg(DISTINCT sm.fabric_type) INTO fabrics_list
    FROM public.stock_movements sm
    WHERE sm.fabric_type IS NOT NULL;

    -- Retorna um objeto JSON com as duas listas
    RETURN json_build_object('users', users_list, 'fabrics', fabrics_list);
END;
$$;


ALTER FUNCTION "public"."get_stock_audit_filters"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_stock_movements_report"("start_date" "text", "end_date" "text") RETURNS TABLE("id" bigint, "created_at" timestamp with time zone, "movement_type" "text", "quantity_moved" numeric, "old_quantity" numeric, "new_quantity" numeric, "notes" "text", "fabric_type" "text", "full_name" "text", "order_number" integer, "lote" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        sm.id,
        sm.created_at,
        sm.movement_type,
        sm.quantity_moved,
        sm.old_quantity,
        sm.new_quantity,
        sm.notes,
        s.fabric_type,
        p.full_name,
        o.order_number,
        sm.lote
    FROM
        public.stock_movements sm
        LEFT JOIN public.stock s ON sm.product_id = s.id
        LEFT JOIN public.profiles p ON sm.user_id = p.id
        LEFT JOIN public.order_items oi ON sm.order_item_id = oi.id
        LEFT JOIN public.orders o ON oi.order_id = o.id
    WHERE
        sm.created_at >= start_date::TIMESTAMPTZ AND
        sm.created_at <= end_date::TIMESTAMPTZ
    ORDER BY
        sm.created_at DESC;
END;
$$;


ALTER FUNCTION "public"."get_stock_movements_report"("start_date" "text", "end_date" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_activity_report"("p_user_id" "uuid") RETURNS TABLE("activity_timestamp" timestamp with time zone, "action_type" "text", "description" "text", "metadata" "jsonb")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    -- Ações nos Pedidos (da tabela order_logs)
    SELECT
        ol.created_at AS activity_timestamp,
        ol.log_type AS action_type,
        ol.description AS description,
        ol.metadata AS metadata
    FROM public.order_logs ol
    WHERE ol.profile_id = p_user_id

    UNION ALL

    -- Ação: Envio de Mensagens no Chat
    SELECT
        m.created_at AS activity_timestamp,
        'CHAT_MESSAGE' AS action_type,
        'Enviou mensagem no canal "' || c.name || '"' AS description,
        jsonb_build_object(
            'channel_id', m.channel_id,
            'message_id', m.id,
            'content', left(m.content, 100)
        ) AS metadata
    FROM public.messages m
    JOIN public.channels c ON m.channel_id = c.id
    WHERE m.profile_id = p_user_id AND m.is_deleted = false

    ORDER BY activity_timestamp DESC;
END;
$$;


ALTER FUNCTION "public"."get_user_activity_report"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_activity_summary_with_presence"() RETURNS TABLE("user_id" "uuid", "full_name" "text", "avatar_url" "text", "role" "text", "last_activity_time" timestamp with time zone, "last_application_name" "text", "last_window_title" "text", "last_classification" "text", "today_productive_seconds" bigint, "today_unproductive_seconds" bigint, "today_neutral_seconds" bigint, "status" "text", "last_seen" timestamp with time zone)
    LANGUAGE "sql" STABLE
    AS $$
WITH LatestActivity AS (
    -- Subquery para obter a última atividade de cada usuário
    SELECT DISTINCT ON (ua.user_id)
        ua.user_id,
        ua.created_at AS last_activity_time,
        ua.application_name AS last_application_name,
        ua.window_title AS last_window_title,
        ua.classification AS last_classification
    FROM public.user_activity ua
    ORDER BY ua.user_id, ua.created_at DESC
),
TimeSummary AS (
    -- Subquery para calcular o tempo total em cada classificação HOJE
    SELECT
        ua.user_id,
        COALESCE(SUM(CASE WHEN ua.classification = 'produtivo' THEN 30 ELSE 0 END), 0) AS today_productive_seconds, -- Assumindo intervalo de 30s
        COALESCE(SUM(CASE WHEN ua.classification = 'improdutivo' THEN 30 ELSE 0 END), 0) AS today_unproductive_seconds, -- Assumindo intervalo de 30s
        COALESCE(SUM(CASE WHEN ua.classification = 'neutro' THEN 30 ELSE 0 END), 0) AS today_neutral_seconds -- Assumindo intervalo de 30s
    FROM public.user_activity ua
    WHERE ua.created_at >= date_trunc('day', timezone('America/Sao_Paulo', now())) -- Filtra para hoje (ajuste o fuso horário se necessário)
      AND ua.created_at < date_trunc('day', timezone('America/Sao_Paulo', now())) + interval '1 day'
    GROUP BY ua.user_id
)
SELECT
    p.id AS user_id,
    p.full_name,
    p.avatar_url,
    p.role::text, -- Converte user_role para text se necessário
    la.last_activity_time,
    la.last_application_name,
    la.last_window_title,
    la.last_classification,
    ts.today_productive_seconds,
    ts.today_unproductive_seconds,
    ts.today_neutral_seconds,
    up.status,
    up.last_seen
FROM public.profiles p
LEFT JOIN LatestActivity la ON p.id = la.user_id
LEFT JOIN TimeSummary ts ON p.id = ts.user_id
LEFT JOIN public.user_presences up ON p.id = up.user_id
ORDER BY p.full_name; -- Ordena por nome por padrão
$$;


ALTER FUNCTION "public"."get_user_activity_summary_with_presence"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_stamp_upload"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  project_url text := 'https://drprfuinwglmzquqtqzq.supabase.co';
  public_url text;
  clean_name text;
BEGIN
  IF NEW.bucket_id = 'stamp-library' THEN
    
    -- Monta a URL pública do arquivo
    public_url := project_url || '/storage/v1/object/public/' || NEW.bucket_id || '/' || NEW.name;

    -- Limpa o nome do arquivo
    -- Remove prefixo numérico e traço, ex: 1757068877336-700774_BB_BANDEIRA.jpg -> 700774_BB_BANDEIRA.jpg
    clean_name := regexp_replace(NEW.name, '^[0-9]+-', '');

    -- Insere na tabela com o nome limpo
    INSERT INTO public.stamp_library (name, gestao_click_service_id, image_url)
    VALUES (clean_name, NEW.name, public_url);

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_stamp_upload"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user_to_lead"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.public_leads (id, email, name)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'name', 'Visitante')
  )
  ON CONFLICT (email) DO NOTHING;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user_to_lead"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_order_submission_v2"("p_order_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    has_sufficient_stock BOOLEAN;
    result JSONB;
BEGIN
    -- Passo 1: Verificar se todos os itens no payload têm estoque suficiente
    -- (Esta lógica pode ser uma função auxiliar ou estar aqui diretamente)
    SELECT are_all_items_in_stock(p_order_payload) INTO has_sufficient_stock;

    -- Passo 2: Roteamento da lógica
    IF has_sufficient_stock THEN
        -- TEM ESTOQUE: Chama a função antiga e testada para criar o pedido normalmente
        SELECT create_order_with_stock_check(
            p_order_payload->>'customer_name',
            (p_order_payload->>'created_by')::uuid,
            (p_order_payload->>'store_id')::uuid,
            (p_order_payload->>'has_down_payment')::boolean,
            p_order_payload->>'down_payment_proof_url',
            p_order_payload->'order_items',
            (p_order_payload->>'total_value')::numeric,
            (p_order_payload->>'customer_id')::integer,
            p_order_payload->>'observation'
        ) INTO result;

        RETURN jsonb_build_object('status', 'created', 'order_details', result);

    ELSE
        -- NÃO TEM ESTOQUE: Insere na nova tabela de pendentes
        INSERT INTO public.pending_stock_orders (created_by, original_payload, required_stock_items, store_id)
        VALUES (
            (p_order_payload->>'created_by')::uuid,
            p_order_payload,
            extract_required_stock(p_order_payload), -- Função auxiliar para extrair o JSON de verificação
            (p_order_payload->>'store_id')::uuid
        );

        -- Lógica para enviar itens de Desenvolvimento/Alteração ao Design
        PERFORM create_design_items_from_pending_order(p_order_payload);

        RETURN jsonb_build_object('status', 'pending_stock');
    END IF;
END;
$$;


ALTER FUNCTION "public"."handle_order_submission_v2"("p_order_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_public_leads_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_public_leads_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_delete_permission"("required_permission" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_role text;
  v_custom_role_id uuid;
  v_user_permissions text;
  v_custom_role_permissions text;
BEGIN
  -- Pega os dados do usuário (focando na nova coluna delete_permissions)
  SELECT role::text, custom_role_id, delete_permissions::text 
  INTO v_role, v_custom_role_id, v_user_permissions
  FROM public.profiles WHERE id = auth.uid();
  
  -- Super Admin sempre tem poder de destruir tudo
  IF v_role = 'super_admin' THEN RETURN true; END IF;

  -- Verifica as permissões de exclusão diretas do usuário
  IF v_user_permissions IS NOT NULL AND v_user_permissions != '' THEN
    IF v_user_permissions LIKE '%"' || required_permission || '"%' 
       OR v_user_permissions LIKE '%''' || required_permission || '''%'
       OR v_user_permissions LIKE '%' || required_permission || ',%'
       OR v_user_permissions LIKE '%,' || required_permission || '%'
       OR v_user_permissions = required_permission
       OR v_user_permissions = '{' || required_permission || '}' 
       OR v_user_permissions = '[' || required_permission || ']' THEN
      RETURN true;
    END IF;
  END IF;

  -- Verifica as permissões de exclusão atreladas ao Cargo (Custom Role)
  IF v_custom_role_id IS NOT NULL THEN
    SELECT delete_permissions::text INTO v_custom_role_permissions 
    FROM public.custom_roles WHERE id = v_custom_role_id;

    IF v_custom_role_permissions IS NOT NULL AND v_custom_role_permissions != '' THEN
      IF v_custom_role_permissions LIKE '%"' || required_permission || '"%' 
         OR v_custom_role_permissions LIKE '%''' || required_permission || '''%'
         OR v_custom_role_permissions LIKE '%' || required_permission || ',%'
         OR v_custom_role_permissions LIKE '%,' || required_permission || '%'
         OR v_custom_role_permissions = required_permission
         OR v_custom_role_permissions = '{' || required_permission || '}' 
         OR v_custom_role_permissions = '[' || required_permission || ']' THEN
        RETURN true;
      END IF;
    END IF;
  END IF;

  RETURN false;
END;
$$;


ALTER FUNCTION "public"."has_delete_permission"("required_permission" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_permission"("p_permission" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_role text;
  v_permissions jsonb;
BEGIN
  SELECT role, permissions::jsonb 
  INTO v_role, v_permissions
  FROM public.profiles 
  WHERE id = auth.uid();

  IF v_role = 'super_admin' THEN
    RETURN true;
  END IF;

  IF v_permissions IS NOT NULL AND v_permissions ? p_permission THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;


ALTER FUNCTION "public"."has_permission"("p_permission" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_screen_permission"("required_permission" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_permissions text;
BEGIN
  -- Busca o campo permissions como texto bruto
  SELECT permissions::text INTO v_permissions
  FROM public.profiles
  WHERE id = auth.uid();
  
  -- Se for nulo ou vazio, recusa
  IF v_permissions IS NULL OR v_permissions = '' THEN
    RETURN false;
  END IF;

  -- Verifica se a permissão exata existe na string, ignorando aspas, colchetes e chaves
  -- Isso funciona tanto para o formato text[] do Postgres quanto para string de JSON real
  IF v_permissions LIKE '%"' || required_permission || '"%' 
     OR v_permissions LIKE '%''' || required_permission || '''%'
     OR v_permissions LIKE '%' || required_permission || ',%'
     OR v_permissions LIKE '%,' || required_permission || '%'
     OR v_permissions = required_permission
     OR v_permissions = '{' || required_permission || '}' 
     OR v_permissions = '[' || required_permission || ']' THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;


ALTER FUNCTION "public"."has_screen_permission"("required_permission" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment"("table_name" "text", "row_id" "uuid", "x" numeric) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Esta é uma forma segura de construir uma query dinâmica no PostgreSQL.
  -- Ela atualiza a coluna 'available_meters' na tabela 'stock'
  -- onde o 'id' da linha corresponde ao 'row_id' fornecido.
  EXECUTE format('UPDATE public.%I SET available_meters = available_meters + %L WHERE id = %L', table_name, x, row_id);
END;
$$;


ALTER FUNCTION "public"."increment"("table_name" "text", "row_id" "uuid", "x" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN (
        SELECT role
        FROM public.profiles
        WHERE id = auth.uid()
    ) = 'admin'::user_role;
END;
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin_or_super"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  );
END;
$$;


ALTER FUNCTION "public"."is_admin_or_super"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_channel_member"("_channel_id" bigint) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.channel_members
    WHERE channel_id = _channel_id AND profile_id = auth.uid()
  )
$$;


ALTER FUNCTION "public"."is_channel_member"("_channel_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_user_member_of_channel"("p_channel_id" bigint, "p_profile_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
  RETURN EXISTS(SELECT 1 FROM public.channel_members WHERE channel_id = p_channel_id AND profile_id = p_profile_id);
END;
$$;


ALTER FUNCTION "public"."is_user_member_of_channel"("p_channel_id" bigint, "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_security_events"("p_events" "jsonb") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    event JSONB;
BEGIN
    FOR event IN SELECT * FROM jsonb_array_elements(p_events)
    LOOP
        INSERT INTO public.security_events_log (
            session_id, user_id, context, event_type, art_id, 
            time_on_art, visible_duration, scroll_speed, 
            exposed_count, interaction_count, metadata_json
        ) VALUES (
            event->>'session_id',
            NULLIF(event->>'user_id', '')::UUID,
            event->>'context',
            event->>'event_type',
            event->>'art_id',
            (event->>'time_on_art')::NUMERIC,
            (event->>'visible_duration')::NUMERIC,
            (event->>'scroll_speed')::NUMERIC,
            (event->>'exposed_count')::INTEGER,
            (event->>'interaction_count')::INTEGER,
            COALESCE(event->'metadata_json', '{}'::JSONB)
        );
    END LOOP;
    
    RETURN true;
END;
$$;


ALTER FUNCTION "public"."log_security_events"("p_events" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_stock_change"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Lógica para quando um item é ATUALIZADO
    IF (TG_OP = 'UPDATE') THEN
        -- Só registra se a quantidade de metros realmente mudou
        IF OLD.available_meters <> NEW.available_meters THEN
            INSERT INTO public.stock_movements (product_id, movement_type, quantity_moved, old_quantity, new_quantity, user_id, notes)
            VALUES (
                NEW.id,
                CASE WHEN NEW.available_meters > OLD.available_meters THEN 'entrada' ELSE 'saida' END,
                NEW.available_meters - OLD.available_meters,
                OLD.available_meters,
                NEW.available_meters,
                auth.uid(), -- Agora isso vai funcionar por causa do 'SECURITY INVOKER'
                'Alteração Manual'
            );
        END IF;
        RETURN NEW;
    END IF;

    -- Lógica para quando um item é INSERIDO (novo tecido)
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.stock_movements (product_id, movement_type, quantity_moved, old_quantity, new_quantity, user_id, notes)
        VALUES (
            NEW.id,
            'entrada_inicial',
            NEW.available_meters,
            0,
            NEW.available_meters,
            auth.uid(),
            'Criação de Novo Tecido'
        );
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."log_stock_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_universal_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_id uuid;
  v_user_name text;
  v_entity_id text;
  v_didactic_message text;
  v_table_friendly text;
  old_clean jsonb;
  new_clean jsonb;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NOT NULL THEN
    -- 1. Tenta buscar no profiles (equipe interna)
    SELECT full_name INTO v_user_name FROM public.profiles WHERE id = v_user_id;
    
    -- 2. Se for NULL, busca no public_leads (clientes do marketplace)
    IF v_user_name IS NULL THEN
        SELECT name INTO v_user_name FROM public.public_leads WHERE id = v_user_id;
    END IF;
  END IF;

  -- 3. Garante que nunca seja NULL para não quebrar a concatenação
  v_user_name := COALESCE(v_user_name, 'Sistema / Cliente');

  CASE TG_TABLE_NAME
    WHEN 'orders' THEN v_table_friendly := 'Pedido de Venda';
    WHEN 'order_items' THEN v_table_friendly := 'Item de Produção';
    WHEN 'stock' THEN v_table_friendly := 'Estoque de Tecido';
    WHEN 'finance_receivables' THEN v_table_friendly := 'Conta a Receber';
    WHEN 'customers_mj' THEN v_table_friendly := 'Cliente';
    WHEN 'app_config' THEN v_table_friendly := 'Configurações do Sistema';
    ELSE v_table_friendly := TG_TABLE_NAME;
  END CASE;

  IF TG_OP = 'INSERT' THEN
    v_entity_id := COALESCE((row_to_json(NEW)->>'id'), (row_to_json(NEW)->>'key'), 'SISTEMA');
    v_didactic_message := v_user_name || ' criou um novo registro de ' || v_table_friendly || '.';
    
    INSERT INTO public.operation_events (actor_id, actor_name, action_type, entity_type, entity_id, entity_label, didactic_message, after_data, module_key, actor_type, severity) 
    VALUES (v_user_id, v_user_name, 'INSERT', TG_TABLE_NAME, v_entity_id, v_table_friendly, v_didactic_message, to_jsonb(NEW), 'Global Audit', 'user', 'info');
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    old_clean := to_jsonb(OLD) - 'updated_at' - 'last_alerted_at' - 'last_seen' - 'last_read_at';
    new_clean := to_jsonb(NEW) - 'updated_at' - 'last_alerted_at' - 'last_seen' - 'last_read_at';
    IF old_clean = new_clean THEN RETURN NEW; END IF;

    v_entity_id := COALESCE((row_to_json(NEW)->>'id'), (row_to_json(NEW)->>'key'), 'SISTEMA');
    v_didactic_message := v_user_name || ' alterou dados de ' || v_table_friendly || '.';
    
    INSERT INTO public.operation_events (actor_id, actor_name, action_type, entity_type, entity_id, entity_label, didactic_message, before_data, after_data, module_key, actor_type, severity) 
    VALUES (v_user_id, v_user_name, 'UPDATE', TG_TABLE_NAME, v_entity_id, v_table_friendly, v_didactic_message, to_jsonb(OLD), to_jsonb(NEW), 'Global Audit', 'user', 'warning');
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    v_entity_id := COALESCE((row_to_json(OLD)->>'id'), (row_to_json(OLD)->>'key'), 'SISTEMA');
    v_didactic_message := v_user_name || ' EXCLUIU um registro de ' || v_table_friendly || '!';
    
    INSERT INTO public.operation_events (actor_id, actor_name, action_type, entity_type, entity_id, entity_label, didactic_message, before_data, module_key, actor_type, severity) 
    VALUES (v_user_id, v_user_name, 'DELETE', TG_TABLE_NAME, v_entity_id, v_table_friendly, v_didactic_message, to_jsonb(OLD), 'Global Audit', 'user', 'critical');
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."log_universal_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."manually_recheck_pending_orders"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    pending_order RECORD;
    processed_count INT := 0;
BEGIN
    RAISE LOG 'Iniciando re-checagem manual de pedidos pendentes...';

    FOR pending_order IN
        SELECT * FROM public.pending_stock_orders
        WHERE status = 'awaiting_stock'
        ORDER BY created_at ASC
    LOOP
        IF are_all_items_in_stock(pending_order.original_payload) THEN
            RAISE LOG 'Pedido ID % para % tem estoque. Atualizando status para ready_to_process.', pending_order.id, pending_order.original_payload->>'customer_name';
            
            UPDATE public.pending_stock_orders
            SET status = 'ready_to_process'
            WHERE id = pending_order.id;

            INSERT INTO public.notifications (recipient_id, content, redirect_url)
            VALUES (
                pending_order.created_by,
                '[TESTE MANUAL] Estoque disponível para o pedido de ' || (pending_order.original_payload->>'customer_name'),
                '/orders'
            );
            
            processed_count := processed_count + 1;
        END IF;
    END LOOP;

    RAISE LOG 'Re-checagem manual finalizada. Pedidos processados: %', processed_count;
    RETURN 'Re-checagem finalizada. Pedidos processados: ' || processed_count;
END;
$$;


ALTER FUNCTION "public"."manually_recheck_pending_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_designers_about_decision"("p_item_id" "uuid", "p_sender_id" "uuid", "p_is_approved" boolean) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  designer_record RECORD;
  item_info RECORD;
  order_info RECORD;
  message_content TEXT;
BEGIN
  -- Obter informações
  SELECT order_id, stamp_ref INTO item_info FROM public.order_items WHERE id = p_item_id;
  SELECT customer_name INTO order_info FROM public.orders WHERE id = item_info.order_id;

  -- Montar a mensagem
  IF p_is_approved THEN
    message_content := 'A arte "' || item_info.stamp_ref || '" de "' || order_info.customer_name || '" foi APROVADA pelo vendedor.';
  ELSE
    message_content := 'Alteração solicitada para a arte "' || item_info.stamp_ref || '" de "' || order_info.customer_name || '".';
  END IF;

  -- Notificar todos os designers
  FOR designer_record IN SELECT id FROM public.profiles WHERE role = 'designer'
  LOOP
    INSERT INTO public.notifications (recipient_id, sender_id, content, redirect_url)
    VALUES (
      designer_record.id,
      p_sender_id,
      message_content,
      '/design'
    );
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."notify_designers_about_decision"("p_item_id" "uuid", "p_sender_id" "uuid", "p_is_approved" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_designers_about_new_item"("p_order_id" "uuid", "p_item_id" "uuid", "p_sender_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  designer_record RECORD;
  order_info RECORD;
BEGIN
  -- Obter informações do pedido para a mensagem
  SELECT customer_name INTO order_info FROM public.orders WHERE id = p_order_id;
  -- Iterar sobre todos os designers e inserir uma notificação para cada um
  FOR designer_record IN SELECT id FROM public.profiles WHERE role = 'designer'
  LOOP
    INSERT INTO public.notifications (recipient_id, sender_id, content, redirect_url)
    VALUES (
      designer_record.id,
      p_sender_id,
      'Novo item de "' || order_info.customer_name || '" entrou na fila de design.',
      '/design'
    );
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."notify_designers_about_new_item"("p_order_id" "uuid", "p_item_id" "uuid", "p_sender_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_seller_about_order_completion"("p_order_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_order_record RECORD;
BEGIN
  -- Obter detalhes do pedido
  SELECT * INTO v_order_record FROM public.orders WHERE id = p_order_id;

  -- Enviar notificação para o vendedor
  IF v_order_record.created_by IS NOT NULL THEN
    INSERT INTO public.notifications(recipient_id, sender_id, content, redirect_url)
    VALUES (
      v_order_record.created_by,
      null, -- Notificação do sistema
      'O pedido de "' || v_order_record.customer_name || '" foi finalizado na produção e está pronto para agendar a entrega.',
      '/entrega' -- Link para a agenda de entrega
    );
  END IF;
END;
$$;


ALTER FUNCTION "public"."notify_seller_about_order_completion"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_seller_about_production_scheduling"("p_item_id" "uuid", "p_scheduled_date" "date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_order_record RECORD;
  v_item_record RECORD;
BEGIN
  -- Obter detalhes do item e do pedido pai
  SELECT * INTO v_item_record FROM public.order_items WHERE id = p_item_id;
  SELECT * INTO v_order_record FROM public.orders WHERE id = v_item_record.order_id;

  -- Enviar notificação para o vendedor que criou o pedido
  IF v_order_record.created_by IS NOT NULL THEN
    INSERT INTO public.notifications(recipient_id, sender_id, content, redirect_url)
    VALUES (
      v_order_record.created_by,
      auth.uid(), -- O usuário que agendou (designer ou admin)
      'Item "' || v_item_record.stamp_ref || '" de "' || v_order_record.customer_name || '" foi agendado para produção em ' || to_char(p_scheduled_date, 'DD/MM/YYYY') || '.',
      '/pedidos' -- Link para a agenda de produção
    );
  END IF;
END;
$$;


ALTER FUNCTION "public"."notify_seller_about_production_scheduling"("p_item_id" "uuid", "p_scheduled_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_seller_for_approval"("p_item_id" "uuid", "p_sender_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  item_info RECORD;
  order_info RECORD;
BEGIN
  -- Obter informações do item e do pedido
  SELECT order_id, stamp_ref INTO item_info FROM public.order_items WHERE id = p_item_id;
  SELECT customer_name, created_by INTO order_info FROM public.orders WHERE id = item_info.order_id;

  -- Inserir notificação para o vendedor (criador do pedido)
  INSERT INTO public.notifications (recipient_id, sender_id, content, redirect_url)
  VALUES (
    order_info.created_by,
    p_sender_id,
    'A arte para "' || item_info.stamp_ref || '" de "' || order_info.customer_name || '" está pronta para sua aprovação.',
    '/pedidos/' || item_info.order_id || '/aprovar'
  );
END;
$$;


ALTER FUNCTION "public"."notify_seller_for_approval"("p_item_id" "uuid", "p_sender_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_approval_decision"("p_decisions" "jsonb", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    decision JSONB;
    has_rejection BOOLEAN := false;
    approved_items UUID[] := ARRAY[]::UUID[];
    item_id UUID;
BEGIN
    -- Verifica se há alguma rejeição na decisão
    SELECT EXISTS (
        SELECT 1
        FROM jsonb_array_elements(p_decisions) AS d
        WHERE d->>'decision' = 'rejected'
    ) INTO has_rejection;

    -- Itera sobre cada decisão de tecido
    FOR decision IN SELECT * FROM jsonb_array_elements(p_decisions)
    LOOP
        IF decision->>'decision' = 'approved' THEN
            FOR item_id IN SELECT * FROM jsonb_array_elements_text(decision->'item_ids') LOOP
                approved_items := array_append(approved_items, item_id);
            END LOOP;
        ELSIF decision->>'decision' = 'rejected' THEN
            UPDATE public.orders
            SET status = 'design_pending', design_tag = 'Alteração'
            WHERE id IN (SELECT value::uuid FROM jsonb_array_elements_text(decision->'item_ids'));

            INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
            SELECT id, p_profile_id, 'COMMENT', 'Solicitação de alteração: ' || (decision->>'comment')
            FROM public.orders
            WHERE id IN (SELECT value::uuid FROM jsonb_array_elements_text(decision->'item_ids'));
        END IF;
    END LOOP;

    -- Processa os itens aprovados
    IF array_length(approved_items, 1) > 0 THEN
        IF has_rejection THEN
            UPDATE public.orders
            SET status = 'design_pending', design_tag = 'Liberado'
            WHERE id = ANY(approved_items);
            INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
            SELECT id, p_profile_id, 'STATUS_CHANGE', 'Aprovado, mas aguardando outras alterações no pedido.'
            FROM public.orders WHERE id = ANY(approved_items);
        ELSE
            UPDATE public.orders
            SET status = 'production_queue'
            WHERE id = ANY(approved_items);
            INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
            SELECT id, p_profile_id, 'STATUS_CHANGE', 'Arte aprovada. Pedido encaminhado para a fila de produção.'
            FROM public.orders WHERE id = ANY(approved_items);
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION "public"."process_approval_decision"("p_decisions" "jsonb", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_item_approval_and_schedule"("p_item_id" "uuid", "p_profile_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    approved_item RECORD;
    schedule_date DATE;
    parent_order RECORD;
BEGIN
    -- 1. Encontra o item e atualiza seu status para 'approved_by_seller'
    UPDATE public.order_items
    SET status = 'approved_by_seller'
    WHERE id = p_item_id
    RETURNING * INTO approved_item;

    -- Se não encontrou o item, retorna um erro
    IF NOT FOUND THEN
        RETURN 'Erro: Item com ID ' || p_item_id || ' não encontrado.';
    END IF;

    -- 2. Busca informações do pedido pai
    SELECT * INTO parent_order FROM public.orders WHERE id = approved_item.order_id;

    -- 3. Loga a ação de aprovação
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description, metadata)
    VALUES (approved_item.order_id, p_profile_id, 'STATUS_CHANGE', 'Item "' || approved_item.stamp_ref || '" aprovado pelo vendedor.', jsonb_build_object('item_id', p_item_id));

    -- 4. Calcula a data de agendamento para o próximo dia útil
    schedule_date := get_next_business_day(CURRENT_DATE);

    -- 5. Insere na tabela de agendamento de produção
    INSERT INTO public.production_schedule (order_id, order_item_id, scheduled_date, quantity_meters)
    VALUES (approved_item.order_id, p_item_id, schedule_date, approved_item.quantity_meters);

    -- 6. Loga a ação de agendamento
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description, metadata)
    VALUES (approved_item.order_id, p_profile_id, 'STATUS_CHANGE', 'Item "' || approved_item.stamp_ref || '" agendado para produção em ' || to_char(schedule_date, 'DD/MM/YYYY') || '.', jsonb_build_object('item_id', p_item_id));

    -- 7. Notifica o time de design sobre a aprovação
    -- (Opcional, mas recomendado para manter o fluxo de comunicação)
    PERFORM notify_designers_about_decision(p_item_id, p_profile_id, true);

    -- 8. Verifica se o pedido pai pode ser finalizado
    PERFORM check_and_finalize_order(approved_item.order_id, p_profile_id);

    RETURN 'Item ' || p_item_id || ' aprovado e agendado para produção com sucesso.';
END;
$$;


ALTER FUNCTION "public"."process_item_approval_and_schedule"("p_item_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_pending_stock_orders"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    pending_order RECORD;
BEGIN
    -- Itera sobre todos os pedidos que estão aguardando estoque
    FOR pending_order IN
        SELECT * FROM public.pending_stock_orders
        WHERE status = 'awaiting_stock'
        ORDER BY created_at ASC
    LOOP
        -- Para cada pedido, faz a verificação completa do estoque
        IF are_all_items_in_stock(pending_order.original_payload) THEN
            -- AÇÃO CORRIGIDA:
            -- Apenas atualiza o status. O frontend cuidará do resto.
            UPDATE public.pending_stock_orders
            SET status = 'ready_to_process'
            WHERE id = pending_order.id;

            -- Cria uma notificação no sistema para avisar o vendedor
            INSERT INTO public.notifications (recipient_id, content, redirect_url)
            VALUES (
                pending_order.created_by,
                'Estoque disponível! O pedido pendente para ' || (pending_order.original_payload->>'customer_name') || ' está sendo processado.',
                '/orders' -- ou a URL apropriada
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."process_pending_stock_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."process_seller_item_decision"("p_item_id" "uuid", "p_decision" "text", "p_comment" "text", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id uuid;
    v_all_items_approved boolean;
BEGIN
    -- Atualiza o status do item.
    UPDATE public.order_items SET status = p_decision WHERE id = p_item_id RETURNING order_id INTO v_order_id;
    
    IF p_decision = 'changes_requested' THEN
        -- CORRETO: Marca a tag e devolve o pedido para a fila de design.
        UPDATE public.order_items SET design_tag = 'Alteração' WHERE id = p_item_id;
        UPDATE public.orders SET status = 'design_pending' WHERE id = v_order_id;
        INSERT INTO public.order_logs (order_id, profile_id, log_type, description) VALUES (v_order_id, p_profile_id, 'COMMENT', 'Alteração solicitada: ' || p_comment);

    ELSEIF p_decision = 'approved_by_seller' THEN
        -- CORRETO: Apenas loga e verifica se o pedido está pronto para o designer.
        INSERT INTO public.order_logs (order_id, profile_id, log_type, description) VALUES (v_order_id, p_profile_id, 'STATUS_CHANGE', 'Item ' || (SELECT stamp_ref FROM order_items WHERE id = p_item_id) || ' aprovado pelo vendedor.');
        
        -- Verifica se todos os itens estão aprovados pelo vendedor.
        SELECT bool_and(status = 'approved_by_seller') INTO v_all_items_approved FROM public.order_items WHERE order_id = v_order_id;

        -- Se tudo estiver aprovado, o status do pedido volta para 'customer_approval', sinalizando ao designer que está pronto para a liberação final.
        IF v_all_items_approved THEN
            UPDATE public.orders SET status = 'customer_approval' WHERE id = v_order_id;
        END IF;
    END IF;
END;
$$;


ALTER FUNCTION "public"."process_seller_item_decision"("p_item_id" "uuid", "p_decision" "text", "p_comment" "text", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reagendar_entrega"("p_order_id" "uuid", "p_new_delivery_date" "date", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Atualiza a data de entrega na tabela de agendamento
    UPDATE public.production_schedule
    SET actual_delivery_date = p_new_delivery_date
    WHERE order_id = p_order_id;

    -- Insere um log registrando a ação manual
    INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_profile_id, 'STATUS_CHANGE', 'Entrega reagendada manualmente para ' || to_char(p_new_delivery_date, 'DD/MM/YYYY') || '.');
END;
$$;


ALTER FUNCTION "public"."reagendar_entrega"("p_order_id" "uuid", "p_new_delivery_date" "date", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recheck_stock_for_entire_orders"() RETURNS TABLE("updated_order_id" "uuid", "items_unlocked_count" bigint)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  order_rec RECORD;
  can_proceed BOOLEAN;
  item_rec RECORD;
  unlocked_count BIGINT;
BEGIN
  -- Percorre cada PEDIDO que tenha pelo menos um item com a flag de estoque insuficiente.
  FOR order_rec IN
    SELECT DISTINCT order_id FROM public.order_items WHERE has_insufficient_stock = TRUE
  LOOP
    can_proceed := TRUE; -- Assumimos que o pedido pode prosseguir, até provar o contrário.

    -- Para cada pedido encontrado, verifica TODOS os seus itens.
    FOR item_rec IN
      SELECT oi.quantity_meters, s.available_meters
      FROM public.order_items oi
      LEFT JOIN public.stock s ON oi.fabric_type = s.fabric_type
      WHERE oi.order_id = order_rec.order_id
    LOOP
      -- Se QUALQUER item do pedido ainda não tiver estoque suficiente, marca o pedido como "não pode prosseguir".
      IF item_rec.available_meters IS NULL OR item_rec.available_meters < item_rec.quantity_meters THEN
        can_proceed := FALSE;
        EXIT; -- Sai do loop interno, pois já sabemos que este pedido não pode ser liberado.
      END IF;
    END LOOP;

    -- Se, após verificar todos os itens, o pedido inteiro puder prosseguir...
    IF can_proceed THEN
      -- ...APENAS remove a flag de estoque insuficiente dos itens daquele pedido.
      -- O status atual do item (seja 'design_pending', 'approved_by_seller', etc.) NÃO É ALTERADO.
      WITH updated_rows AS (
          UPDATE public.order_items
          SET has_insufficient_stock = FALSE
          WHERE order_id = order_rec.order_id AND has_insufficient_stock = TRUE
          RETURNING id
      )
      SELECT count(*) INTO unlocked_count FROM updated_rows;

      -- Retorna o ID do pedido que foi desbloqueado e a contagem de itens.
      RETURN QUERY SELECT order_rec.order_id, unlocked_count;
    END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."recheck_stock_for_entire_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recheck_stock_for_pending_items"() RETURNS TABLE("updated_item_id" "uuid", "old_status" "text", "new_status" "text")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  item_record RECORD;
  stock_record RECORD;
BEGIN
  -- Percorre todos os itens que estão atualmente marcados como sem estoque
  FOR item_record IN
    SELECT id, fabric_type, quantity_meters, status
    FROM public.order_items
    WHERE has_insufficient_stock = TRUE OR status = 'pending_stock'
  LOOP
    -- Para cada item, verifica o estoque atual do tecido correspondente
    SELECT * INTO stock_record
    FROM public.stock
    WHERE fabric_type = item_record.fabric_type;

    -- Se encontrou o tecido no estoque e a quantidade é suficiente
    IF FOUND AND stock_record.available_meters >= item_record.quantity_meters THEN
      -- Atualiza o item para o status normal de design e remove a flag de estoque insuficiente
      UPDATE public.order_items
      SET
        status = 'design_pending',
        has_insufficient_stock = FALSE
      WHERE id = item_record.id;

      -- Retorna o ID do item atualizado e a mudança de status
      RETURN QUERY SELECT item_record.id, item_record.status, 'design_pending';
    END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."recheck_stock_for_pending_items"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."release_item_to_production_v2"("p_item_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Atualiza o status do item para 'in_printing'
    UPDATE public.order_items
    SET status = 'in_printing'
    WHERE id = p_item_id;

    -- Atualiza a data agendada na production_schedule para a data atual
    UPDATE public.production_schedule
    SET scheduled_date = CURRENT_DATE
    WHERE order_item_id = p_item_id;
END;
$$;


ALTER FUNCTION "public"."release_item_to_production_v2"("p_item_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."release_order_to_production"("p_order_id" "uuid", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Chama a função de agendamento automático que já criamos.
    PERFORM public.schedule_order_automatically(p_order_id);

    -- Loga a ação final do designer.
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_profile_id, 'STATUS_CHANGE', 'Pedido liberado para produção pelo designer.');
END;
$$;


ALTER FUNCTION "public"."release_order_to_production"("p_order_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."release_scheduled_order"("p_scheduled_order_id" "uuid", "p_releaser_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    scheduled_rec RECORD;
    new_order_id UUID;
    new_order_number INT;
    total_quantity_meters NUMERIC := 0;
    item_data JSONB;
BEGIN
    SELECT * INTO scheduled_rec
    FROM public.scheduled_orders
    WHERE id = p_scheduled_order_id AND status = 'awaiting_stock'
    FOR UPDATE SKIP LOCKED;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Pedido agendado não encontrado ou já está sendo processado.');
    END IF;

    SELECT nextval('orders_order_number_seq') INTO new_order_number;

    FOR item_data IN SELECT * FROM jsonb_array_elements(scheduled_rec.original_order_payload->'order_items') LOOP
        total_quantity_meters := total_quantity_meters + (item_data->>'quantity_meters')::numeric;
    END LOOP;

    INSERT INTO public.orders (
        order_number, customer_name, created_by, store_id, has_down_payment,
        down_payment_proof_url, status, total_value, quantity_meters, is_launch, details
    ) VALUES (
        new_order_number, scheduled_rec.original_order_payload->>'customer_name', scheduled_rec.created_by,
        (scheduled_rec.original_order_payload->>'store_id')::uuid, (scheduled_rec.original_order_payload->>'has_down_payment')::boolean,
        scheduled_rec.original_order_payload->>'down_payment_proof_url', 'design_pending', (scheduled_rec.original_order_payload->>'total_value')::numeric,
        total_quantity_meters, true, scheduled_rec.original_order_payload
    ) RETURNING id INTO new_order_id;

    FOR item_data IN SELECT * FROM jsonb_array_elements(scheduled_rec.original_order_payload->'order_items') LOOP
        INSERT INTO public.order_items (
            order_id, fabric_type, stamp_ref, quantity_meters, stamp_image_url,
            design_tag, notes, unit_of_measure, rendimento, status, total_value_items, quantity_unit,
            gestao_click_product_id,
            stamp_ref_id -- <<< CORREÇÃO APLICADA AQUI
        ) VALUES (
            new_order_id, item_data->>'fabric_type', item_data->>'stamp_ref', (item_data->>'quantity_meters')::numeric,
            item_data->>'stamp_image_url', item_data->>'design_tag', item_data->>'notes',
            item_data->>'unit_of_measure', (item_data->>'rendimento')::numeric, 'design_pending', (item_data->>'total_value_items')::numeric, (item_data->>'quantity_unit')::numeric,
            item_data->>'gestao_click_product_id',
            item_data->>'stamp_ref_id' -- <<< E AQUI
        );

        UPDATE public.stock
        SET available_meters = available_meters - (item_data->>'quantity_unit')::numeric
        WHERE fabric_type = item_data->>'fabric_type';
    END LOOP;

    UPDATE public.scheduled_orders
    SET
        status = CASE WHEN p_releaser_id IS NOT NULL THEN 'released_by_admin' ELSE 'released_by_stock' END,
        released_at = now(),
        released_by = p_releaser_id
    WHERE id = p_scheduled_order_id;

    RETURN jsonb_build_object('status', 'released', 'order_number', new_order_number, 'order_id', new_order_id);
END;
$$;


ALTER FUNCTION "public"."release_scheduled_order"("p_scheduled_order_id" "uuid", "p_releaser_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_group_member"("p_channel_id" bigint, "p_target_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  is_admin boolean;
  is_mod boolean;
  target_is_admin boolean;
  current_user_name text;
  target_user_name text;
BEGIN
  current_user_id := auth.uid();
  
  SELECT current_user_id = ANY(admin_ids), current_user_id = ANY(moderator_ids), p_target_user_id = ANY(admin_ids)
  INTO is_admin, is_mod, target_is_admin FROM public.channels WHERE id = p_channel_id;

  IF target_is_admin AND current_user_id != p_target_user_id THEN RAISE EXCEPTION 'Acesso negado.'; END IF;
  IF NOT is_admin AND NOT is_mod AND current_user_id != p_target_user_id THEN RAISE EXCEPTION 'Acesso negado.'; END IF;

  DELETE FROM public.channel_members WHERE channel_id = p_channel_id AND profile_id = p_target_user_id;

  UPDATE public.channels SET admin_ids = array_remove(admin_ids, p_target_user_id), moderator_ids = array_remove(moderator_ids, p_target_user_id) WHERE id = p_channel_id;
  
  -- Busca os nomes
  SELECT full_name INTO current_user_name FROM public.profiles WHERE id = current_user_id;
  SELECT full_name INTO target_user_name FROM public.profiles WHERE id = p_target_user_id;

  -- Verifica se ele saiu sozinho ou se foi expulso
  IF current_user_id = p_target_user_id THEN
     INSERT INTO public.messages (channel_id, profile_id, content, message_type) VALUES (p_channel_id, current_user_id, COALESCE(current_user_name, 'Alguém') || ' saiu do grupo.', 'system');
  ELSE
     INSERT INTO public.messages (channel_id, profile_id, content, message_type) VALUES (p_channel_id, current_user_id, COALESCE(current_user_name, 'Alguém') || ' removeu ' || COALESCE(target_user_name, 'um membro') || '.', 'system');
  END IF;
END;
$$;


ALTER FUNCTION "public"."remove_group_member"("p_channel_id" bigint, "p_target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reprocess_pending_stock_orders"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    order_to_process RECORD;
BEGIN
    -- Verifica se a quantidade de metros disponíveis foi aumentada
    IF NEW.available_meters > OLD.available_meters THEN
        -- Itera sobre todos os pedidos que estão aguardando o tecido que foi atualizado
        FOR order_to_process IN
            SELECT id
            FROM public.orders
            WHERE status = 'pending_stock'
              AND details ->> 'fabric_type' = NEW.fabric_type
            ORDER BY created_at ASC -- Processa os mais antigos primeiro
        LOOP
            -- Tenta agendar o pedido novamente usando a lógica correta e atualizada
            -- A função 'schedule_order_automatically' já verifica o estoque e os limites
            PERFORM public.schedule_order_automatically(order_to_process.id);
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."reprocess_pending_stock_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_item_changes"("p_item_id" "uuid", "p_comment" "text", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_order_id uuid;
    v_stamp_ref text;
    v_customer_name text;
    v_designer_id uuid;
BEGIN
    -- 1. Obter detalhes do item e do pedido pai
    SELECT oi.order_id, oi.stamp_ref, o.customer_name, o.designer_id
    INTO v_order_id, v_stamp_ref, v_customer_name, v_designer_id
    FROM public.order_items oi
    JOIN public.orders o ON oi.order_id = o.id
    WHERE oi.id = p_item_id;

    IF v_order_id IS NULL THEN
        RAISE EXCEPTION 'Item do pedido com ID % não encontrado', p_item_id;
    END IF;

    -- 2. Atualizar o item: status volta para 'design_pending' e tag vai para 'Alteração'
    UPDATE public.order_items
    SET
        status = 'design_pending',
        design_tag = 'Alteração'
    WHERE id = p_item_id;

    -- 3. Adicionar um log com o comentário da alteração
    INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
    VALUES (v_order_id, p_profile_id, 'COMMENT', 'Solicitação de alteração para o item "' || v_stamp_ref || '": ' || p_comment);

    -- 4. Enviar notificação para o designer responsável (se houver)
    IF v_designer_id IS NOT NULL THEN
        INSERT INTO public.notifications(recipient_id, sender_id, content, redirect_url)
        VALUES (v_designer_id, p_profile_id, 'Alteração solicitada para o item "' || v_stamp_ref || '" do cliente ' || v_customer_name, '/design');
    END IF;

END;
$$;


ALTER FUNCTION "public"."request_item_changes"("p_item_id" "uuid", "p_comment" "text", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reschedule_production_item"("p_item_id" "uuid", "p_new_date" "date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_order_id uuid;
BEGIN
    -- 1. Atualiza a data na tabela de agendamento (fonte da verdade para o Kanban)
    UPDATE public.production_schedule
    SET scheduled_date = p_new_date
    WHERE order_item_id = p_item_id;

    -- 2. Encontra o ID do pedido principal a partir do item
    SELECT order_id INTO v_order_id
    FROM public.order_items
    WHERE id = p_item_id;

    -- 3. Atualiza também a data na tabela de pedidos para consistência com o Delivery.vue
    IF v_order_id IS NOT NULL THEN
        UPDATE public.orders
        SET production_date = p_new_date
        WHERE id = v_order_id;
    END IF;
END;
$$;


ALTER FUNCTION "public"."reschedule_production_item"("p_item_id" "uuid", "p_new_date" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."restore_credit_on_payment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_payment_method_name text;
BEGIN
  -- Só nos interessa se o status mudou para 'pago'
  IF NEW.status = 'pago' AND OLD.status <> 'pago' THEN
    
    -- Descobre o nome da forma de pagamento usada nesse título
    SELECT name INTO v_payment_method_name
    FROM finance_payment_methods
    WHERE id = NEW.payment_method_id;

    -- Verifica se a forma de pagamento é "Crédito Loja" (ou similar)
    -- Ajuste os nomes conforme seu cadastro exato
    IF v_payment_method_name ILIKE '%crédito loja%' 
       OR v_payment_method_name ILIKE '%credito loja%' 
       OR v_payment_method_name ILIKE '%saldo em loja%' THEN
       
       -- Devolve o valor ao limite usado do cliente (diminui o usado)
       UPDATE customers_mj
       SET credit_used = credit_used - NEW.value
       WHERE id = NEW.customer_id;
       
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."restore_credit_on_payment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revert_item_to_design"("p_item_id" "uuid", "p_admin_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_admin_role text;
  v_order_id uuid;
  v_stamp_ref text;
  v_designer_id uuid;
  v_customer_name text;
BEGIN
  -- Passo 1: Verificar se o usuário que está executando a ação é um administrador.
  SELECT role INTO v_admin_role FROM public.profiles WHERE id = p_admin_id;
  IF v_admin_role != 'admin' THEN
    RAISE EXCEPTION 'Permissão negada: Apenas administradores podem reverter itens para o design.';
  END IF;

  -- Passo 2: Obter informações importantes do item antes de fazer as alterações.
  SELECT oi.order_id, oi.stamp_ref, o.customer_name, o.designer_id
  INTO v_order_id, v_stamp_ref, v_customer_name, v_designer_id
  FROM public.order_items as oi
  JOIN public.orders as o ON oi.order_id = o.id
  WHERE oi.id = p_item_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Item do pedido com ID % não encontrado.', p_item_id;
  END IF;

  -- Passo 3: Atualizar o status do item para "design_pending" e a tag para "Alteração".
  -- Isso o fará reaparecer no Kanban de Design na coluna correta.
  UPDATE public.order_items
  SET
    status = 'design_pending',
    design_tag = 'Alteração'
  WHERE id = p_item_id;

  -- Passo 4: Remover o item da agenda de produção para que não apareça mais
  -- nas telas de Produção e Lançamentos.
  DELETE FROM public.production_schedule WHERE order_item_id = p_item_id;

  -- Passo 5: Registrar a ação no histórico do pedido para auditoria.
  INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
  VALUES (v_order_id, p_admin_id, 'STATUS_CHANGE', 'O item "' || v_stamp_ref || '" foi revertido para a fase de Design pelo administrador.');

  -- Passo 6: Notificar o designer responsável (se houver um) sobre a reversão.
  IF v_designer_id IS NOT NULL THEN
    INSERT INTO public.notifications (recipient_id, sender_id, content, redirect_url)
    VALUES (v_designer_id, p_admin_id, 'O item "' || v_stamp_ref || '" do cliente "' || v_customer_name || '" foi retornado para sua fila para alterações.', '/design');
  END IF;

END;
$$;


ALTER FUNCTION "public"."revert_item_to_design"("p_item_id" "uuid", "p_admin_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reverter_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Reverte o status do pedido para 'completed'
    UPDATE public.orders
    SET status = 'completed'
    WHERE id = p_order_id;

    -- Limpa as informações de agendamento e confirmação
    UPDATE public.production_schedule
    SET
        delivery_confirmed_at = NULL,
        actual_delivery_date = NULL
    WHERE order_id = p_order_id;

    -- Adiciona um log no histórico do pedido
    INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
    VALUES (p_order_id, p_profile_id, 'STATUS_CHANGE', 'Agendamento de entrega revertido. Pedido retornou para a fila de agendamento.');

END;
$$;


ALTER FUNCTION "public"."reverter_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_item_for_production"("p_item_id" "uuid", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id uuid;
    v_item_fabric_type text;
    v_item_quantity_meters numeric;
    v_item_machine_type text;
    v_current_date date := CURRENT_DATE;
    v_scheduled_date date;
    v_day_of_week int;
    v_limit_mesa numeric;
    v_limit_corrida numeric;
    v_limit_overall numeric;
    v_prod_mesa_on_date numeric;
    v_prod_corrida_on_date numeric;
    v_loop_guard int := 0; -- Proteção contra loop infinito
BEGIN
    -- Obter detalhes do item do pedido
    SELECT order_id, fabric_type, quantity_meters
    INTO v_order_id, v_item_fabric_type, v_item_quantity_meters
    FROM public.order_items
    WHERE id = p_item_id;

    IF v_order_id IS NULL THEN
        RAISE EXCEPTION 'Item com ID % não encontrado.', p_item_id;
    END IF;

    -- Determinar o tipo de máquina para o item
    v_item_machine_type := CASE
        WHEN v_item_fabric_type IN ('TECIDO CREPONADO', 'MALHA TULLE', 'MALHA FLUITY', 'MALHA CANELADA', 'MALHA SUPLEX', 'TECIDO CHIFFON', 'MALHA LIGANET') THEN 'MESA'
        ELSE 'CORRIDA'
    END;

    -- Loop para encontrar o próximo dia disponível
    LOOP
        -- Proteção para evitar loop infinito
        v_loop_guard := v_loop_guard + 1;
        IF v_loop_guard > 365 THEN
            RAISE EXCEPTION 'Não foi possível encontrar uma data de produção disponível no próximo ano para o item %.', p_item_id;
        END IF;

        v_day_of_week := EXTRACT(DOW FROM v_current_date);

        -- Pular Domingos (DOW = 0)
        IF v_day_of_week = 0 THEN
            v_current_date := v_current_date + INTERVAL '1 day';
            CONTINUE;
        END IF;

        -- Definir limites diários
        v_limit_mesa := 4000;
        v_limit_corrida := 10000;
        IF v_day_of_week = 6 THEN -- Sábado
            v_limit_overall := 5000;
        ELSE -- Dias de semana
            v_limit_overall := 14000;
        END IF;

        -- Calcular produção existente para o dia, separada por tipo de máquina
        SELECT
            COALESCE(SUM(CASE WHEN (
                CASE
                    WHEN oi.fabric_type IN ('TECIDO CREPONADO', 'MALHA TULLE', 'MALHA FLUITY', 'MALHA CANELADA', 'MALHA SUPLEX', 'TECIDO CHIFFON', 'MALHA LIGANET') THEN 'MESA'
                    ELSE 'CORRIDA'
                END
            ) = 'MESA' THEN oi.quantity_meters ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN (
                CASE
                    WHEN oi.fabric_type IN ('TECIDO CREPONADO', 'MALHA TULLE', 'MALHA FLUITY', 'MALHA CANELADA', 'MALHA SUPLEX', 'TECIDO CHIFFON', 'MALHA LIGANET') THEN 'MESA'
                    ELSE 'CORRIDA'
                END
            ) = 'CORRIDA' THEN oi.quantity_meters ELSE 0 END), 0)
        INTO v_prod_mesa_on_date, v_prod_corrida_on_date
        FROM public.production_schedule ps
        JOIN public.order_items oi ON ps.order_item_id = oi.id
        WHERE ps.scheduled_date = v_current_date;

        -- Verificar se o novo item cabe nos limites
        IF (v_prod_mesa_on_date + v_prod_corrida_on_date + v_item_quantity_meters) <= v_limit_overall THEN
            IF v_item_machine_type = 'MESA' AND (v_prod_mesa_on_date + v_item_quantity_meters) <= v_limit_mesa THEN
                v_scheduled_date := v_current_date;
                EXIT; -- Encontrou um dia
            ELSIF v_item_machine_type = 'CORRIDA' AND (v_prod_corrida_on_date + v_item_quantity_meters) <= v_limit_corrida THEN
                v_scheduled_date := v_current_date;
                EXIT; -- Encontrou um dia
            END IF;
        END IF;

        -- Se não couber, ir para o próximo dia
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;

    -- Garantir que uma data foi encontrada antes de continuar
    IF v_scheduled_date IS NULL THEN
        RAISE EXCEPTION 'Falha crítica: a data de agendamento não pôde ser determinada para o item %.', p_item_id;
    END IF;

    -- Inserir na tabela de agendamento
    INSERT INTO public.production_schedule(order_item_id, order_id, scheduled_date, quantity_meters, status)
    VALUES (p_item_id, v_order_id, v_scheduled_date, v_item_quantity_meters, 'agendado');

    -- Atualizar status do item
    UPDATE public.order_items
    SET status = 'production_queue'
    WHERE id = p_item_id;

    -- Atualizar status do pedido principal se necessário
    UPDATE public.orders
    SET status = 'production_queue'
    WHERE id = v_order_id AND status <> 'production_queue';

    -- Log da ação
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (v_order_id, p_profile_id, 'STATUS_CHANGE', 'Item ' || (SELECT stamp_ref FROM public.order_items WHERE id = p_item_id) || ' agendado para produção em ' || to_char(v_scheduled_date, 'DD/MM/YYYY') || '.');

    -- Notificar o vendedor
    -- PERFORM notify_seller_about_production_scheduling(p_item_id, v_scheduled_date);
END;
$$;


ALTER FUNCTION "public"."schedule_item_for_production"("p_item_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_order"("p_order_id" "uuid") RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_order_quantity_meters int;
  v_current_date date := now();
  v_current_day_of_week int;
  v_daily_production_limit int := 10000;
  v_meters_on_day int;
  v_scheduled_date date;
begin
  -- Pega a metragem do pedido
  select quantity_meters into v_order_quantity_meters from orders where id = p_order_id;

  -- Se a metragem for maior que o limite, retorna um erro
  if v_order_quantity_meters > v_daily_production_limit then
      raise exception 'A metragem do pedido excede o limite diário de produção (10000m).';
  end if;

  -- Procura o próximo dia de produção disponível
  loop
    v_current_day_of_week := extract(isodow from v_current_date); -- 1=Segunda, 5=Sexta

    -- Se for um dia útil (de segunda a sexta)
    if v_current_day_of_week >= 1 and v_current_day_of_week <= 5 then
      -- Verifica a produção já agendada para este dia
      select sum(quantity_meters) into v_meters_on_day
      from orders
      where production_date = v_current_date::date;

      -- Se a produção para o dia for nula, define como 0
      if v_meters_on_day is null then
        v_meters_on_day := 0;
      end if;

      -- Se houver espaço para o novo pedido
      if (v_meters_on_day + v_order_quantity_meters) <= v_daily_production_limit then
        v_scheduled_date := v_current_date;
        exit; -- Encontrou um dia, sai do loop
      end if;
    end if;

    -- Incrementa para o próximo dia para a próxima iteração
    v_current_date := v_current_date + interval '1 day';

  end loop;

  -- Atualiza o pedido com o status e a data de produção
  update orders
  set status = 'production_queue', production_date = v_scheduled_date
  where id = p_order_id;

  return v_scheduled_date;
end;
$$;


ALTER FUNCTION "public"."schedule_order"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_order_automatically"("p_order_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order record;
    v_fabric_type text;
    v_quantity numeric;
    v_machine_type text;
    v_schedule_date date;
    v_current_date date := current_date;
    v_day_of_week int;
    v_daily_limit numeric;
    v_machine_limit numeric;
    v_total_production numeric;
    v_machine_production numeric;
    v_found_slot boolean := false;
BEGIN
    -- Obter detalhes do pedido
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
    v_fabric_type := v_order.details->>'fabric_type';
    v_quantity := v_order.quantity_meters;
    v_machine_type := (SELECT CASE
        WHEN v_fabric_type IN ('Creponado', 'Tule', 'Fluity', 'Canelado', 'Suplex', 'Chiffon', 'Liganet') THEN 'MESA'
        ELSE 'CORRIDA'
    END);

    -- Loop para encontrar o próximo dia disponível
    WHILE NOT v_found_slot LOOP
        v_day_of_week := EXTRACT(DOW FROM v_current_date);

        -- Pular Domingos (DOW = 0)
        IF v_day_of_week = 0 THEN
            v_current_date := v_current_date + INTERVAL '1 day';
            CONTINUE;
        END IF;

        -- Definir limites diários
        v_daily_limit := CASE WHEN v_day_of_week = 6 THEN 5000 ELSE 14000 END;
        v_machine_limit := CASE WHEN v_machine_type = 'MESA' THEN 4000 ELSE 10000 END;

        -- Calcular a produção já agendada para o dia
        SELECT
            COALESCE(SUM(ps.quantity_meters), 0),
            COALESCE(SUM(CASE WHEN (
                SELECT CASE
                    WHEN o.details->>'fabric_type' IN ('Creponado', 'Tule', 'Fluity', 'Canelado', 'Suplex', 'Chiffon', 'Liganet') THEN 'MESA'
                    ELSE 'CORRIDA'
                END
            ) = v_machine_type THEN ps.quantity_meters ELSE 0 END), 0)
        INTO v_total_production, v_machine_production
        FROM public.production_schedule ps
        JOIN public.orders o ON ps.order_id = o.id
        WHERE ps.scheduled_date = v_current_date;

        -- Verificar se há capacidade
        IF (v_total_production + v_quantity) <= v_daily_limit AND (v_machine_production + v_quantity) <= v_machine_limit THEN
            v_schedule_date := v_current_date;
            v_found_slot := true;
        ELSE
            v_current_date := v_current_date + INTERVAL '1 day';
        END IF;
    END LOOP;

    -- Inserir na agenda de produção
    INSERT INTO public.production_schedule (order_id, scheduled_date, quantity_meters)
    VALUES (p_order_id, v_schedule_date, v_quantity);

    -- Atualizar o status do pedido principal
    UPDATE public.orders
    SET status = 'production_queue', production_date = v_schedule_date
    WHERE id = p_order_id;
END;
$$;


ALTER FUNCTION "public"."schedule_order_automatically"("p_order_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_order_with_limits"("p_order_id" "uuid", "p_fabric_type" "text", "p_quantity" numeric, "p_daily_limit" integer DEFAULT 10000) RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    next_production_day date;
    daily_total numeric;
    final_status text;
BEGIN
    -- Encontra o próximo dia útil (Seg-Sáb)
    next_production_day := current_date;
    LOOP
        IF EXTRACT(ISODOW FROM next_production_day) < 7 THEN -- Não agenda no Domingo
            -- Calcula o total já agendado para o dia encontrado
            SELECT COALESCE(SUM(quantity_meters), 0)
            INTO daily_total
            FROM public.orders
            WHERE production_date = next_production_day AND details ->> 'fabric_type' = p_fabric_type;

            -- Verifica se o pedido cabe no limite do dia
            IF (daily_total + p_quantity) <= p_daily_limit THEN
                EXIT; -- Encontrou um dia válido, sai do loop
            END IF;
        END IF;
        next_production_day := next_production_day + interval '1 day';
    END LOOP;

    -- Agenda o pedido para o dia encontrado
    UPDATE public.orders
    SET production_date = next_production_day, status = 'production_queue'
    WHERE id = p_order_id;
    
    final_status := 'production_queue';

    RETURN final_status;
END;
$$;


ALTER FUNCTION "public"."schedule_order_with_limits"("p_order_id" "uuid", "p_fabric_type" "text", "p_quantity" numeric, "p_daily_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_production_for_item"("p_fabric_type" "text", "p_quantity" numeric) RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    machine_type text;
    daily_limit numeric;
    current_production numeric;
    target_date date := current_date;
BEGIN
    machine_type := get_machine_type_for_fabric(p_fabric_type);

    LOOP
        -- Pula Domingos
        IF EXTRACT(DOW FROM target_date) = 0 THEN
            target_date := target_date + 1;
            CONTINUE;
        END IF;

        -- Define o limite diário com base no dia da semana
        IF EXTRACT(DOW FROM target_date) = 6 THEN -- Sábado
            daily_limit := 5000;
        ELSE
            daily_limit := 14000;
        END IF;

        -- Calcula a produção já agendada para o dia
        SELECT COALESCE(SUM(oi.quantity_meters), 0)
        INTO current_production
        FROM production_schedule ps
        JOIN order_items oi ON ps.order_item_id = oi.id
        WHERE ps.scheduled_date = target_date;

        -- Verifica se o item cabe na produção do dia
        IF (current_production + p_quantity) <= daily_limit THEN
            RETURN target_date;
        END IF;

        -- Se não couber, avança para o próximo dia
        target_date := target_date + 1;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."schedule_production_for_item"("p_fabric_type" "text", "p_quantity" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_solid_items_for_production"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    item RECORD;
    schedule_date DATE;
    items_scheduled_count INT := 0;
BEGIN
    -- Itera sobre todos os itens que foram aprovados pelo vendedor mas ainda não foram para a fila de produção
    FOR item IN
        SELECT oi.id, oi.order_id, oi.quantity_meters, oi.created_at
        FROM public.order_items oi
        WHERE oi.status = 'approved_by_seller'
    LOOP
        -- Calcula a data de agendamento para o próximo dia útil a partir da data de aprovação do item
        schedule_date := get_next_business_day(item.created_at::date);

        -- Insere na tabela de agendamento de produção
        INSERT INTO public.production_schedule (order_id, order_item_id, scheduled_date, quantity_meters)
        VALUES (item.order_id, item.id, schedule_date, item.quantity_meters);

        -- Atualiza o status do item para 'production_queue' para que ele seja processado pela produção
        UPDATE public.order_items
        SET status = 'production_queue'
        WHERE id = item.id;

        -- Loga a ação de agendamento automático
        INSERT INTO public.order_logs (order_id, profile_id, log_type, description, metadata)
        VALUES (item.order_id, auth.uid(), 'STATUS_CHANGE', 'Item ' || item.id || ' agendado automaticamente para produção em ' || to_char(schedule_date, 'DD/MM/YYYY') || '.', jsonb_build_object('item_id', item.id));

        items_scheduled_count := items_scheduled_count + 1;
    END LOOP;

    RETURN 'Sincronização concluída. Itens agendados: ' || items_scheduled_count;
END;
$$;


ALTER FUNCTION "public"."schedule_solid_items_for_production"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_initial_forecast_delivery_date"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  start_production_date date;
  completion_date date;
BEGIN
  -- Define que a produção começa no dia seguinte à data de criação.
  start_production_date := (NEW.created_at AT TIME ZONE 'UTC')::date + 1;

  -- Adiciona 2 dias úteis para completar o período de 3 dias de produção.
  completion_date := public.add_business_days(start_production_date, 2);
  
  -- Calcula e define a data de previsão de entrega na nova coluna.
  NEW.forecast_delivery_date := public.get_next_delivery_day(completion_date);
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_initial_forecast_delivery_date"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_message_delete_history"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.original_content := old.content;
  new.is_deleted := true;
  new.deleted_at := now();
  new.content := '[mensagem apagada]';
  return new;
end;
$$;


ALTER FUNCTION "public"."set_message_delete_history"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_message_edit_history"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.content is distinct from old.content then
    new.original_content := old.content;
    new.is_edited := true;
    new.edited_at := now();
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."set_message_edit_history"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    channel_creator_id uuid;
    is_user_admin boolean;
BEGIN
    -- Obter o ID do criador do canal e verificar se o usuário é admin
    SELECT created_by INTO channel_creator_id FROM public.channels WHERE id = p_channel_id;
    SELECT public.is_admin() INTO is_user_admin;

    -- Verificar permissão: Se o usuário é o criador do canal OU um admin
    IF auth.uid() = channel_creator_id OR is_user_admin THEN
        UPDATE public.channels
        SET is_deleted = TRUE, deleted_at = now()
        WHERE id = p_channel_id;
        RETURN TRUE; -- Sucesso
    ELSE
        -- Usuário não tem permissão
        RAISE EXCEPTION 'Permissão negada: Você não é o criador do canal nem um administrador.';
    END IF;
END;
$$;


ALTER FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sre_check_collision_from_drafts"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_conflict_order_id UUID;
    v_draft_user_name TEXT;
BEGIN
    IF NEW.reserved_order_number IS NOT NULL THEN
        SELECT id INTO v_conflict_order_id FROM public.orders WHERE order_number = NEW.reserved_order_number;
        
        IF FOUND THEN
            SELECT full_name INTO v_draft_user_name FROM public.profiles WHERE id = NEW.user_id;
            
            INSERT INTO public.sre_incidents (module, severity, title, description, context_data)
            VALUES (
                'Vendas', 'critical', 
                'Colisão Iminente: Rascunho vs Pedido Faturado', 
                'O rascunho do cliente "' || NEW.name || '" (Vendedor: ' || COALESCE(v_draft_user_name, 'Desconhecido') || ') está a segurar o número #' || NEW.reserved_order_number || ', que JÁ EXISTE na tabela de pedidos efetivados. Se o vendedor tentar salvar, o sistema vai quebrar (Violação de UNIQUE).',
                jsonb_build_object('draft_id', NEW.id, 'conflicting_order_number', NEW.reserved_order_number, 'existing_order_id', v_conflict_order_id, 'resolution_type', 'FIX_DRAFT_NUMBER')
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sre_check_collision_from_drafts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sre_check_collision_from_orders"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.order_drafts WHERE reserved_order_number = NEW.order_number) THEN
        INSERT INTO public.sre_incidents (module, severity, title, description, context_data)
        SELECT 
            'Vendas', 'critical', 
            'Colisão Detectada: Novo Pedido eliminou um Rascunho', 
            'O pedido efetivado #' || NEW.order_number || ' usou um número que estava reservado pelo rascunho de "' || name || '". O rascunho foi corrompido.',
            jsonb_build_object('draft_id', id, 'conflicting_order_number', NEW.order_number, 'existing_order_id', NEW.id, 'resolution_type', 'FIX_DRAFT_NUMBER')
        FROM public.order_drafts WHERE reserved_order_number = NEW.order_number;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sre_check_collision_from_orders"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sre_get_infra_metrics"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_table_stats jsonb;
  v_active_connections int;
BEGIN
  -- Coleta estatísticas reais de I/O das tabelas do seu ERP
  SELECT jsonb_agg(jsonb_build_object(
    'table_name', relname,
    'total_reads', seq_tup_read + idx_tup_fetch,
    'total_inserts', n_tup_ins,
    'total_updates', n_tup_upd,
    'total_deletes', n_tup_del,
    'live_rows', n_live_tup
  ))
  INTO v_table_stats
  FROM pg_stat_user_tables
  WHERE schemaname = 'public' 
    AND relname NOT IN ('operation_events', 'audit_logs'); -- Ignora tabelas de log na volumetria

  -- Conta conexões ativas no banco
  SELECT count(*) INTO v_active_connections FROM pg_stat_activity WHERE state = 'active';

  RETURN jsonb_build_object(
    'tables', v_table_stats,
    'active_connections', v_active_connections,
    'scanned_at', now()
  );
END;
$$;


ALTER FUNCTION "public"."sre_get_infra_metrics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sre_run_reconciliation"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_draft_collisions INT := 0;
    v_fiscal_rejections INT := 0;
BEGIN
    -- A. Reconciliar Drafts em Colisão
    WITH inserted AS (
        INSERT INTO public.sre_incidents (module, severity, title, description, context_data)
        SELECT 
            'Vendas', 'critical', 'Colisão Histórica de Rascunho',
            'O Rascunho do cliente "' || COALESCE(d.name, 'Desconhecido') || '" (criado em ' || to_char(d.created_at, 'DD/MM HH24:MI') || ') tentou reservar o número ' || d.reserved_order_number || ', mas este número JÁ FOI UTILIZADO pelo pedido efetivado ID: ' || o.id::text || '. O rascunho está corrompido e o vendedor tomará erro ao salvar.',
            jsonb_build_object('draft_id', d.id, 'conflict_number', d.reserved_order_number, 'resolution_type', 'FIX_DRAFT')
        FROM public.order_drafts d
        INNER JOIN public.orders o ON d.reserved_order_number = o.order_number
        WHERE NOT EXISTS (
            SELECT 1 FROM public.sre_incidents i 
            WHERE i.context_data->>'draft_id' = d.id::text AND i.status = 'open'
        )
        RETURNING 1
    )
    SELECT count(*) INTO v_draft_collisions FROM inserted;

    -- B. Reconciliar NFe Rejeitadas Presas
    WITH inserted_nfe AS (
        INSERT INTO public.sre_incidents (module, severity, title, description, context_data)
        SELECT 
            'Fiscal', 'critical', 'NFe Rejeitada sem Tratativa',
            'A NFe nº ' || COALESCE(n.numero, 'S/N') || ' para "' || COALESCE(n.destinatario_nome, 'Desconhecido') || '" está parada com status ' || n.status || '. Retorno Sefaz: ' || COALESCE(n.retorno_sefaz->>'xMotivo', 'Desconhecido') || '. Ação necessária para liberar o faturamento.',
            jsonb_build_object('nfe_id', n.id, 'status', n.status, 'resolution_type', 'RETRY_NFE')
        FROM public.nfe_outbound n
        WHERE n.status IN ('REJEITADA', 'ERRO')
        AND NOT EXISTS (
            SELECT 1 FROM public.sre_incidents i 
            WHERE i.context_data->>'nfe_id' = n.id::text AND i.status = 'open'
        )
        RETURNING 1
    )
    SELECT count(*) INTO v_fiscal_rejections FROM inserted_nfe;

    RETURN jsonb_build_object(
        'scanned_at', now(),
        'draft_collisions_found', v_draft_collisions,
        'fiscal_rejections_found', v_fiscal_rejections
    );
END;
$$;


ALTER FUNCTION "public"."sre_run_reconciliation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN DELETE FROM public.admin_channel_members WHERE channel_id = OLD.channel_id AND profile_id = OLD.profile_id; RETURN OLD; END; $$;


ALTER FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN INSERT INTO public.admin_channel_members (channel_id, profile_id, created_at) VALUES (NEW.channel_id, NEW.profile_id, NEW.created_at); RETURN NEW; END; $$;


ALTER FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_channels_to_admin_channels_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN DELETE FROM public.admin_channels WHERE id = OLD.id; RETURN OLD; END; $$;


ALTER FUNCTION "public"."sync_channels_to_admin_channels_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_channels_to_admin_channels_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ 
    BEGIN 
      INSERT INTO public.admin_channels (id, created_at, name, description, created_by, icon, color, icon_image_url, type, is_private_dm, dm_participant_ids, is_deleted, deleted_at, is_locked) 
      VALUES (NEW.id, NEW.created_at, NEW.name, NEW.description, NEW.created_by, NEW.icon, NEW.color, NEW.icon_image_url, NEW.type, NEW.is_private_dm, NEW.dm_participant_ids, NEW.is_deleted, NEW.deleted_at, NEW.is_locked); 
      RETURN NEW; 
    END; 
$$;


ALTER FUNCTION "public"."sync_channels_to_admin_channels_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_channels_to_admin_channels_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ 
    BEGIN 
      UPDATE public.admin_channels 
      SET created_at = NEW.created_at, name = NEW.name, description = NEW.description, created_by = NEW.created_by, icon = NEW.icon, color = NEW.color, icon_image_url = NEW.icon_image_url, type = NEW.type, is_private_dm = NEW.is_private_dm, dm_participant_ids = NEW.dm_participant_ids, is_deleted = NEW.is_deleted, deleted_at = NEW.deleted_at, is_locked = NEW.is_locked
      WHERE id = NEW.id; 
      RETURN NEW; 
    END; 
$$;


ALTER FUNCTION "public"."sync_channels_to_admin_channels_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_messages_to_admin_messages_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN DELETE FROM public.admin_messages WHERE id = OLD.id; RETURN OLD; END; $$;


ALTER FUNCTION "public"."sync_messages_to_admin_messages_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_messages_to_admin_messages_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ 
    BEGIN 
      INSERT INTO public.admin_messages (id, created_at, content, profile_id, channel_id, is_deleted, is_edited, original_content, deleted_at, edited_at, message_type, target_users) 
      VALUES (NEW.id, NEW.created_at, NEW.content, NEW.profile_id, NEW.channel_id, NEW.is_deleted, NEW.is_edited, NEW.original_content, NEW.deleted_at, NEW.edited_at, NEW.message_type, NEW.target_users); 
      RETURN NEW; 
    END; 
$$;


ALTER FUNCTION "public"."sync_messages_to_admin_messages_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_messages_to_admin_messages_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ 
    BEGIN 
      UPDATE public.admin_messages 
      SET is_deleted = NEW.is_deleted, is_edited = NEW.is_edited, original_content = OLD.content, deleted_at = NEW.deleted_at, edited_at = NEW.edited_at, message_type = NEW.message_type, content = NEW.content, profile_id = NEW.profile_id, channel_id = NEW.channel_id, created_at = NEW.created_at, target_users = NEW.target_users
      WHERE id = NEW.id; 
      RETURN NEW; 
    END; 
$$;


ALTER FUNCTION "public"."sync_messages_to_admin_messages_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_order_item_date"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE cajuia_order_items
  SET created_at = (SELECT created_at FROM cajuia_orders WHERE id = NEW.order_id)
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_order_item_date"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_item_op_generation"("p_item_id" "uuid", "p_is_generated" boolean, "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id UUID;
    v_item_ref TEXT;
BEGIN
    -- Atualiza a flag no item específico
    UPDATE public.order_items
    SET is_op_generated = p_is_generated
    WHERE id = p_item_id
    RETURNING order_id, stamp_ref INTO v_order_id, v_item_ref;

    -- Adiciona um log da ação
    INSERT INTO public.order_logs (order_id, profile_id, log_type, description)
    VALUES (v_order_id, p_profile_id, 'COMMENT',
            'Item "' || v_item_ref || '" foi ' ||
            CASE WHEN p_is_generated THEN '"verificado" para geração de OP.' ELSE '"desmarcado" para geração de OP.' END
           );
END;
$$;


ALTER FUNCTION "public"."toggle_item_op_generation"("p_item_id" "uuid", "p_is_generated" boolean, "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_cajuia_auto_post_sale"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Chama a função contábil passando o ID da nova venda
    -- Envolvemos em um bloco BEGIN/EXCEPTION para que erros contábeis (ex: falta de config)
    -- NÃO travem a venda no PDV. O erro é logado, mas a venda passa.
    BEGIN
        PERFORM public.cajuia_post_sale_to_ledger(NEW.id);
    EXCEPTION WHEN OTHERS THEN
        -- Opcional: Logar erro em uma tabela de auditoria cajuia_logs se quiser
        RAISE WARNING 'Falha ao gerar contabilidade automática para venda %: %', NEW.id, SQLERRM;
    END;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trg_cajuia_auto_post_sale"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."unlock_orders_with_sufficient_stock"() RETURNS TABLE("unlocked_order_id" "uuid", "items_unlocked_count" integer)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    order_to_check RECORD;
    all_items_have_stock BOOLEAN;
    unlocked_count INT;
BEGIN
    -- 1. Encontra todos os pedidos distintos que possuem pelo menos um item marcado com 'has_insufficient_stock'.
    FOR order_to_check IN
        SELECT DISTINCT order_id
        FROM public.order_items
        WHERE has_insufficient_stock = TRUE
    LOOP
        -- 2. Para cada um desses pedidos, verifica se o estoque disponível para TODOS os seus tecidos é 0 ou maior.
        --    Esta é a LÓGICA CORRIGIDA.
        SELECT bool_and(COALESCE(s.available_meters, 0) >= 0)
        INTO all_items_have_stock
        FROM public.order_items oi
        LEFT JOIN public.stock s ON oi.fabric_type = s.fabric_type
        WHERE oi.order_id = order_to_check.order_id;

        -- 3. Se (e somente se) todos os tecidos do pedido tiverem estoque não-negativo...
        IF all_items_have_stock THEN
            -- ...então atualiza APENAS a flag 'has_insufficient_stock' para FALSE.
            -- O status atual do item não é tocado.
            WITH unlocked_items AS (
                UPDATE public.order_items
                SET has_insufficient_stock = FALSE
                WHERE order_id = order_to_check.order_id AND has_insufficient_stock = TRUE
                RETURNING 1
            )
            SELECT COUNT(*) INTO unlocked_count FROM unlocked_items;

            -- 4. Prepara a linha de resultado e a adiciona ao conjunto de retorno da função.
            unlocked_order_id := order_to_check.order_id;
            items_unlocked_count := unlocked_count;
            RETURN NEXT;
        END IF;
    END LOOP;

    -- Finaliza a função.
    RETURN;
END;
$$;


ALTER FUNCTION "public"."unlock_orders_with_sufficient_stock"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_app_tasks_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_app_tasks_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_client_credit"("client_id" "uuid", "amount" numeric) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.customers_mj
  SET credit_used = COALESCE(credit_used, 0) + amount
  WHERE id = client_id;
END;
$$;


ALTER FUNCTION "public"."update_client_credit"("client_id" "uuid", "amount" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_item_stamp_ref"("p_item_id" "uuid", "p_new_ref" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.order_items
    SET stamp_ref = p_new_ref
    WHERE id = p_item_id;
END;
$$;


ALTER FUNCTION "public"."update_item_stamp_ref"("p_item_id" "uuid", "p_new_ref" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_last_read"("p_channel_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE public.channel_members
    SET last_read_at = NOW()
    WHERE channel_id = p_channel_id AND profile_id = auth.uid();
END;
$$;


ALTER FUNCTION "public"."update_last_read"("p_channel_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_member_role"("p_channel_id" bigint, "p_target_user_id" "uuid", "p_new_role" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_user_id uuid;
  is_admin boolean;
  current_user_name text;
  target_user_name text;
  role_name text;
BEGIN
  current_user_id := auth.uid();
  
  SELECT current_user_id = ANY(admin_ids) INTO is_admin FROM public.channels WHERE id = p_channel_id;
  IF NOT is_admin THEN RAISE EXCEPTION 'Acesso negado.'; END IF;

  UPDATE public.channels SET admin_ids = array_remove(admin_ids, p_target_user_id), moderator_ids = array_remove(moderator_ids, p_target_user_id) WHERE id = p_channel_id;

  IF p_new_role = 'admin' THEN
    UPDATE public.channels SET admin_ids = array_append(admin_ids, p_target_user_id) WHERE id = p_channel_id;
    role_name := 'Administrador';
  ELSIF p_new_role = 'mod' THEN
    UPDATE public.channels SET moderator_ids = array_append(moderator_ids, p_target_user_id) WHERE id = p_channel_id;
    role_name := 'Moderador';
  ELSE
    role_name := 'Participante comum';
  END IF;

  SELECT full_name INTO current_user_name FROM public.profiles WHERE id = current_user_id;
  SELECT full_name INTO target_user_name FROM public.profiles WHERE id = p_target_user_id;

  INSERT INTO public.messages (channel_id, profile_id, content, message_type)
  VALUES (p_channel_id, current_user_id, COALESCE(current_user_name, 'Alguém') || ' alterou o cargo de ' || COALESCE(target_user_name, 'um membro') || ' para ' || role_name || '.', 'system');
END;
$$;


ALTER FUNCTION "public"."update_member_role"("p_channel_id" bigint, "p_target_user_id" "uuid", "p_new_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_modified_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_modified_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_order_financial_status"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id uuid;
    v_total_order numeric;
    v_total_paid numeric;
BEGIN
    -- Descobre qual é o ID do pedido afetado (seja criando, pagando ou deletando parcela)
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    -- Se a parcela não estiver atrelada a um pedido, não faz nada
    IF v_order_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Pega o valor total real do pedido
    SELECT total_value INTO v_total_order
    FROM public.orders
    WHERE id = v_order_id;

    -- Se não achar o pedido, aborta
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- SOMA TODAS AS PARCELAS PAGAS DESTE PEDIDO (considerando possíveis descontos)
    SELECT COALESCE(SUM(value - COALESCE(discount, 0)), 0) INTO v_total_paid
    FROM public.finance_receivables
    WHERE order_id = v_order_id AND status = 'pago';

    -- A MÁGICA: Decide o status baseado na matemática exata e atualiza a tabela de pedidos
    IF v_total_paid >= v_total_order AND v_total_order > 0 THEN
        UPDATE public.orders SET financial_status = 'Faturado' WHERE id = v_order_id;
    ELSIF v_total_paid > 0 THEN
        UPDATE public.orders SET financial_status = 'Parcialmente Faturado' WHERE id = v_order_id;
    ELSE
        UPDATE public.orders SET financial_status = 'Em Aberto' WHERE id = v_order_id;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_order_financial_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_order_item_status"("p_item_id" "uuid", "p_new_status" "text", "p_final_art_url" "text", "p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_order_id uuid;
BEGIN
    -- Atualiza o item individual
    UPDATE public.order_items
    SET status = p_new_status, stamp_image_url = COALESCE(p_final_art_url, stamp_image_url)
    WHERE id = p_item_id
    RETURNING order_id INTO v_order_id;

    -- Se o item foi enviado para aprovação, atualiza o pedido principal e notifica
    IF p_new_status = 'customer_approval' THEN
        UPDATE public.orders
        SET status = 'customer_approval'
        WHERE id = v_order_id;

        -- >>> INÍCIO DA CORREÇÃO: Notificar Vendedor <<<
        PERFORM public.notify_seller_for_approval(p_item_id, p_profile_id);
        -- >>> FIM DA CORREÇÃO <<<

    END IF;

    -- Log da ação
    INSERT INTO public.order_logs(order_id, profile_id, log_type, description)
    VALUES (v_order_id, p_profile_id, 'STATUS_CHANGE', 'Status do item ' || (SELECT stamp_ref FROM order_items WHERE id = p_item_id) || ' atualizado para ' || p_new_status);
END;
$$;


ALTER FUNCTION "public"."update_order_item_status"("p_item_id" "uuid", "p_new_status" "text", "p_final_art_url" "text", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_session_risk"("p_session_id" "text", "p_user_id" "uuid", "p_score_add" integer, "p_reason" "text", "p_context" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_current_score INTEGER;
    v_new_score INTEGER;
    v_current_status public.access_status_enum;
    v_new_status public.access_status_enum;
    v_new_flag public.risk_flag_enum;
    v_blocked_until TIMESTAMP WITH TIME ZONE;
    v_profile_id UUID;
BEGIN
    -- Busca ou cria o perfil da sessão
    SELECT id, risk_score, access_status 
    INTO v_profile_id, v_current_score, v_current_status
    FROM public.security_profiles 
    WHERE session_id = p_session_id;

    IF v_profile_id IS NULL THEN
        INSERT INTO public.security_profiles (session_id, user_id, current_context)
        VALUES (p_session_id, p_user_id, p_context)
        RETURNING id, risk_score, access_status 
        INTO v_profile_id, v_current_score, v_current_status;
    END IF;

    -- Se já está bloqueado, não faz nada além de retornar o status
    IF v_current_status = 'blocked' THEN
        RETURN jsonb_build_object(
            'success', true, 
            'access_status', 'blocked', 
            'risk_score', v_current_score
        );
    END IF;

    -- Calcula nova pontuação
    v_new_score := v_current_score + p_score_add;
    
    -- Se o incremento for negativo (ações humanas como clicar), garantimos que o score não fique menor que zero
    IF v_new_score < 0 THEN
        v_new_score := 0;
    END IF;

    -- Avalia as Flags e Status baseado no novo score
    v_new_status := v_current_status;
    v_new_flag := 'none';
    v_blocked_until := NULL;

    IF v_new_score >= 100 THEN
        v_new_flag := 'high';
        v_new_status := 'blocked';
        v_blocked_until := now() + INTERVAL '30 minutes';
    ELSIF v_new_score >= 70 THEN
        v_new_flag := 'high';
        v_new_status := 'revalidation_required';
    ELSIF v_new_score >= 40 THEN
        v_new_flag := 'medium';
    ELSIF v_new_score >= 20 THEN
        v_new_flag := 'low';
    END IF;

    -- Atualiza o perfil no banco
    UPDATE public.security_profiles
    SET 
        risk_score = v_new_score,
        risk_flag = v_new_flag,
        access_status = v_new_status,
        blocked_until = v_blocked_until,
        risk_reason = COALESCE(p_reason, risk_reason),
        current_context = p_context,
        last_activity_at = now(),
        updated_at = now(),
        user_id = COALESCE(user_id, p_user_id) -- Atualiza o user_id se ele logar no meio da sessão
    WHERE id = v_profile_id;

    -- Retorna o estado atualizado para a store do frontend reagir imediatamente
    RETURN jsonb_build_object(
        'success', true,
        'risk_score', v_new_score,
        'risk_flag', v_new_flag,
        'access_status', v_new_status,
        'blocked_until', v_blocked_until
    );
END;
$$;


ALTER FUNCTION "public"."update_session_risk"("p_session_id" "text", "p_user_id" "uuid", "p_score_add" integer, "p_reason" "text", "p_context" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_stock_batches_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_stock_batches_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_stock_quantity"("p_stock_id_to_update" "uuid", "p_quantity_to_add" numeric) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    stock_row RECORD;
BEGIN
    -- Tenta bloquear a linha específica do estoque.
    -- Se estiver bloqueada por outra transação, SKIP LOCKED faz com que a gente não espere.
    SELECT *
    INTO stock_row
    FROM public.stock
    WHERE id = p_stock_id_to_update
    FOR UPDATE SKIP LOCKED;

    -- Se a linha não foi encontrada ou estava bloqueada, stock_row será nulo.
    IF stock_row IS NULL THEN
        RAISE EXCEPTION 'Não foi possível atualizar o estoque para este item no momento. Ele está sendo usado por outro processo. Tente novamente em alguns segundos.';
    END IF;

    -- Se a linha foi bloqueada com sucesso, prossiga com a atualização.
    UPDATE public.stock
    SET available_meters = available_meters + p_quantity_to_add
    WHERE id = p_stock_id_to_update;

END;
$$;


ALTER FUNCTION "public"."update_stock_quantity"("p_stock_id_to_update" "uuid", "p_quantity_to_add" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_time_tracking_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_time_tracking_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
   NEW.updated_at = now(); 
   RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_presence"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO public.user_presences (user_id, last_seen, status)
    VALUES (NEW.id, NOW(), 'online')
    ON CONFLICT (user_id)
    DO UPDATE SET last_seen = NOW(), status = 'online';
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user_presence"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_premium_access"("p_email" "text", "p_code" "text", "p_context" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_lead_id uuid;
  v_temp_code text;
  v_expires_at timestamptz;
  v_auth_context jsonb;
  v_login_count int;
  v_score integer := 0;
  v_new_session_token text;
BEGIN
  -- Busca 100% compatível com o parser do Supabase (Sem SELECT INTO)
  v_lead_id := (SELECT id FROM public.public_leads WHERE email = p_email LIMIT 1);
  v_temp_code := (SELECT temp_auth_code FROM public.public_leads WHERE email = p_email LIMIT 1);
  v_expires_at := (SELECT temp_auth_expires_at FROM public.public_leads WHERE email = p_email LIMIT 1);
  v_auth_context := (SELECT authorized_context FROM public.public_leads WHERE email = p_email LIMIT 1);
  v_login_count := (SELECT login_count FROM public.public_leads WHERE email = p_email LIMIT 1);
  
  IF v_lead_id IS NULL OR v_temp_code != p_code OR v_expires_at < now() THEN
    INSERT INTO public.premium_access_events (user_email, event_type, reason, metadata_json)
    VALUES (p_email, 'temp_code_validation_fail', 'Invalid or Expired Code', p_context);
    RAISE EXCEPTION 'Chave inválida ou expirada.';
  END IF;

  -- Avalia o contexto: É o mesmo PC e IP do primeiro acesso?
  IF v_auth_context IS NOT NULL AND v_auth_context::text != '{}'::text THEN
    IF (p_context->>'ip') != (v_auth_context->>'ip') THEN v_score := v_score + 30; END IF;
    IF (p_context->>'user_agent') != (v_auth_context->>'user_agent') THEN v_score := v_score + 25; END IF;
    IF (p_context->>'fingerprint') != (v_auth_context->>'fingerprint') THEN v_score := v_score + 40; END IF;
  ELSE
    -- Primeiro login com a chave nova: vincula o dispositivo atual como oficial
    UPDATE public.public_leads SET authorized_context = p_context WHERE id = v_lead_id;
  END IF;

  -- QUEIMA IMEDIATA DA CHAVE NA PRIMEIRA TENTATIVA COM DIVERGÊNCIA
  IF v_score >= 50 THEN
    UPDATE public.public_leads 
    SET access_status = 'blocked', risk_flag = 'high', blocked_reason = 'Divergência Crítica de Rede/Dispositivo', blocked_at = now(), temp_auth_code = null
    WHERE id = v_lead_id;
    
    INSERT INTO public.premium_access_events (lead_id, user_email, event_type, risk_score, metadata_json)
    VALUES (v_lead_id, p_email, 'suspicious_access_detected', v_score, p_context);
    
    RAISE EXCEPTION 'ACESSO BLOQUEADO: Mudança drástica de dispositivo detectada.';
    
  ELSIF v_score >= 21 AND v_score < 50 THEN
    UPDATE public.public_leads 
    SET access_status = 'revalidation_required', risk_flag = 'medium', temp_auth_code = null
    WHERE id = v_lead_id;
    
    INSERT INTO public.premium_access_events (lead_id, user_email, event_type, risk_score, metadata_json)
    VALUES (v_lead_id, p_email, 'revalidation_required', v_score, p_context);
    
    RAISE EXCEPTION 'REVALIDAÇÃO NECESSÁRIA: Mudança de rede (ex: VPN) detectada. Solicite nova chave para este IP.';
  END IF;

  -- ACESSO APROVADO: Mesmo IP/PC. A chave NÃO é queimada e continua valendo até a hora de expirar.
  v_new_session_token := gen_random_uuid()::text;
  
  UPDATE public.premium_sessions SET is_valid = false WHERE lead_id = v_lead_id;
  INSERT INTO public.premium_sessions (lead_id, session_token, device_fingerprint, ip_address, expires_at)
  VALUES (v_lead_id, v_new_session_token, p_context->>'fingerprint', p_context->>'ip', now() + interval '30 days');

  UPDATE public.public_leads 
  SET access_status = 'active', 
      risk_flag = 'none', 
      login_count = COALESCE(v_login_count, 0) + 1, 
      last_ip = p_context->>'ip'
  WHERE id = v_lead_id;

  INSERT INTO public.premium_access_events (lead_id, user_email, event_type, risk_score, metadata_json)
  VALUES (v_lead_id, p_email, 'premium_access_granted', v_score, p_context);

  RETURN jsonb_build_object('status', 'success', 'session_token', v_new_session_token);
END;
$$;


ALTER FUNCTION "public"."validate_premium_access"("p_email" "text", "p_code" "text", "p_context" "jsonb") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_channel_members" (
    "channel_id" bigint NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_channel_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_channels" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "name" "text",
    "description" "text",
    "created_by" "uuid",
    "icon" "text",
    "color" "text",
    "icon_image_url" "text",
    "type" "text" DEFAULT 'group'::"text" NOT NULL,
    "is_private_dm" boolean DEFAULT false,
    "dm_participant_ids" "uuid"[],
    "is_deleted" boolean DEFAULT false,
    "deleted_at" timestamp with time zone,
    "is_locked" boolean DEFAULT false
);


ALTER TABLE "public"."admin_channels" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_messages" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "content" "text",
    "profile_id" "uuid",
    "channel_id" bigint,
    "is_deleted" boolean DEFAULT false,
    "is_edited" boolean DEFAULT false,
    "original_content" "text",
    "deleted_at" timestamp with time zone,
    "edited_at" timestamp with time zone,
    "message_type" "text",
    "target_users" "uuid"[]
);


ALTER TABLE "public"."admin_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "username" "text",
    "full_name" "text",
    "avatar_url" "text",
    "role" "public"."user_role" DEFAULT 'user'::"public"."user_role" NOT NULL,
    "store_id" "uuid",
    "allowed_regions" "text"[],
    "vhsys_access_token" "text",
    "vhsys_secret_access_token" "text",
    "gestao_click_id" bigint,
    "assistant_thread_id" "text",
    "has_accepted_terms" boolean DEFAULT false NOT NULL,
    "can_access_crm" boolean DEFAULT false,
    "email" "text",
    "can_move_cash" boolean DEFAULT true,
    "is_active" boolean DEFAULT true,
    "security_pin" "text" DEFAULT '0000'::"text",
    "commission_percentage" numeric DEFAULT 0,
    "permissions" "text"[] DEFAULT '{}'::"text"[],
    "chat_wallpaper_url" "text",
    "employee_id" "uuid",
    "company_id" "uuid",
    "custom_role_id" "uuid",
    "read_only_permissions" "text"[] DEFAULT '{}'::"text"[],
    "delete_permissions" "text"[] DEFAULT '{}'::"text"[]
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."gestao_click_id" IS 'ID correspondente ao vendedor no sistema Gestão Click.';



COMMENT ON COLUMN "public"."profiles"."commission_percentage" IS 'Porcentagem de comissão do vendedor utilizada para cálculos financeiros';



CREATE OR REPLACE VIEW "public"."admin_orders_view" AS
 SELECT "o"."id",
    "o"."status",
    "o"."customer_name",
    "o"."details",
    "o"."quantity_meters",
    "o"."store_id",
    "o"."designer_id",
    "o"."production_date",
    "o"."created_by",
    "o"."created_at",
    "o"."updated_at",
    "o"."value",
    "creator"."full_name" AS "creator_name",
    "designer"."full_name" AS "designer_name"
   FROM (("public"."orders" "o"
     LEFT JOIN "public"."profiles" "creator" ON (("o"."created_by" = "creator"."id")))
     LEFT JOIN "public"."profiles" "designer" ON (("o"."designer_id" = "designer"."id")));


ALTER VIEW "public"."admin_orders_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" character varying(255) NOT NULL,
    "description" "text",
    "status" character varying(50) DEFAULT 'pendente'::character varying NOT NULL,
    "priority" character varying(50) DEFAULT 'media'::character varying NOT NULL,
    "due_date" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "assigned_to" "uuid",
    "created_by" "uuid",
    "is_immutable" boolean DEFAULT false,
    "requires_alert" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."app_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "action_type" "text" NOT NULL,
    "target_id" "text",
    "ip_address" "text" NOT NULL,
    "city" "text",
    "region" "text",
    "isp" "text",
    "user_agent" "text",
    "device_fingerprint" "text",
    "payload" "jsonb",
    "audit_hash" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "session_id" "uuid",
    "auth_event_id" "uuid",
    "request_headers" "jsonb",
    "risk_score" integer DEFAULT 0,
    "latitude" numeric(10,8),
    "longitude" numeric(11,8),
    "previous_log_hash" "text"
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "url" "text" NOT NULL,
    "mime_type" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."builder_assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid",
    "old_data" "jsonb",
    "new_data" "jsonb",
    "ip_address" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."builder_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_menus" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "handle" "text" NOT NULL,
    "name" "text" NOT NULL,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."builder_menus" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_page_versions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "page_id" "uuid",
    "version_number" integer NOT NULL,
    "status" "text" NOT NULL,
    "schema" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "published_at" timestamp with time zone,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "builder_page_versions_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'published'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."builder_page_versions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_pages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "title" "text" NOT NULL,
    "page_type" "text" DEFAULT 'standard'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."builder_pages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."builder_themes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "global_settings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_active" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."builder_themes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_accounting_configs" (
    "key" "text" NOT NULL,
    "account_id" "uuid",
    "description" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_accounting_configs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "nature" "public"."cajuia_account_nature" NOT NULL,
    "parent_id" "uuid",
    "is_synthetic" boolean DEFAULT false,
    "is_system_default" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_bank_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "initial_balance" numeric(10,2) DEFAULT 0,
    "current_balance" numeric(10,2) DEFAULT 0,
    "is_active" boolean DEFAULT true,
    CONSTRAINT "cajuia_bank_accounts_type_check" CHECK (("type" = ANY (ARRAY['wallet'::"text", 'bank'::"text", 'gateway'::"text", 'safe'::"text"])))
);


ALTER TABLE "public"."cajuia_bank_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_bank_statements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "account_id" "uuid" NOT NULL,
    "file_name" "text" NOT NULL,
    "period_start" "date",
    "period_end" "date",
    "imported_at" timestamp with time zone DEFAULT "now"(),
    "imported_by" "uuid"
);


ALTER TABLE "public"."cajuia_bank_statements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_bank_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "statement_id" "uuid",
    "transaction_date" "date" NOT NULL,
    "amount" numeric NOT NULL,
    "description" "text",
    "fitid" "text",
    "memo" "text",
    "is_reconciled" boolean DEFAULT false,
    "matched_entry_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_bank_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_cash_movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "description" "text",
    "order_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "cajuia_cash_movements_type_check" CHECK (("type" = ANY (ARRAY['opening'::"text", 'sale_cash'::"text", 'supply'::"text", 'bleed'::"text", 'closing'::"text"])))
);


ALTER TABLE "public"."cajuia_cash_movements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_cash_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "opened_at" timestamp with time zone DEFAULT "now"(),
    "closed_at" timestamp with time zone,
    "initial_balance" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "final_balance_system" numeric(10,2),
    "final_balance_user" numeric(10,2),
    "difference" numeric(10,2),
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "notes" "text",
    "store_id" "uuid",
    CONSTRAINT "cajuia_cash_sessions_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."cajuia_cash_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" DEFAULT 'category'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "cajuia_categories_type_check" CHECK (("type" = ANY (ARRAY['gender'::"text", 'category'::"text"])))
);


ALTER TABLE "public"."cajuia_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_clients" (
    "id" bigint NOT NULL,
    "external_id" bigint,
    "name" "text" NOT NULL,
    "cpf_cnpj" "text",
    "email" "text",
    "phone" "text",
    "city" "text",
    "state" "text",
    "blocked" boolean DEFAULT false,
    "last_purchase_date" timestamp with time zone,
    "total_purchases" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_clients" OWNER TO "postgres";


ALTER TABLE "public"."cajuia_clients" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."cajuia_clients_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."cajuia_corte_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "company_id" "uuid",
    "stock_item_id" "uuid",
    "nome_peca" "text" NOT NULL,
    "quantidade" numeric DEFAULT 1 NOT NULL,
    "status" "text" DEFAULT 'Corte'::"text" NOT NULL,
    "observacoes" "text",
    "user_id" "uuid",
    "lote" "text",
    "cor" "text",
    "tamanho" "text",
    "prioridade" "text" DEFAULT 'Normal'::"text",
    "data_prevista" "date",
    "ordem_producao" "text"
);


ALTER TABLE "public"."cajuia_corte_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_cost_centers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_cost_centers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_dashboard_layouts" (
    "user_id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "layout" "jsonb" NOT NULL
);


ALTER TABLE "public"."cajuia_dashboard_layouts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_expense_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "name" "text" NOT NULL,
    "type" "text" DEFAULT 'fixed'::"text",
    "is_active" boolean DEFAULT true,
    CONSTRAINT "cajuia_expense_categories_type_check" CHECK (("type" = ANY (ARRAY['fixed'::"text", 'variable'::"text"])))
);


ALTER TABLE "public"."cajuia_expense_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_fiscal_docs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "order_id" "uuid",
    "doc_type" "text" NOT NULL,
    "doc_number" integer NOT NULL,
    "series" integer NOT NULL,
    "status" "text" NOT NULL,
    "access_key" "text",
    "protocol" "text",
    "xml_url" "text",
    "pdf_url" "text",
    "error_message" "text",
    "rejection_code" "text",
    CONSTRAINT "cajuia_fiscal_docs_doc_type_check" CHECK (("doc_type" = ANY (ARRAY['NFCe'::"text", 'NFe'::"text"]))),
    CONSTRAINT "cajuia_fiscal_docs_status_check" CHECK (("status" = ANY (ARRAY['AUTHORIZED'::"text", 'REJECTED'::"text", 'CANCELED'::"text", 'PROCESSING'::"text"])))
);


ALTER TABLE "public"."cajuia_fiscal_docs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_journal_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "transaction_date" "date" NOT NULL,
    "description" "text" NOT NULL,
    "origin_type" "text",
    "origin_id" "uuid",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_draft" boolean DEFAULT false
);


ALTER TABLE "public"."cajuia_journal_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_journal_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "journal_entry_id" "uuid" NOT NULL,
    "account_id" "uuid" NOT NULL,
    "cost_center_id" "uuid",
    "debit" numeric DEFAULT 0,
    "credit" numeric DEFAULT 0,
    "history" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "check_debit_or_credit" CHECK (((("debit" > (0)::numeric) AND ("credit" = (0)::numeric)) OR (("credit" > (0)::numeric) AND ("debit" = (0)::numeric))))
);


ALTER TABLE "public"."cajuia_journal_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_order_drafts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "client_name" "text",
    "total_value" numeric,
    "content" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "customer_name" "text",
    "order_number" bigint,
    "item_count" integer,
    "draft_data" "jsonb"
);


ALTER TABLE "public"."cajuia_order_drafts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_order_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "product_id" "uuid",
    "product_name" "text" NOT NULL,
    "quantity" integer NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "total_price" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_order_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."cajuia_order_number_seq"
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."cajuia_order_number_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_number" integer DEFAULT "nextval"('"public"."cajuia_order_number_seq"'::"regclass") NOT NULL,
    "vendedor_id" "uuid",
    "customer_id" "text",
    "customer_name" "text" NOT NULL,
    "total_value" numeric(10,2) NOT NULL,
    "payment_method" "text",
    "gestaoclick_sale_id" "text",
    "sales_order_pdf_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_payables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "description" "text",
    "supplier_name" "text",
    "amount" numeric(10,2),
    "due_date" "date",
    "competency_date" "date" DEFAULT CURRENT_DATE,
    "payment_date" timestamp with time zone,
    "status" "text" DEFAULT 'PENDING'::"text",
    "notes" "text",
    "category_id" "uuid",
    "bank_account_id" "uuid"
);


ALTER TABLE "public"."cajuia_payables" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_permissions" (
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_price_lists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_price_lists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_product_prices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "price_list_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "price" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajuia_product_prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "sku" "text",
    "price" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "photo_url" "text",
    "quantity_in_stock" integer DEFAULT 0 NOT NULL,
    "gestaoclick_id" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "category" "text",
    "gender" "text",
    "barcode" "text",
    "ncm" "text",
    "cfop" "text" DEFAULT '5102'::"text",
    "cest" "text",
    "origin" "text" DEFAULT '0'::"text",
    "csosn" "text" DEFAULT '102'::"text",
    "cst_pis" "text" DEFAULT '99'::"text",
    "cst_cofins" "text" DEFAULT '99'::"text",
    "tax_percentage" numeric(5,2) DEFAULT 0
);


ALTER TABLE "public"."cajuia_products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_receivables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "description" "text",
    "customer_name" "text",
    "gross_value" numeric(10,2),
    "net_value" numeric(10,2),
    "due_date" "date",
    "competency_date" "date" DEFAULT CURRENT_DATE,
    "payment_date" timestamp with time zone,
    "status" "text" DEFAULT 'PENDING'::"text",
    "notes" "text",
    "payment_method" "text"
);


ALTER TABLE "public"."cajuia_receivables" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_tax_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "environment" "text" DEFAULT 'homologation'::"text" NOT NULL,
    "certificate_url" "text",
    "certificate_password" "text",
    "certificate_expiration" "date",
    "csc_token" "text",
    "csc_id" "text",
    "next_nfc_number" integer DEFAULT 1,
    "next_nfe_number" integer DEFAULT 1,
    "series" integer DEFAULT 1,
    "default_cfop_nfc" "text" DEFAULT '5102'::"text",
    "default_ncm" "text",
    "default_csosn" "text" DEFAULT '102'::"text",
    CONSTRAINT "cajuia_tax_settings_environment_check" CHECK (("environment" = ANY (ARRAY['production'::"text", 'homologation'::"text"])))
);


ALTER TABLE "public"."cajuia_tax_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajuia_widgets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "title" "text" NOT NULL,
    "type" "text" NOT NULL,
    "config" "jsonb" NOT NULL,
    "default_cols" integer DEFAULT 3,
    "is_system" boolean DEFAULT false,
    CONSTRAINT "cajuia_widgets_type_check" CHECK (("type" = ANY (ARRAY['kpi'::"text", 'chart'::"text", 'list'::"text"])))
);


ALTER TABLE "public"."cajuia_widgets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_banners" (
    "id" integer NOT NULL,
    "tag" "text",
    "title" "text" NOT NULL,
    "subtitle" "text",
    "cta_text" "text",
    "image_url" "text" NOT NULL,
    "active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."catalog_banners" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."catalog_banners_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."catalog_banners_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."catalog_banners_id_seq" OWNED BY "public"."catalog_banners"."id";



CREATE TABLE IF NOT EXISTS "public"."catalog_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "main_image_url" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."catalog_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_collections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "cover_image_url" "text",
    "is_active" boolean DEFAULT true,
    "published_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."catalog_collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_fabrics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "base_price" numeric(10,2) NOT NULL,
    "price_tiers" "jsonb" DEFAULT '[]'::"jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "unit_of_measure" "text" DEFAULT 'm'::"text",
    "unit" "text",
    "image_url" "text"
);


ALTER TABLE "public"."catalog_fabrics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_mockups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "base_image_url" "text" NOT NULL,
    "mask_url" "text",
    "shadow_overlay_url" "text",
    "config" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."catalog_mockups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_settings" (
    "id" integer DEFAULT 1 NOT NULL,
    "theme_config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."catalog_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_stamp_collections" (
    "stamp_id" "uuid" NOT NULL,
    "collection_id" "uuid" NOT NULL,
    "position" integer DEFAULT 0
);


ALTER TABLE "public"."catalog_stamp_collections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_stamp_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stamp_id" "uuid",
    "media_url" "text" NOT NULL,
    "media_type" "text" DEFAULT 'image'::"text",
    "position" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."catalog_stamp_media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_stamp_mockups" (
    "stamp_id" "uuid" NOT NULL,
    "mockup_id" "uuid" NOT NULL,
    "position" integer DEFAULT 0
);


ALTER TABLE "public"."catalog_stamp_mockups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_stamp_tags" (
    "stamp_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL
);


ALTER TABLE "public"."catalog_stamp_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalog_stamps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "ref_code" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "category_id" "uuid",
    "main_image_url" "text" NOT NULL,
    "seamless_pattern_url" "text",
    "dominant_color" "text",
    "is_new" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "seo_title" "text",
    "seo_description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "digital_price" numeric(10,2) DEFAULT 599.00,
    "digital_file_url" "text",
    "stamp_type" "text" DEFAULT 'Corrida'::"text",
    "width_cm" numeric(10,2) DEFAULT 50.00,
    "height_cm" numeric(10,2) DEFAULT 50.00
);


ALTER TABLE "public"."catalog_stamps" OWNER TO "postgres";


COMMENT ON COLUMN "public"."catalog_stamps"."stamp_type" IS 'Define se a estampa é Corrida ou Barrado.';



CREATE TABLE IF NOT EXISTS "public"."catalog_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."catalog_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."channel_members" (
    "channel_id" bigint NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_read_at" timestamp with time zone,
    "is_pinned" boolean DEFAULT false,
    "is_muted" boolean DEFAULT false,
    "role" "text" DEFAULT 'member'::"text"
);


ALTER TABLE "public"."channel_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."channels" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_by" "uuid" NOT NULL,
    "icon" "text" DEFAULT 'mdi-pound'::"text" NOT NULL,
    "color" "text" DEFAULT 'grey'::"text" NOT NULL,
    "icon_image_url" "text",
    "is_deleted" boolean DEFAULT false,
    "deleted_at" timestamp with time zone,
    "is_private_dm" boolean DEFAULT false,
    "type" "text" DEFAULT 'group'::"text" NOT NULL,
    "dm_participant_ids" "uuid"[],
    "is_group" boolean DEFAULT false,
    "is_restricted" boolean DEFAULT false,
    "admin_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "moderator_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "is_locked" boolean DEFAULT false
);


ALTER TABLE "public"."channels" OWNER TO "postgres";


ALTER TABLE "public"."channels" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."channels_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."client_design_deliveries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_email" "text" NOT NULL,
    "design_request_id" "text" NOT NULL,
    "file_url" "text" NOT NULL,
    "delivered_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone NOT NULL,
    "force_visible" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."client_design_deliveries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."client_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "transaction_type" character varying(50) NOT NULL,
    "reference_id" "uuid",
    "amount" numeric(10,2) NOT NULL,
    "status" character varying(50) DEFAULT 'approved'::character varying,
    "payment_method" character varying(50) DEFAULT 'PIX'::character varying,
    "description" "text",
    "receipt_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."client_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commerce_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "document" "text",
    "phone" "text" NOT NULL,
    "location" "text",
    "email" "text",
    "session_token" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."commerce_leads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commerce_moodboard_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "moodboard_id" "uuid",
    "stamp_id" "uuid",
    "mockup_id" "uuid",
    "mockup_state" "jsonb",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."commerce_moodboard_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commerce_moodboards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "session_token" "text",
    "title" "text" DEFAULT 'Meu Moodboard'::"text",
    "status" "text" DEFAULT 'active'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."commerce_moodboards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commerce_quote_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "moodboard_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "message" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."commerce_quote_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "name" "text" NOT NULL,
    "trade_name" "text",
    "cnpj" "text" NOT NULL,
    "ie" "text",
    "address" "jsonb" DEFAULT '{}'::"jsonb",
    "environment" "text" DEFAULT 'homologacao'::"text",
    "nfe_series" integer DEFAULT 1,
    "nfe_next_number" integer DEFAULT 1,
    "certificate_validity" timestamp with time zone,
    "certificate_thumbprint" "text",
    "active" boolean DEFAULT true,
    "crt" integer DEFAULT 1,
    "zip_code" "text",
    "street" "text",
    "number" "text",
    "district" "text",
    "city" "text",
    "uf" "text",
    "email" "text",
    "nfe_environment" "text" DEFAULT 'homologacao'::"text",
    "nfe_version" "text" DEFAULT '4.00'::"text",
    "nfe_info_complementar" "text",
    "subtract_icms_pis_cofins" boolean DEFAULT false,
    "simple_danfe" boolean DEFAULT false,
    "nfce_next_number" integer DEFAULT 1,
    "nfce_series" integer DEFAULT 1,
    "nfce_token" "text",
    "nfce_csc" "text",
    "nfce_environment" "text" DEFAULT 'homologacao'::"text",
    "nfce_version" "text" DEFAULT '4.00'::"text",
    "nfce_info_complementar" "text",
    "nfse_next_rps" integer DEFAULT 1,
    "nfse_rps_series" "text",
    "nfse_tax_regime" "text",
    "nfse_operation_nature" "text",
    "nfse_environment" "text" DEFAULT 'homologacao'::"text",
    "nfse_layout" "text" DEFAULT 'nacional'::"text",
    "nfse_info_complementar" "text",
    "xml_auth_cnpjs" "text",
    "default_cst_csosn" character varying(5) DEFAULT '102'::character varying,
    "certificate_url" "text",
    "certificate_password" "text",
    "logo_url" "text",
    "cte_environment" character varying(20) DEFAULT 'homologacao'::character varying,
    "cte_series" integer DEFAULT 1,
    "cte_next_number" integer DEFAULT 1,
    "cte_info_complementar" "text",
    "im" character varying(50),
    "complemento" character varying(150)
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


COMMENT ON COLUMN "public"."companies"."certificate_validity" IS 'Data de vencimento do certificado digital';



COMMENT ON COLUMN "public"."companies"."default_cst_csosn" IS 'CST ou CSOSN padrão utilizado nas emissões de NFe desta empresa';



COMMENT ON COLUMN "public"."companies"."certificate_url" IS 'Caminho ou URL do arquivo .pfx do certificado no Supabase Storage';



COMMENT ON COLUMN "public"."companies"."certificate_password" IS 'Senha do certificado digital A1';



COMMENT ON COLUMN "public"."companies"."logo_url" IS 'URL pública da logo da empresa armazenada no Supabase Storage';



CREATE TABLE IF NOT EXISTS "public"."company_installed_apps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "app_id" character varying NOT NULL,
    "installed_at" timestamp with time zone DEFAULT "now"(),
    "installed_by" "uuid"
);


ALTER TABLE "public"."company_installed_apps" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."company_integrations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid",
    "provider" character varying NOT NULL,
    "is_active" boolean DEFAULT false,
    "credentials" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."company_integrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm_active_alerts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "lead_id" "uuid",
    "alert_type" "text" NOT NULL,
    "message" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."crm_active_alerts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm_automations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "is_active" boolean DEFAULT true,
    "trigger_event" "text" NOT NULL,
    "condition_value" "jsonb",
    "action_type" "text" NOT NULL,
    "action_payload" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."crm_automations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm_kanban_columns" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "title" "text" NOT NULL,
    "bg_class" "text" DEFAULT 'bg-grey-lighten-5'::"text",
    "accent_color" "text" DEFAULT '#1976D2'::"text",
    "order_index" integer DEFAULT 10,
    "wip_limit" integer DEFAULT 0,
    "win_probability" integer DEFAULT 0,
    "rotting_days" integer DEFAULT 3
);


ALTER TABLE "public"."crm_kanban_columns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm_lead_history" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "lead_id" "uuid",
    "action_type" "text" NOT NULL,
    "description" "text",
    "old_value" "text",
    "new_value" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."crm_lead_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crm_workflows" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "is_active" boolean DEFAULT true,
    "nodes" "jsonb" DEFAULT '[]'::"jsonb",
    "edges" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."crm_workflows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cte_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "data_emissao" timestamp with time zone DEFAULT "now"(),
    "id_nuvem" "text",
    "chave" character varying(44),
    "numero" bigint,
    "status_sefaz" character varying(50) DEFAULT 'pendente'::character varying,
    "status_processamento" character varying(50),
    "source" character varying(20) DEFAULT 'emitted'::character varying,
    "ambiente" character varying(20) DEFAULT 'producao'::character varying,
    "natureza_operacao" character varying(255),
    "cfop" integer,
    "emitente_nome" character varying(255),
    "cnpj_emitente" character varying(20),
    "tomador_role" integer,
    "tomador_nome" character varying(255),
    "uf_inicio" character varying(2),
    "municipio_inicio_nome" character varying(255),
    "municipio_inicio_ibge" character varying(10),
    "uf_fim" character varying(2),
    "municipio_fim_nome" character varying(255),
    "municipio_fim_ibge" character varying(10),
    "valor_frete" numeric(15,2),
    "valor_mercadoria" numeric(15,2),
    "produto_predominante" character varying(255),
    "peso_bruto" numeric(15,3),
    "qtd_volumes" integer,
    "rntrc" character varying(20),
    "veiculo_placa" character varying(10),
    "informacoes_adicionais" "text",
    "chaves_nfe" "jsonb",
    "remetente" "jsonb",
    "destinatario" "jsonb",
    "nsu" bigint DEFAULT 0,
    "cnpj_destinatario" "text",
    "company_id" "uuid"
);


ALTER TABLE "public"."cte_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."custom_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_supervisor" boolean DEFAULT false,
    "permissions" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "read_only_permissions" "text"[] DEFAULT '{}'::"text"[],
    "delete_permissions" "text"[] DEFAULT '{}'::"text"[]
);


ALTER TABLE "public"."custom_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."customer_tags" (
    "id" bigint NOT NULL,
    "customer_name" "text" NOT NULL,
    "tag" "text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."customer_tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."customer_tags" IS 'Tags para segmentação e marcação de clientes.';



ALTER TABLE "public"."customer_tags" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."customer_tags_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "document" "text",
    "phone" "text",
    "email" "text",
    "address" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "last_order_date" "date",
    "total_spent" numeric(10,2) DEFAULT 0,
    "created_by" "uuid"
);


ALTER TABLE "public"."customers" OWNER TO "postgres";


COMMENT ON TABLE "public"."customers" IS 'Tabela centralizada de clientes para o CRM.';



CREATE TABLE IF NOT EXISTS "public"."customers_mj" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" bigint,
    "tipo_pessoa" character varying(20),
    "nome" "text",
    "razao_social" character varying(255),
    "cnpj" character varying(20),
    "ie" character varying(50),
    "im" character varying(50),
    "cpf" character varying(20),
    "rg" character varying(20),
    "nascimento" "date",
    "situacao" character varying(50),
    "telefone" character varying(50),
    "celular" character varying(50),
    "fax" character varying(50),
    "email" character varying(255),
    "cep" character varying(20),
    "endereco" "text",
    "bairro" character varying(100),
    "complemento" character varying(255),
    "cidade" character varying(100),
    "estado" character varying(2),
    "vendedor_responsavel" character varying(100),
    "observacoes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "credit_limit" numeric(15,2) DEFAULT 0.00,
    "credit_used" numeric(15,2) DEFAULT 0.00,
    "nome_fantasia" "text",
    "numero" "text",
    "vendedor_responsavel_id" "uuid",
    "acquisition_channel" "text",
    "acquisition_subchannel" "text",
    "visit_proof_url" "text",
    "avatar_url" "text",
    "person_type" "text" DEFAULT 'PF'::"text",
    "company_size" "text"
);


ALTER TABLE "public"."customers_mj" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_stock_reports" (
    "id" bigint NOT NULL,
    "report_date" "date" NOT NULL,
    "initial_stock" "jsonb" NOT NULL,
    "final_stock" "jsonb" NOT NULL,
    "movements" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."daily_stock_reports" OWNER TO "postgres";


ALTER TABLE "public"."daily_stock_reports" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."daily_stock_reports_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."debug_payload_log" (
    "id" integer NOT NULL,
    "received_at" timestamp with time zone DEFAULT "now"(),
    "payload" "jsonb"
);


ALTER TABLE "public"."debug_payload_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."debug_payload_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."debug_payload_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."debug_payload_log_id_seq" OWNED BY "public"."debug_payload_log"."id";



CREATE TABLE IF NOT EXISTS "public"."design_assignment_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "item_id" "uuid" NOT NULL,
    "order_id" "uuid",
    "item_type" "text" NOT NULL,
    "item_name" "text" NOT NULL,
    "designer_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."design_assignment_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."design_kanban_columns" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "title" "text" NOT NULL,
    "tag_name" "text" NOT NULL,
    "bg_class" "text" DEFAULT 'bg-grey-lighten-5'::"text",
    "dot_color" "text" DEFAULT 'bg-primary'::"text",
    "chip_color" "text" DEFAULT 'primary'::"text",
    "accent_color" "text" DEFAULT '#1976D2'::"text",
    "order_index" integer DEFAULT 0,
    "allowed_roles" "uuid"[] DEFAULT '{}'::"uuid"[],
    "available_in_new_order" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."design_kanban_columns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."design_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pending_order_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "customer_name" "text",
    "fabric_type" "text",
    "stamp_ref" "text",
    "stamp_image_url" "text",
    "notes" "text",
    "design_tag" "text",
    "status" "text" DEFAULT 'design_pending_stock'::"text" NOT NULL
);


ALTER TABLE "public"."design_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."design_rejection_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "item_id" "uuid" NOT NULL,
    "item_type" "text" NOT NULL,
    "leader_id" "uuid",
    "reason" "text" NOT NULL,
    "rejected_image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."design_rejection_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."design_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "general_notes" "text",
    "created_by" "uuid" DEFAULT "auth"."uid"(),
    "store_id" "uuid",
    "status" "text" DEFAULT 'design_pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "design_items" "jsonb",
    "attachments" "text"[],
    "dev_code" "text",
    "final_art_url" "text",
    "new_stamp_id" bigint,
    "designer_id" "uuid",
    "additional_arts" "text"[] DEFAULT '{}'::"text"[],
    "request_type" "text" DEFAULT 'development'::"text",
    "design_tag" character varying(100) DEFAULT 'Desenvolvimento'::character varying
);


ALTER TABLE "public"."design_requests" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."design_requests_dev_code_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."design_requests_dev_code_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."design_user_permissions" (
    "user_id" "uuid" NOT NULL,
    "requires_leader_approval" boolean DEFAULT false,
    "can_approve_for_leader" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "is_leader" boolean DEFAULT false,
    "ui_x" numeric DEFAULT 0,
    "ui_y" numeric DEFAULT 0,
    "is_blocked" boolean DEFAULT false
);


ALTER TABLE "public"."design_user_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."dfe_entries" (
    "chave" "text" NOT NULL,
    "cnpj_destinatario" "text" NOT NULL,
    "emitente_nome" "text",
    "emitente_cnpj" "text",
    "valor" numeric DEFAULT 0,
    "data_emissao" timestamp with time zone,
    "situacao_sefaz" "text",
    "xml_link" "text",
    "status_processamento" "text" DEFAULT 'pendente'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "situacao_manifestacao" "text" DEFAULT 'SemManifestacao'::"text",
    "nsu" bigint
);


ALTER TABLE "public"."dfe_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."digital_purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_email" "text" NOT NULL,
    "stamp_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "price_paid" numeric(10,2) NOT NULL,
    "file_url" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "purchased_at" timestamp with time zone
);


ALTER TABLE "public"."digital_purchases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "provider" "text" NOT NULL,
    "email_address" "text" NOT NULL,
    "access_token" "text" NOT NULL,
    "refresh_token" "text" NOT NULL,
    "token_expires_at" timestamp with time zone,
    "sync_cursor" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "email_accounts_provider_check" CHECK (("provider" = ANY (ARRAY['gmail'::"text", 'outlook'::"text"])))
);


ALTER TABLE "public"."email_accounts" OWNER TO "postgres";


COMMENT ON TABLE "public"."email_accounts" IS 'Armazena as credenciais OAuth das contas de e-mail (Gmail/Outlook) conectadas pelos usuários.';



CREATE TABLE IF NOT EXISTS "public"."emails" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "direction" "text",
    "from_address" "text" NOT NULL,
    "to_address" "text" NOT NULL,
    "subject" "text",
    "html_body" "text",
    "text_body" "text",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "message_id" "text",
    "thread_id" "text",
    "cc_address" "text",
    "account_id" "uuid",
    "has_attachments" boolean DEFAULT false,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "emails_direction_check" CHECK (("direction" = ANY (ARRAY['inbound'::"text", 'outbound'::"text"])))
);


ALTER TABLE "public"."emails" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employees_mj" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" bigint,
    "nome" "text",
    "email" "text",
    "telefone" "text",
    "celular" "text",
    "cargo" "text",
    "cpf" "text",
    "situacao" "text" DEFAULT 'Ativo'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "avatar_url" "text",
    "rg" "text",
    "birth_date" "date",
    "marital_status" "text" DEFAULT 'Solteiro(a)'::"text",
    "contract_type" "text" DEFAULT 'CLT'::"text",
    "admission_date" "date",
    "work_hours" "text",
    "departments" "jsonb" DEFAULT '[]'::"jsonb",
    "salary_base" numeric DEFAULT 0,
    "salary_additional" numeric DEFAULT 0,
    "tax_percentage" numeric DEFAULT 40,
    "supervisor_id" "text",
    "emergency_contact" "jsonb" DEFAULT '{"name": "", "phone": "", "relation": ""}'::"jsonb",
    "bank_info" "jsonb" DEFAULT '{"pix": "", "bank": "", "type": "Corrente", "agency": "", "account": ""}'::"jsonb",
    "work_schedule" "jsonb" DEFAULT '{}'::"jsonb",
    "dependents" "jsonb" DEFAULT '[]'::"jsonb",
    "career_history" "jsonb" DEFAULT '[]'::"jsonb",
    "benefits" "jsonb" DEFAULT '[]'::"jsonb",
    "documents" "jsonb" DEFAULT '[]'::"jsonb",
    "equipments" "jsonb" DEFAULT '[]'::"jsonb",
    "status" "text" DEFAULT 'ativo'::"text",
    "user_id" "uuid",
    "face_descriptors" "jsonb" DEFAULT '[]'::"jsonb",
    "role" "text",
    "hourly_divisor" numeric DEFAULT 220,
    "department" "text",
    "company_id" "uuid"
);


ALTER TABLE "public"."employees_mj" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."erp_orders_cache" (
    "id" bigint NOT NULL,
    "codigo" "text",
    "cliente_nome" "text",
    "vendedor_nome" "text",
    "data" "date",
    "valor_total" numeric,
    "raw_data" "jsonb",
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."erp_orders_cache" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "bank_name" "text",
    "agency" "text",
    "account_number" "text",
    "initial_balance" numeric(15,2) DEFAULT 0.00,
    "current_balance" numeric(15,2) DEFAULT 0.00,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "balance_date" "date" DEFAULT CURRENT_DATE
);


ALTER TABLE "public"."finance_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "action_type" "text" NOT NULL,
    "entity_id" "uuid",
    "user_id" "uuid",
    "ip_address" "text",
    "payload" "jsonb",
    "old_value" "jsonb"
);


ALTER TABLE "public"."finance_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_bank_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "agency" "text",
    "account_number" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."finance_bank_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_chart_of_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "parent_id" "uuid",
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "is_group" boolean DEFAULT false,
    "active" boolean DEFAULT true,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "finance_chart_of_accounts_type_check" CHECK (("type" = ANY (ARRAY['Receita'::"text", 'Despesa'::"text", 'Ativo'::"text", 'Passivo'::"text"])))
);


ALTER TABLE "public"."finance_chart_of_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_charts_of_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "type" "text" DEFAULT 'receita'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."finance_charts_of_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_cost_centers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."finance_cost_centers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_invoice_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receivable_id" "uuid" NOT NULL,
    "paid_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "paid_value" numeric(10,2) NOT NULL,
    "bank_account_id" "uuid" NOT NULL,
    "proof_url" "text",
    "notes" "text",
    "processed_by" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."finance_invoice_payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_payables" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "description" "text",
    "value" numeric,
    "due_date" "date",
    "status" "text" DEFAULT 'pendente'::"text",
    "category" "text",
    "competence_date" "date" DEFAULT "now"(),
    "installment_number" integer DEFAULT 1,
    "total_installments" integer DEFAULT 1,
    "recurrence_id" "uuid",
    "origin_nfe_key" "text",
    "origin_fleet_id" "uuid",
    "notes" "text",
    "competency_date" "date",
    "payment_date" "date",
    "payment_method" "text",
    "cost_center" "text",
    "entity_name" "text",
    "bank_account_id" "uuid",
    "payment_method_id" "uuid",
    "chart_of_accounts_id" "uuid",
    "cost_center_id" "uuid",
    "supplier_id" "uuid",
    "discount" numeric(10,2) DEFAULT 0.00,
    "gestao_click_id" bigint,
    "company_id" "uuid",
    "attachment_url" "text",
    "attachments" "text"[] DEFAULT '{}'::"text"[],
    "reconciliation_status" "text" DEFAULT 'PENDING'::"text",
    "bank_fitid" "text"
);


ALTER TABLE "public"."finance_payables" OWNER TO "postgres";


ALTER TABLE "public"."finance_payables" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."finance_payables_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."finance_payment_methods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "gestao_click_id" "text",
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."finance_payment_methods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_receivable_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receivable_id" "uuid" NOT NULL,
    "paid_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "paid_value" numeric(10,2) NOT NULL,
    "bank_account_id" "uuid" NOT NULL,
    "proof_url" "text",
    "notes" "text",
    "processed_by" "uuid" DEFAULT "auth"."uid"() NOT NULL
);


ALTER TABLE "public"."finance_receivable_payments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_receivables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "description" "text",
    "value" numeric(10,2) NOT NULL,
    "due_date" "date" NOT NULL,
    "competence_date" "date" DEFAULT "now"() NOT NULL,
    "status" "public"."finance_status" DEFAULT 'em_aberto'::"public"."finance_status" NOT NULL,
    "order_id" "uuid",
    "customer_id" "uuid",
    "chart_of_accounts_id" "uuid",
    "cost_center_id" "uuid",
    "bank_account_id" "uuid",
    "payment_method_id" "uuid",
    "paid_value" numeric(10,2) DEFAULT 0.00,
    "interest" numeric(10,2) DEFAULT 0.00,
    "discount" numeric(10,2) DEFAULT 0.00,
    "paid_at" timestamp with time zone,
    "created_by" "uuid" DEFAULT "auth"."uid"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "notes" "text",
    "receipt_date" "date",
    "billing_items_snapshot" "jsonb" DEFAULT '[]'::"jsonb",
    "competency_date" "date",
    "payment_date" "date",
    "payment_method" "text",
    "cost_center" "text",
    "entity_name" "text",
    "gestao_click_id" bigint,
    "company_id" "uuid",
    "attachments" "text"[] DEFAULT '{}'::"text"[],
    "boleto_url" "text",
    "boleto_barcode" "text",
    "boleto_digitable" "text",
    "external_id" "text",
    "reconciliation_status" "text" DEFAULT 'PENDING'::"text",
    "bank_fitid" "text",
    "store_sale_id" "uuid",
    "order_number" integer,
    "source_type" character varying(50)
);


ALTER TABLE "public"."finance_receivables" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "account_id" "uuid",
    "description" "text" NOT NULL,
    "amount" numeric(15,2) NOT NULL,
    "type" "text",
    "category" "text",
    "transaction_date" "date" DEFAULT CURRENT_DATE,
    "status" "text" DEFAULT 'COMPLETED'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "bank_fitid" "text",
    "reconciliation_status" "text" DEFAULT 'PENDING'::"text",
    "external_id" "text",
    CONSTRAINT "finance_transactions_type_check" CHECK (("type" = ANY (ARRAY['INCOME'::"text", 'EXPENSE'::"text", 'TRANSFER'::"text"])))
);


ALTER TABLE "public"."finance_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fiscal_companies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "name" "text" NOT NULL,
    "cnpj" "text" NOT NULL,
    "ie" "text",
    "crt" "text" DEFAULT '1'::"text",
    "email" "text",
    "zip_code" "text",
    "street" "text",
    "number" "text",
    "district" "text",
    "city" "text",
    "uf" "text",
    "active" boolean DEFAULT true
);


ALTER TABLE "public"."fiscal_companies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fiscal_tax_rules" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid",
    "uf" character varying(2) NOT NULL,
    "cfop" character varying(10) NOT NULL,
    "cst_csosn" character varying(10) NOT NULL,
    "icms_aliquot" numeric DEFAULT 0,
    "icms_base_reduction" numeric DEFAULT 0,
    "pis_aliquot" numeric DEFAULT 0,
    "cofins_aliquot" numeric DEFAULT 0,
    "ipi_aliquot" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."fiscal_tax_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fleet_refuelings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "request_number" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "vehicle_id" "uuid",
    "driver_name" "text" NOT NULL,
    "requested_amount" numeric(10,2),
    "approved_amount" numeric(10,2),
    "fuel_type" "text",
    "liters" numeric(10,2),
    "km_at_refuel" integer,
    "receipt_url" "text",
    "status" "text" DEFAULT 'pendente'::"text",
    "notes" "text"
);


ALTER TABLE "public"."fleet_refuelings" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."fleet_refuelings_request_number_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."fleet_refuelings_request_number_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."fleet_refuelings_request_number_seq" OWNED BY "public"."fleet_refuelings"."request_number";



CREATE TABLE IF NOT EXISTS "public"."fleet_vehicles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "plate" "text" NOT NULL,
    "model" "text" NOT NULL,
    "brand" "text" NOT NULL,
    "year" integer,
    "color" "text",
    "driver_name" "text",
    "company_owner" "text",
    "photo_url" "text",
    "status" "text" DEFAULT 'ativo'::"text",
    "km_current" integer DEFAULT 0,
    "company_id" "uuid",
    "renavam" character varying(50),
    "chassis" character varying(50),
    "registration_state" character varying(2) DEFAULT 'SP'::character varying,
    "driver_cpf" character varying(20),
    "driver_cnh" character varying(20),
    "driver_cnh_category" character varying(5),
    "driver_cnh_expiry" "date",
    "driver_photo_url" "text",
    "attachments" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."fleet_vehicles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."fleet_vehicles"."company_id" IS 'Referência à tabela de empresas (companies) para o proprietário do veículo';



COMMENT ON COLUMN "public"."fleet_vehicles"."attachments" IS 'Armazena o fichário de documentos do veículo em formato JSON Array [{name, url, category, uploaded_at}]';



CREATE TABLE IF NOT EXISTS "public"."label_presets" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "settings" "jsonb" NOT NULL,
    "image_url" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."label_presets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marketplace_cart" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "stamp_id" "uuid",
    "quantity" double precision DEFAULT 1,
    "fabric_id" "uuid",
    "is_physical" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."marketplace_cart" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marketplace_customers" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "name" "text",
    "document" "text",
    "phone" "text",
    "location" "text",
    "discovery_source" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."marketplace_customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marketplace_favorite_folders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."marketplace_favorite_folders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marketplace_favorite_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "stamp_id" "uuid",
    "folder_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."marketplace_favorite_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "content" "text" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "channel_id" bigint NOT NULL,
    "is_deleted" boolean DEFAULT false,
    "is_edited" boolean DEFAULT false,
    "original_content" "text",
    "deleted_at" timestamp with time zone,
    "edited_at" timestamp with time zone,
    "message_type" "text" DEFAULT '''user'''::"text",
    "reply_to_message_id" bigint,
    "target_users" "uuid"[],
    "caption" "text",
    "status" "text" DEFAULT 'sent'::"text",
    "reactions" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


ALTER TABLE "public"."messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."mj_cash_extraction_audit" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "order_ref" character varying(255),
    "amount" numeric(10,2) NOT NULL,
    "method_name" character varying(100),
    "is_cash" boolean,
    "origin" character varying(100) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "raw_payload" "jsonb"
);


ALTER TABLE "public"."mj_cash_extraction_audit" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mj_cash_movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "order_id" "uuid",
    "type" "text" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "source_table" "text",
    "source_id" "uuid",
    "note" "text",
    CONSTRAINT "mj_cash_movements_type_check" CHECK (("type" = ANY (ARRAY['sale_cash'::"text", 'supply'::"text", 'bleed'::"text", 'opening'::"text", 'in_audit'::"text", 'out_audit'::"text"])))
);


ALTER TABLE "public"."mj_cash_movements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mj_cash_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "store_id" "uuid",
    "initial_balance" numeric(10,2) DEFAULT 0,
    "final_balance_system" numeric(10,2) DEFAULT 0,
    "final_balance_user" numeric(10,2) DEFAULT 0,
    "difference" numeric(10,2) DEFAULT 0,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "notes" "text",
    "opened_at" timestamp with time zone DEFAULT "now"(),
    "closed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_breakdown" "jsonb"
);


ALTER TABLE "public"."mj_cash_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mj_expense_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."mj_expense_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mj_payables" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "description" "text" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "due_date" "date" NOT NULL,
    "supplier_name" "text",
    "status" character varying(20) DEFAULT 'PENDING'::character varying,
    "nfe_key" character varying(44),
    "nfe_xml_url" "text",
    "category_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."mj_payables" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."nfce_outbound" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "emitente_cnpj" "text",
    "numero" bigint,
    "serie" integer,
    "valor_total" numeric,
    "status" "text",
    "chave" "text",
    "pdf_link" "text",
    "xml_link" "text",
    "destinatario_nome" "text",
    "ambiente" "text",
    "retorno_sefaz" "jsonb"
);


ALTER TABLE "public"."nfce_outbound" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."nfe_outbound" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "emitente_cnpj" "text" NOT NULL,
    "destinatario_nome" "text",
    "valor_total" numeric,
    "status" "text",
    "chave" "text",
    "numero" "text",
    "xml_link" "text",
    "pdf_link" "text",
    "retorno_sefaz" "jsonb",
    "draft_data" "jsonb",
    "modelo" character varying(5) DEFAULT '55'::character varying,
    "qr_code_url" "text"
);


ALTER TABLE "public"."nfe_outbound" OWNER TO "postgres";


COMMENT ON COLUMN "public"."nfe_outbound"."modelo" IS 'Modelo do documento: 55 (NFe) ou 65 (NFCe)';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipient_id" "uuid",
    "sender_id" "uuid",
    "content" "text" NOT NULL,
    "redirect_url" "text",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "type" "text"
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."operation_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "module_key" "text" NOT NULL,
    "severity" "text" DEFAULT 'info'::"text",
    "actor_type" "text" NOT NULL,
    "actor_id" "uuid",
    "actor_name" "text",
    "automation_reason" "text",
    "action_type" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "entity_label" "text",
    "didactic_message" "text" NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb",
    "before_data" "jsonb",
    "after_data" "jsonb",
    "session_id" "uuid",
    "correlation_id" "text"
);


ALTER TABLE "public"."operation_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_drafts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "draft_data" "jsonb" NOT NULL,
    "reserved_order_number" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."order_drafts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_groups" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."order_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "fabric_type" "text" NOT NULL,
    "stamp_ref" "text",
    "quantity_meters" numeric NOT NULL,
    "stamp_image_url" "text",
    "design_tag" "text" NOT NULL,
    "status" "text" DEFAULT 'design_pending'::"text" NOT NULL,
    "is_op_generated" boolean DEFAULT false NOT NULL,
    "details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "notes" "text",
    "op_number" integer,
    "billed_quantity" numeric(10,2),
    "quantity_unit" numeric,
    "unit_of_measure" "text",
    "rendimento" numeric,
    "has_insufficient_stock" boolean DEFAULT false NOT NULL,
    "total_value_items" numeric(10,2) DEFAULT 0,
    "gestao_click_product_id" "text",
    "is_exclusive" boolean DEFAULT false,
    "print_started_at" timestamp with time zone,
    "print_ended_at" timestamp with time zone,
    "excluded_from_invoice" boolean DEFAULT false,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "reprint_info" "jsonb" DEFAULT '{"count": 0, "history": [], "total_lost_meters": 0}'::"jsonb"
);


ALTER TABLE "public"."order_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."order_items" IS 'Armazena os itens individuais (filhos) de um pedido principal (pai).';



COMMENT ON COLUMN "public"."order_items"."billed_quantity" IS 'Metragem final faturada após a produção, considerando perdas ou ganhos.';



CREATE TABLE IF NOT EXISTS "public"."order_logs" (
    "id" bigint NOT NULL,
    "order_id" "uuid" NOT NULL,
    "profile_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "log_type" "text" NOT NULL,
    "description" "text",
    "metadata" "jsonb"
);


ALTER TABLE "public"."order_logs" OWNER TO "postgres";


ALTER TABLE "public"."order_logs" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."order_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE SEQUENCE IF NOT EXISTS "public"."order_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER SEQUENCE "public"."order_number_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."order_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "payment_type" "text" NOT NULL,
    "payment_method" "text",
    "payment_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "receipt_url" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "order_payments_amount_check" CHECK (("amount" > (0)::numeric))
);


ALTER TABLE "public"."order_payments" OWNER TO "postgres";


COMMENT ON TABLE "public"."order_payments" IS 'Registra pagamentos individuais (sinal, restante) para um pedido.';



COMMENT ON COLUMN "public"."order_payments"."order_id" IS 'O pedido ao qual este pagamento está vinculado.';



COMMENT ON COLUMN "public"."order_payments"."amount" IS 'O valor deste pagamento específico.';



COMMENT ON COLUMN "public"."order_payments"."payment_type" IS 'O tipo de pagamento (Sinal, Restante).';



COMMENT ON COLUMN "public"."order_payments"."receipt_url" IS 'URL do arquivo de comprovante (anexado) no Storage.';



CREATE SEQUENCE IF NOT EXISTS "public"."orders_order_number_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."orders_order_number_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."orders_order_number_seq" OWNED BY "public"."orders"."order_number";



CREATE TABLE IF NOT EXISTS "public"."pcp_workflows" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "version" "text" DEFAULT '1.0.0'::"text" NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "nodes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "edges" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pcp_workflows" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pdv_price_lists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pdv_price_lists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pdv_product_prices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "price_list_id" "uuid",
    "product_id" "uuid",
    "price" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pdv_product_prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pending_stock_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status" "text" DEFAULT 'awaiting_stock'::"text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "released_at" timestamp with time zone,
    "original_payload" "jsonb" NOT NULL,
    "required_stock_items" "jsonb",
    "target_order_id" "uuid",
    "store_id" "uuid",
    "error_message" "text"
);


ALTER TABLE "public"."pending_stock_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pilot_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "stamp_id" "uuid",
    "fabric_id" "uuid",
    "status" character varying(50) DEFAULT 'pending_payment'::character varying,
    "payment_id" character varying(255),
    "payment_status" character varying(50) DEFAULT 'pending'::character varying,
    "pix_qr_code" "text",
    "pix_qr_code_base64" "text",
    "amount" numeric(10,2) NOT NULL,
    "quantity_meters" numeric(10,2) DEFAULT 1.0,
    "representative_request" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "customer_mj_id" "uuid",
    "custom_stamp_url" "text",
    "design_tag" "text" DEFAULT 'Desenvolvimento'::"text",
    "designer_id" "uuid",
    "group_id" "uuid" DEFAULT "gen_random_uuid"(),
    "notes" "text"
);


ALTER TABLE "public"."pilot_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pilot_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "pilot_id" "uuid",
    "action" character varying(50) NOT NULL,
    "amount" numeric(15,2) DEFAULT 0.00,
    "created_by" "uuid",
    "details" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."pilot_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."premium_access_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "user_email" "text" NOT NULL,
    "event_type" "text" NOT NULL,
    "ip" "text",
    "user_agent" "text",
    "device_fingerprint" "text",
    "risk_score" integer DEFAULT 0,
    "reason" "text",
    "metadata_json" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."premium_access_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."premium_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "session_token" "text" NOT NULL,
    "device_fingerprint" "text" NOT NULL,
    "ip_address" "text",
    "is_valid" boolean DEFAULT true,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."premium_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."price_list" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "composition" "text",
    "grammage" "text",
    "unit" "text" DEFAULT 'metro'::"text" NOT NULL,
    "price_se" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "price_ne" numeric(10,2) DEFAULT 0.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "price_se_cash" numeric,
    "price_se_term" numeric,
    "price_ne_cash" numeric,
    "price_ne_term" numeric,
    "rendimento" "text",
    "width" "text",
    "width_length" "text",
    "rolo" "text"
);


ALTER TABLE "public"."price_list" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."product_details" (
    "id" bigint NOT NULL,
    "gestao_click_id" "text" NOT NULL,
    "fabric_type" "text" NOT NULL,
    "unit_of_measure" "text" DEFAULT 'metro'::"text" NOT NULL,
    "rendimento" numeric,
    "meters_per_roll" numeric,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."product_details" OWNER TO "postgres";


COMMENT ON TABLE "public"."product_details" IS 'Tabela para armazenar configurações de unidade de medida e rendimento para produtos do Gestão Click.';



COMMENT ON COLUMN "public"."product_details"."gestao_click_id" IS 'ID do produto correspondente no Gestão Click.';



COMMENT ON COLUMN "public"."product_details"."unit_of_measure" IS 'Unidade de medida (metro ou kg).';



COMMENT ON COLUMN "public"."product_details"."rendimento" IS 'Metros por KG (usado para conversão).';



COMMENT ON COLUMN "public"."product_details"."meters_per_roll" IS 'Metragem padrão por rolo (opcional).';



ALTER TABLE "public"."product_details" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."product_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."production_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "order_item_id" "uuid",
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."production_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."production_machines" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."production_machines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."production_schedule" (
    "id" bigint NOT NULL,
    "order_id" "uuid" NOT NULL,
    "scheduled_date" "date" NOT NULL,
    "quantity_meters" numeric NOT NULL,
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "delivery_confirmed_at" timestamp with time zone,
    "actual_delivery_date" "date",
    "order_item_id" "uuid"
);


ALTER TABLE "public"."production_schedule" OWNER TO "postgres";


COMMENT ON COLUMN "public"."production_schedule"."delivery_confirmed_at" IS 'Timestamp de quando a entrega foi confirmada pelo responsável.';



ALTER TABLE "public"."production_schedule" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."production_schedule_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."productivity_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "term" "text" NOT NULL,
    "classification" "text" DEFAULT 'neutro'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "user_id" "uuid"
);


ALTER TABLE "public"."productivity_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "current_stock" numeric DEFAULT 0 NOT NULL,
    "unit_of_measure" "text" DEFAULT 'metro'::"text" NOT NULL,
    "rendimento" numeric,
    "last_synced_at" timestamp with time zone
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."profiles_with_email" AS
 SELECT "p"."id",
    "p"."updated_at",
    "p"."created_at",
    "p"."username",
    "p"."full_name",
    "p"."avatar_url",
    "p"."role",
    "p"."store_id",
    "p"."allowed_regions",
    "p"."vhsys_access_token",
    "p"."vhsys_secret_access_token",
    "p"."gestao_click_id",
    "u"."email"
   FROM ("public"."profiles" "p"
     JOIN "auth"."users" "u" ON (("p"."id" = "u"."id")));


ALTER VIEW "public"."profiles_with_email" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_columns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "position" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."project_columns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."public_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "document" "text",
    "phone" "text",
    "location" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "discovery_source" "text",
    "design_access_status" "text" DEFAULT 'none'::"text",
    "wishlist" "uuid"[] DEFAULT '{}'::"uuid"[],
    "instagram" "text",
    "account_status" "text" DEFAULT 'pending'::"text",
    "temp_auth_code" "text",
    "temp_auth_expires_at" timestamp with time zone,
    "auth_code_requested" boolean DEFAULT false NOT NULL,
    "last_ip" "text",
    "last_region" "text",
    "suspicious_ip" boolean DEFAULT false NOT NULL,
    "login_count" integer DEFAULT 0 NOT NULL,
    "request_count" integer DEFAULT 0 NOT NULL,
    "access_status" "text" DEFAULT 'inactive'::"text",
    "risk_flag" "text" DEFAULT 'none'::"text",
    "blocked_reason" "text",
    "blocked_at" timestamp with time zone,
    "blocked_by" "uuid",
    "authorized_context" "jsonb" DEFAULT '{}'::"jsonb",
    "kanban_column_id" "uuid",
    "vip_interest" "text",
    "vip_pilot_meterage" "text",
    "vip_operation_size" "text",
    CONSTRAINT "check_design_access_status" CHECK (("design_access_status" = ANY (ARRAY['none'::"text", 'pending'::"text", 'granted'::"text"]))),
    CONSTRAINT "public_leads_access_status_check" CHECK (("access_status" = ANY (ARRAY['inactive'::"text", 'pending_validation'::"text", 'active'::"text", 'revalidation_required'::"text", 'blocked'::"text"]))),
    CONSTRAINT "public_leads_risk_flag_check" CHECK (("risk_flag" = ANY (ARRAY['none'::"text", 'low'::"text", 'medium'::"text", 'high'::"text"])))
);


ALTER TABLE "public"."public_leads" OWNER TO "postgres";


COMMENT ON COLUMN "public"."public_leads"."wishlist" IS 'Array de UUIDs das estampas favoritadas pelo cliente.';



COMMENT ON COLUMN "public"."public_leads"."account_status" IS 'Status de aprovação do cliente (pending, approved, rejected)';



CREATE TABLE IF NOT EXISTS "public"."purchase_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_id" "uuid",
    "product_id" "uuid",
    "description" "text" NOT NULL,
    "quantity" numeric(10,2) DEFAULT 1 NOT NULL,
    "unit_price" numeric(15,2) DEFAULT 0 NOT NULL,
    "total_price" numeric(15,2) DEFAULT 0 NOT NULL,
    "unit_of_measure" character varying(20) DEFAULT 'un'::character varying,
    "service_id" "uuid"
);


ALTER TABLE "public"."purchase_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_type" "text" NOT NULL,
    "supplier_id" "uuid",
    "entity_name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "value" numeric(15,2) DEFAULT 0 NOT NULL,
    "delivery_date" "date" NOT NULL,
    "status" "text" DEFAULT 'pendente'::"text",
    "company_id" "uuid",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "attachments" "jsonb" DEFAULT '[]'::"jsonb",
    "move_stock" boolean DEFAULT true,
    "order_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "supplier_name" "text",
    "total_value" numeric(15,2) DEFAULT 0,
    "payment_details" "jsonb" DEFAULT '{}'::"jsonb",
    "chart_of_accounts_id" "uuid",
    "created_by_name" "text",
    "updated_at" timestamp with time zone,
    "updated_by_name" "text",
    "production_status" "text" DEFAULT 'indefinido'::"text",
    "audit_log" "jsonb" DEFAULT '[]'::"jsonb",
    "is_quotation" boolean DEFAULT false,
    "sequential_code" integer NOT NULL,
    "codigo" integer,
    "origin" character varying(50) DEFAULT 'direct'::character varying,
    "finance_payable_id" bigint,
    CONSTRAINT "purchases_purchase_type_check" CHECK (("purchase_type" = ANY (ARRAY['product'::"text", 'service'::"text"])))
);


ALTER TABLE "public"."purchases" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."purchases_codigo_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."purchases_codigo_seq" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."purchases_product_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."purchases_product_seq" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."purchases_sequential_code_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."purchases_sequential_code_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."purchases_sequential_code_seq" OWNED BY "public"."purchases"."sequential_code";



CREATE SEQUENCE IF NOT EXISTS "public"."purchases_service_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."purchases_service_seq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sales_goals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "seller_id" "uuid" NOT NULL,
    "month" integer NOT NULL,
    "year" integer NOT NULL,
    "goal_value" numeric(12,2) NOT NULL,
    "goal_clients" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."sales_goals" OWNER TO "postgres";


COMMENT ON TABLE "public"."sales_goals" IS 'Metas de vendas mensais para cada vendedor.';



CREATE TABLE IF NOT EXISTS "public"."scheduled_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "original_order_payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'awaiting_stock'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "released_at" timestamp with time zone,
    "released_by" "uuid"
);


ALTER TABLE "public"."scheduled_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."security_events_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "text" NOT NULL,
    "user_id" "uuid",
    "context" "text" NOT NULL,
    "event_type" "text" NOT NULL,
    "art_id" "text",
    "time_on_art" numeric,
    "visible_duration" numeric,
    "scroll_speed" numeric,
    "exposed_count" integer,
    "interaction_count" integer,
    "metadata_json" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."security_events_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."security_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "text" NOT NULL,
    "user_id" "uuid",
    "current_context" "text" DEFAULT 'unknown'::"text",
    "risk_score" integer DEFAULT 0 NOT NULL,
    "risk_flag" "public"."risk_flag_enum" DEFAULT 'none'::"public"."risk_flag_enum" NOT NULL,
    "access_status" "public"."access_status_enum" DEFAULT 'active'::"public"."access_status_enum" NOT NULL,
    "blocked_until" timestamp with time zone,
    "risk_reason" "text",
    "last_activity_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."security_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."seller_activities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "seller_id" "uuid" NOT NULL,
    "customer_name" "text" NOT NULL,
    "activity_type" "text" NOT NULL,
    "activity_date" timestamp with time zone DEFAULT "now"(),
    "latitude" real,
    "longitude" real,
    "notes" "text",
    "attachments" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."seller_activities" OWNER TO "postgres";


COMMENT ON TABLE "public"."seller_activities" IS 'Registros de atividades e check-ins dos vendedores.';



CREATE TABLE IF NOT EXISTS "public"."services_catalog" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "base_price" numeric(10,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."services_catalog" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sre_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "incident_id" "uuid",
    "action_type" "text" NOT NULL,
    "performed_by" "uuid",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sre_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sre_incidents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "module" "text" NOT NULL,
    "severity" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "context_data" "jsonb" DEFAULT '{}'::"jsonb",
    "status" "text" DEFAULT 'open'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "resolved_at" timestamp with time zone,
    "resolved_by" "uuid"
);


ALTER TABLE "public"."sre_incidents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_activity" (
    "id" bigint NOT NULL,
    "user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "application_name" "text",
    "window_title" "text",
    "classification" "text" DEFAULT 'neutro'::"text",
    "path" "text",
    "pid" integer
);


ALTER TABLE "public"."user_activity" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."sre_live_telemetry" AS
 SELECT 'user_activity'::"text" AS "source",
    ("ua"."id")::"text" AS "event_id",
    "ua"."created_at",
    "p"."full_name" AS "user_name",
    'Auditoria de UI'::"text" AS "module",
    ('O usuário acessou a tela: '::"text" || "ua"."window_title") AS "didactic_message",
    "row_to_json"("ua".*) AS "payload"
   FROM ("public"."user_activity" "ua"
     LEFT JOIN "public"."profiles" "p" ON (("ua"."user_id" = "p"."id")))
UNION ALL
 SELECT 'order_logs'::"text" AS "source",
    ("ol"."id")::"text" AS "event_id",
    "ol"."created_at",
    "p"."full_name" AS "user_name",
    'Operação de Venda'::"text" AS "module",
    ('Ação no pedido: '::"text" || "ol"."description") AS "didactic_message",
    "row_to_json"("ol".*) AS "payload"
   FROM ("public"."order_logs" "ol"
     LEFT JOIN "public"."profiles" "p" ON (("ol"."profile_id" = "p"."id")));


ALTER VIEW "public"."sre_live_telemetry" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stamp_folders" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."stamp_folders" OWNER TO "postgres";


ALTER TABLE "public"."stamp_folders" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."stamp_folders_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."stamp_library" (
    "id" bigint NOT NULL,
    "gestao_click_service_id" character varying NOT NULL,
    "name" "text" NOT NULL,
    "image_url" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "folder_id" bigint,
    "is_approved_for_sale" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."stamp_library" OWNER TO "postgres";


COMMENT ON TABLE "public"."stamp_library" IS 'Catálogo de estampas pré-definidas vinculadas a serviços do Gestão Click.';



COMMENT ON COLUMN "public"."stamp_library"."gestao_click_service_id" IS 'ID do serviço correspondente na API do Gestão Click.';



COMMENT ON COLUMN "public"."stamp_library"."image_url" IS 'URL pública da imagem da estampa armazenada no Supabase Storage.';



COMMENT ON COLUMN "public"."stamp_library"."is_approved_for_sale" IS 'Indica se a estampa foi aprovada pelo designer e está visível para a equipe de vendas.';



ALTER TABLE "public"."stamp_library" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."stamp_library_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."stock_batches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stock_id" "uuid" NOT NULL,
    "batch_code" character varying(100) NOT NULL,
    "initial_qty" numeric(15,4) NOT NULL,
    "current_qty" numeric(15,4) NOT NULL,
    "cost_per_unit" numeric(15,4) DEFAULT 0 NOT NULL,
    "supplier_id" "uuid",
    "arrival_date" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."stock_batches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_ledger" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stock_id" "uuid" NOT NULL,
    "batch_id" "uuid",
    "operation_type" character varying(50) NOT NULL,
    "qty_changed" numeric(15,4) NOT NULL,
    "qty_before" numeric(15,4) NOT NULL,
    "qty_after" numeric(15,4) NOT NULL,
    "order_id" "uuid",
    "order_number" character varying(100),
    "client_name" character varying(255),
    "order_items_used" "jsonb",
    "notes" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."stock_ledger" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stock_movements" (
    "id" bigint NOT NULL,
    "product_id" "uuid" NOT NULL,
    "movement_type" "text" NOT NULL,
    "quantity_moved" numeric NOT NULL,
    "old_quantity" numeric NOT NULL,
    "new_quantity" numeric NOT NULL,
    "user_id" "uuid",
    "order_item_id" "uuid",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "lote" "text"
);


ALTER TABLE "public"."stock_movements" OWNER TO "postgres";


ALTER TABLE "public"."stock_movements" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."stock_movements_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."stock_tabs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "label" "text" NOT NULL,
    "cnpj" "text",
    "theme_color" "text" DEFAULT 'teal'::"text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."stock_tabs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "client_email" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "total_amount" numeric DEFAULT 0,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."store_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."store_sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" "text",
    "order_number" "text",
    "customer_name" "text",
    "total_value" numeric DEFAULT 0,
    "discount_value" numeric DEFAULT 0,
    "net_value" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "date_sale" "date",
    "status" "text",
    "payment_status" "text",
    "company_id" "uuid",
    "seller_name" "text",
    "items" "jsonb" DEFAULT '[]'::"jsonb",
    "payments" "jsonb" DEFAULT '[]'::"jsonb",
    "notes" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "seller_id" "uuid",
    "financial_status" "text" DEFAULT 'Pendente'::"text",
    "nfe_number" "text",
    "nfe_key" "text",
    "store_id" "uuid",
    "customer_id" "uuid"
);


ALTER TABLE "public"."store_sales" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."storefront_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "logo_url" "text",
    "hero_title" "text",
    "hero_subtitle" "text",
    "hero_bg_url" "text",
    "parallax_title" "text",
    "parallax_text" "text",
    "parallax_bg_url" "text",
    "maintenance_mode" boolean DEFAULT false,
    "grids_config" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "allow_psd_sales" boolean DEFAULT true,
    "home_blocks" "jsonb" DEFAULT '[]'::"jsonb",
    "welcome_popup_enabled" boolean DEFAULT false,
    "welcome_popup_style" "text" DEFAULT 'classic'::"text",
    "welcome_popup_image" "text"
);


ALTER TABLE "public"."storefront_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "address" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "active" boolean DEFAULT true,
    "cnpj" "text",
    "ie" "text",
    "street" "text",
    "number" "text",
    "complement" "text",
    "neighborhood" "text",
    "city" "text",
    "city_code" "text",
    "state" "text",
    "zip_code" "text",
    "crt" "text" DEFAULT '1'::"text",
    "environment" "text" DEFAULT 'homologacao'::"text",
    "last_nfe_number" integer DEFAULT 0,
    "certificate_expiry" "date",
    "company_id" "uuid",
    "csc_token" "text",
    "csc_id" "text",
    "series" integer DEFAULT 1,
    "settings" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."stores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."suppliers_mj" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "gestao_click_id" bigint,
    "nome" "text",
    "razao_social" "text",
    "cnpj_cpf" "text",
    "email" "text",
    "telefone" "text",
    "celular" "text",
    "cidade" "text",
    "estado" "text",
    "situacao" "text" DEFAULT 'Ativo'::"text",
    "tipo_pessoa" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."suppliers_mj" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "action_type" "text" NOT NULL,
    "details" "text",
    "user_id" "uuid",
    "user_email" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."system_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_events" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "module" character varying(50) NOT NULL,
    "level" character varying(20) NOT NULL,
    "event_name" character varying(100) NOT NULL,
    "message" "text" NOT NULL,
    "user_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "is_resolved" boolean DEFAULT false,
    "resolved_at" timestamp with time zone,
    "resolved_by" "uuid"
);


ALTER TABLE "public"."system_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_settings" (
    "id" integer NOT NULL,
    "require_vip_design" boolean DEFAULT true,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL
);


ALTER TABLE "public"."system_settings" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."system_settings_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."system_settings_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."system_settings_id_seq" OWNED BY "public"."system_settings"."id";



CREATE TABLE IF NOT EXISTS "public"."system_updates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "version" character varying NOT NULL,
    "description" "text" NOT NULL,
    "target_roles" "jsonb" DEFAULT '[]'::"jsonb",
    "target_users" "jsonb" DEFAULT '[]'::"jsonb",
    "reopen_interval_seconds" integer DEFAULT 300,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_updates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "is_completed" boolean DEFAULT false NOT NULL,
    "due_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "priority" "text" DEFAULT 'Média'::"text" NOT NULL,
    "created_by" "uuid",
    "order_id" "uuid",
    "column_id" "uuid",
    "project_id" "uuid",
    "position" integer
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_extension_requests" (
    "id" integer NOT NULL,
    "user_id" "uuid" NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "now"(),
    "duration_minutes" integer NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "approved_until" timestamp with time zone,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    CONSTRAINT "time_extension_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."time_extension_requests" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."time_extension_requests_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."time_extension_requests_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."time_extension_requests_id_seq" OWNED BY "public"."time_extension_requests"."id";



CREATE TABLE IF NOT EXISTS "public"."time_tracking_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "shift_template_id" "uuid",
    "manager" "text",
    "insalubrity_level" integer DEFAULT 0,
    "hazard_pay" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_corrections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "date" "date" NOT NULL,
    "justification" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_corrections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_holidays" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "date" "date" NOT NULL,
    "multiplier" integer DEFAULT 100,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."time_tracking_holidays" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_kiosk_releases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "date" "date" NOT NULL,
    "window_start" time without time zone,
    "window_end" time without time zone,
    "reason" "text",
    "approved" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_kiosk_releases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_kiosk_users" (
    "kiosk_id" "uuid" NOT NULL,
    "employee_id" "uuid" NOT NULL
);


ALTER TABLE "public"."time_tracking_kiosk_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_kiosks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "allowed_ip" "text",
    "lat" numeric(10,6),
    "lng" numeric(10,6),
    "max_radius_meters" integer DEFAULT 50 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."time_tracking_kiosks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "date" "date" NOT NULL,
    "in1" time without time zone,
    "out1" time without time zone,
    "in2" time without time zone,
    "out2" time without time zone,
    "balance_minutes" integer DEFAULT 0,
    "status" "text" DEFAULT 'Regular'::"text",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "punches" "jsonb" DEFAULT '[]'::"jsonb",
    "punch_photos" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."time_tracking_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_overrides" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "date" "date" NOT NULL,
    "start_time" time without time zone,
    "break_start" time without time zone,
    "break_end" time without time zone,
    "end_time" time without time zone,
    "note" "text",
    "label" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_overrides" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_overtime_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "date" "date" NOT NULL,
    "start_time" time without time zone,
    "end_time" time without time zone,
    "reason" "text",
    "manager" "text",
    "status" "text" DEFAULT 'Pendente'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_overtime_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_payroll_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "employee_id" "uuid",
    "title" "text" NOT NULL,
    "category" "text",
    "reference" "text",
    "amount" numeric DEFAULT 0,
    "automatic" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_payroll_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tolerance_minutes" integer DEFAULT 10,
    "default_overtime_rate" integer DEFAULT 50,
    "sunday_overtime_rate" integer DEFAULT 100,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "night_additional_rate" numeric DEFAULT 20,
    "min_meal_break_minutes" integer DEFAULT 60,
    "min_rest_between_shifts_hours" integer DEFAULT 11,
    "max_overtime_per_day_minutes" integer DEFAULT 120,
    "night_start" time without time zone DEFAULT '22:00:00'::time without time zone,
    "night_end" time without time zone DEFAULT '05:00:00'::time without time zone,
    "reduced_night_hour" boolean DEFAULT true,
    "reduced_night_minutes" numeric DEFAULT 52.5,
    "monthly_minimum_wage_base" numeric DEFAULT 1518,
    "kiosk_cooldown_minutes" integer DEFAULT 30
);


ALTER TABLE "public"."time_tracking_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."time_tracking_shift_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "weekly_hours" numeric DEFAULT 44,
    "allow_bank_hours" boolean DEFAULT true,
    "night_shift" boolean DEFAULT false,
    "requires_manager_approval" boolean DEFAULT true,
    "days" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."time_tracking_shift_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_modules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "module_type" "text" NOT NULL,
    "content_url" "text" NOT NULL,
    "module_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "training_modules_module_type_check" CHECK (("module_type" = ANY (ARRAY['video'::"text", 'pdf'::"text", 'image'::"text"])))
);


ALTER TABLE "public"."training_modules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_progress" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "module_id" "uuid" NOT NULL,
    "completed_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."training_progress" OWNER TO "postgres";


ALTER TABLE "public"."training_progress" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."training_progress_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE "public"."user_activity" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."user_activity_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_notification_dismissals" (
    "user_id" "uuid" NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "dismissed_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_notification_dismissals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_preferences" (
    "user_id" "uuid" NOT NULL,
    "settings_version" integer DEFAULT 1 NOT NULL,
    "settings" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()),
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"())
);


ALTER TABLE "public"."user_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_presences" (
    "user_id" "uuid" NOT NULL,
    "last_seen" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text" DEFAULT 'offline'::"text" NOT NULL,
    "current_activity" "text"
);


ALTER TABLE "public"."user_presences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "file_url" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "category" "text" DEFAULT 'Geral'::"text",
    "file_type" "text" DEFAULT 'application/pdf'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_screenshots" (
    "id" integer NOT NULL,
    "user_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "captured_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_screenshots" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."user_screenshots_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."user_screenshots_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."user_screenshots_id_seq" OWNED BY "public"."user_screenshots"."id";



CREATE OR REPLACE VIEW "public"."v_sre_unified_logs" AS
 SELECT ("ol"."id")::"text" AS "event_id",
    "ol"."created_at",
    "p"."full_name" AS "actor_name",
    "ol"."log_type" AS "action_type",
    'Vendas'::"text" AS "module",
    "ol"."description" AS "didactic_message",
    NULL::"jsonb" AS "before_data",
    "ol"."metadata" AS "after_data",
    'order_logs'::"text" AS "source_table"
   FROM ("public"."order_logs" "ol"
     LEFT JOIN "public"."profiles" "p" ON (("ol"."profile_id" = "p"."id")))
UNION ALL
 SELECT ("fal"."id")::"text" AS "event_id",
    "fal"."created_at",
    "p"."full_name" AS "actor_name",
    "fal"."action_type",
    'Financeiro'::"text" AS "module",
    ('Auditoria Financeira no registro: '::"text" || COALESCE(("fal"."entity_id")::"text", 'N/A'::"text")) AS "didactic_message",
    "fal"."old_value" AS "before_data",
    "fal"."payload" AS "after_data",
    'finance_audit_logs'::"text" AS "source_table"
   FROM ("public"."finance_audit_logs" "fal"
     LEFT JOIN "public"."profiles" "p" ON (("fal"."user_id" = "p"."id")))
UNION ALL
 SELECT ("sm"."id")::"text" AS "event_id",
    "sm"."created_at",
    "p"."full_name" AS "actor_name",
    "sm"."movement_type" AS "action_type",
    'Estoque'::"text" AS "module",
    ('Movimentação: '::"text" || "sm"."notes") AS "didactic_message",
    "jsonb_build_object"('quantidade', "sm"."old_quantity") AS "before_data",
    "jsonb_build_object"('quantidade', "sm"."new_quantity") AS "after_data",
    'stock_movements'::"text" AS "source_table"
   FROM ("public"."stock_movements" "sm"
     LEFT JOIN "public"."profiles" "p" ON (("sm"."user_id" = "p"."id")))
UNION ALL
 SELECT ("pl"."id")::"text" AS "event_id",
    "pl"."created_at",
    "p"."full_name" AS "actor_name",
    "pl"."action" AS "action_type",
    'Produção'::"text" AS "module",
    (('Ação na produção (Item: '::"text" || COALESCE(("pl"."order_item_id")::"text", ''::"text")) || ')'::"text") AS "didactic_message",
    NULL::"jsonb" AS "before_data",
    "pl"."metadata" AS "after_data",
    'production_logs'::"text" AS "source_table"
   FROM ("public"."production_logs" "pl"
     LEFT JOIN "public"."profiles" "p" ON (("pl"."user_id" = "p"."id")))
UNION ALL
 SELECT ("oe"."id")::"text" AS "event_id",
    "oe"."created_at",
    "oe"."actor_name",
    "oe"."action_type",
    "oe"."entity_label" AS "module",
    "oe"."didactic_message",
    "oe"."before_data",
    "oe"."after_data",
    'operation_events'::"text" AS "source_table"
   FROM "public"."operation_events" "oe";


ALTER VIEW "public"."v_sre_unified_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wa_conversations" (
    "id" bigint NOT NULL,
    "customer_phone" "text" NOT NULL,
    "customer_name" "text",
    "assigned_to" "uuid",
    "status" "text" DEFAULT 'aberta'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."wa_conversations" OWNER TO "postgres";


COMMENT ON TABLE "public"."wa_conversations" IS 'Armazena as conversas ativas do WhatsApp.';



ALTER TABLE "public"."wa_conversations" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."wa_conversations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."wa_messages" (
    "id" bigint NOT NULL,
    "conversation_id" bigint NOT NULL,
    "content" "text" NOT NULL,
    "message_direction" "text" NOT NULL,
    "sender_profile_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."wa_messages" OWNER TO "postgres";


COMMENT ON TABLE "public"."wa_messages" IS 'Armazena cada mensagem trocada em uma conversa do WhatsApp.';



ALTER TABLE "public"."wa_messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."wa_messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."work_schedules" (
    "id" integer NOT NULL,
    "user_id" "uuid",
    "day_of_week" smallint NOT NULL,
    "start_time" time without time zone NOT NULL,
    "end_time" time without time zone NOT NULL,
    "is_general" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "work_schedules_day_of_week_check" CHECK ((("day_of_week" >= 0) AND ("day_of_week" <= 6)))
);


ALTER TABLE "public"."work_schedules" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."work_schedules_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."work_schedules_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."work_schedules_id_seq" OWNED BY "public"."work_schedules"."id";



ALTER TABLE ONLY "public"."catalog_banners" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."catalog_banners_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."debug_payload_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."debug_payload_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."fleet_refuelings" ALTER COLUMN "request_number" SET DEFAULT "nextval"('"public"."fleet_refuelings_request_number_seq"'::"regclass");



ALTER TABLE ONLY "public"."orders" ALTER COLUMN "order_number" SET DEFAULT "nextval"('"public"."orders_order_number_seq"'::"regclass");



ALTER TABLE ONLY "public"."purchases" ALTER COLUMN "sequential_code" SET DEFAULT "nextval"('"public"."purchases_sequential_code_seq"'::"regclass");



ALTER TABLE ONLY "public"."system_settings" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."system_settings_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."time_extension_requests" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."time_extension_requests_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."user_screenshots" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."user_screenshots_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."work_schedules" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."work_schedules_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."admin_channel_members"
    ADD CONSTRAINT "admin_channel_members_pkey" PRIMARY KEY ("channel_id", "profile_id");



ALTER TABLE ONLY "public"."admin_channels"
    ADD CONSTRAINT "admin_channels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_messages"
    ADD CONSTRAINT "admin_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."app_tasks"
    ADD CONSTRAINT "app_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_assets"
    ADD CONSTRAINT "builder_assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_audit_logs"
    ADD CONSTRAINT "builder_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_menus"
    ADD CONSTRAINT "builder_menus_handle_key" UNIQUE ("handle");



ALTER TABLE ONLY "public"."builder_menus"
    ADD CONSTRAINT "builder_menus_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_page_versions"
    ADD CONSTRAINT "builder_page_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_pages"
    ADD CONSTRAINT "builder_pages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."builder_pages"
    ADD CONSTRAINT "builder_pages_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."builder_themes"
    ADD CONSTRAINT "builder_themes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_accounting_configs"
    ADD CONSTRAINT "cajuia_accounting_configs_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."cajuia_accounts"
    ADD CONSTRAINT "cajuia_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_bank_accounts"
    ADD CONSTRAINT "cajuia_bank_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_bank_statements"
    ADD CONSTRAINT "cajuia_bank_statements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_bank_transactions"
    ADD CONSTRAINT "cajuia_bank_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_cash_movements"
    ADD CONSTRAINT "cajuia_cash_movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_cash_sessions"
    ADD CONSTRAINT "cajuia_cash_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_categories"
    ADD CONSTRAINT "cajuia_categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."cajuia_categories"
    ADD CONSTRAINT "cajuia_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_clients"
    ADD CONSTRAINT "cajuia_clients_external_id_key" UNIQUE ("external_id");



ALTER TABLE ONLY "public"."cajuia_clients"
    ADD CONSTRAINT "cajuia_clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_corte_tasks"
    ADD CONSTRAINT "cajuia_corte_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_cost_centers"
    ADD CONSTRAINT "cajuia_cost_centers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_dashboard_layouts"
    ADD CONSTRAINT "cajuia_dashboard_layouts_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."cajuia_expense_categories"
    ADD CONSTRAINT "cajuia_expense_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_fiscal_docs"
    ADD CONSTRAINT "cajuia_fiscal_docs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_journal_entries"
    ADD CONSTRAINT "cajuia_journal_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_journal_items"
    ADD CONSTRAINT "cajuia_journal_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_order_drafts"
    ADD CONSTRAINT "cajuia_order_drafts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_order_items"
    ADD CONSTRAINT "cajuia_order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_orders"
    ADD CONSTRAINT "cajuia_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_payables"
    ADD CONSTRAINT "cajuia_payables_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."cajuia_payables"
    ADD CONSTRAINT "cajuia_payables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_permissions"
    ADD CONSTRAINT "cajuia_permissions_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."cajuia_price_lists"
    ADD CONSTRAINT "cajuia_price_lists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_product_prices"
    ADD CONSTRAINT "cajuia_product_prices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_products"
    ADD CONSTRAINT "cajuia_products_barcode_key" UNIQUE ("barcode");



ALTER TABLE ONLY "public"."cajuia_products"
    ADD CONSTRAINT "cajuia_products_gestaoclick_id_key" UNIQUE ("gestaoclick_id");



ALTER TABLE ONLY "public"."cajuia_products"
    ADD CONSTRAINT "cajuia_products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_products"
    ADD CONSTRAINT "cajuia_products_sku_key" UNIQUE ("sku");



ALTER TABLE ONLY "public"."cajuia_receivables"
    ADD CONSTRAINT "cajuia_receivables_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."cajuia_receivables"
    ADD CONSTRAINT "cajuia_receivables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_tax_settings"
    ADD CONSTRAINT "cajuia_tax_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajuia_widgets"
    ADD CONSTRAINT "cajuia_widgets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_banners"
    ADD CONSTRAINT "catalog_banners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_categories"
    ADD CONSTRAINT "catalog_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_categories"
    ADD CONSTRAINT "catalog_categories_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."catalog_collections"
    ADD CONSTRAINT "catalog_collections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_collections"
    ADD CONSTRAINT "catalog_collections_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."catalog_fabrics"
    ADD CONSTRAINT "catalog_fabrics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_mockups"
    ADD CONSTRAINT "catalog_mockups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_settings"
    ADD CONSTRAINT "catalog_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_stamp_collections"
    ADD CONSTRAINT "catalog_stamp_collections_pkey" PRIMARY KEY ("stamp_id", "collection_id");



ALTER TABLE ONLY "public"."catalog_stamp_media"
    ADD CONSTRAINT "catalog_stamp_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_stamp_mockups"
    ADD CONSTRAINT "catalog_stamp_mockups_pkey" PRIMARY KEY ("stamp_id", "mockup_id");



ALTER TABLE ONLY "public"."catalog_stamp_tags"
    ADD CONSTRAINT "catalog_stamp_tags_pkey" PRIMARY KEY ("stamp_id", "tag_id");



ALTER TABLE ONLY "public"."catalog_stamps"
    ADD CONSTRAINT "catalog_stamps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_stamps"
    ADD CONSTRAINT "catalog_stamps_ref_code_key" UNIQUE ("ref_code");



ALTER TABLE ONLY "public"."catalog_stamps"
    ADD CONSTRAINT "catalog_stamps_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."catalog_tags"
    ADD CONSTRAINT "catalog_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalog_tags"
    ADD CONSTRAINT "catalog_tags_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."channel_members"
    ADD CONSTRAINT "channel_members_pkey" PRIMARY KEY ("channel_id", "profile_id");



ALTER TABLE ONLY "public"."channels"
    ADD CONSTRAINT "channels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."client_design_deliveries"
    ADD CONSTRAINT "client_design_deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."client_transactions"
    ADD CONSTRAINT "client_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commerce_leads"
    ADD CONSTRAINT "commerce_leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commerce_leads"
    ADD CONSTRAINT "commerce_leads_session_token_key" UNIQUE ("session_token");



ALTER TABLE ONLY "public"."commerce_moodboard_items"
    ADD CONSTRAINT "commerce_moodboard_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commerce_moodboards"
    ADD CONSTRAINT "commerce_moodboards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commerce_quote_requests"
    ADD CONSTRAINT "commerce_quote_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_cnpj_key" UNIQUE ("cnpj");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."company_installed_apps"
    ADD CONSTRAINT "company_installed_apps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."company_installed_apps"
    ADD CONSTRAINT "company_installed_apps_store_id_app_id_key" UNIQUE ("store_id", "app_id");



ALTER TABLE ONLY "public"."company_integrations"
    ADD CONSTRAINT "company_integrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."company_integrations"
    ADD CONSTRAINT "company_integrations_store_id_provider_key" UNIQUE ("store_id", "provider");



ALTER TABLE ONLY "public"."crm_active_alerts"
    ADD CONSTRAINT "crm_active_alerts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crm_automations"
    ADD CONSTRAINT "crm_automations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crm_kanban_columns"
    ADD CONSTRAINT "crm_kanban_columns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crm_lead_history"
    ADD CONSTRAINT "crm_lead_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crm_workflows"
    ADD CONSTRAINT "crm_workflows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cte_entries"
    ADD CONSTRAINT "cte_entries_chave_key" UNIQUE ("chave");



ALTER TABLE ONLY "public"."cte_entries"
    ADD CONSTRAINT "cte_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."custom_roles"
    ADD CONSTRAINT "custom_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customer_tags"
    ADD CONSTRAINT "customer_tags_customer_name_tag_key" UNIQUE ("customer_name", "tag");



ALTER TABLE ONLY "public"."customer_tags"
    ADD CONSTRAINT "customer_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customers_mj"
    ADD CONSTRAINT "customers_mj_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."customers_mj"
    ADD CONSTRAINT "customers_mj_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_stock_reports"
    ADD CONSTRAINT "daily_stock_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."daily_stock_reports"
    ADD CONSTRAINT "daily_stock_reports_report_date_key" UNIQUE ("report_date");



ALTER TABLE ONLY "public"."debug_payload_log"
    ADD CONSTRAINT "debug_payload_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_assignment_requests"
    ADD CONSTRAINT "design_assignment_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_kanban_columns"
    ADD CONSTRAINT "design_kanban_columns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_kanban_columns"
    ADD CONSTRAINT "design_kanban_columns_tag_name_key" UNIQUE ("tag_name");



ALTER TABLE ONLY "public"."design_queue"
    ADD CONSTRAINT "design_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_rejection_logs"
    ADD CONSTRAINT "design_rejection_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_requests"
    ADD CONSTRAINT "design_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."design_user_permissions"
    ADD CONSTRAINT "design_user_permissions_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."dfe_entries"
    ADD CONSTRAINT "dfe_entries_pkey" PRIMARY KEY ("chave");



ALTER TABLE ONLY "public"."digital_purchases"
    ADD CONSTRAINT "digital_purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_accounts"
    ADD CONSTRAINT "email_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_accounts"
    ADD CONSTRAINT "email_accounts_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_message_id_key" UNIQUE ("message_id");



ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."employees_mj"
    ADD CONSTRAINT "employees_mj_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."employees_mj"
    ADD CONSTRAINT "employees_mj_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."erp_orders_cache"
    ADD CONSTRAINT "erp_orders_cache_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_accounts"
    ADD CONSTRAINT "finance_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_audit_logs"
    ADD CONSTRAINT "finance_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_bank_accounts"
    ADD CONSTRAINT "finance_bank_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_chart_of_accounts"
    ADD CONSTRAINT "finance_chart_of_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_charts_of_accounts"
    ADD CONSTRAINT "finance_charts_of_accounts_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."finance_charts_of_accounts"
    ADD CONSTRAINT "finance_charts_of_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_cost_centers"
    ADD CONSTRAINT "finance_cost_centers_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."finance_cost_centers"
    ADD CONSTRAINT "finance_cost_centers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_invoice_payments"
    ADD CONSTRAINT "finance_invoice_payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_payment_methods"
    ADD CONSTRAINT "finance_payment_methods_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."finance_payment_methods"
    ADD CONSTRAINT "finance_payment_methods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_receivable_payments"
    ADD CONSTRAINT "finance_receivable_payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_transactions"
    ADD CONSTRAINT "finance_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fiscal_companies"
    ADD CONSTRAINT "fiscal_companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fiscal_tax_rules"
    ADD CONSTRAINT "fiscal_tax_rules_company_id_uf_key" UNIQUE ("company_id", "uf");



ALTER TABLE ONLY "public"."fiscal_tax_rules"
    ADD CONSTRAINT "fiscal_tax_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fleet_refuelings"
    ADD CONSTRAINT "fleet_refuelings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fleet_vehicles"
    ADD CONSTRAINT "fleet_vehicles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fleet_vehicles"
    ADD CONSTRAINT "fleet_vehicles_plate_key" UNIQUE ("plate");



ALTER TABLE ONLY "public"."label_presets"
    ADD CONSTRAINT "label_presets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."marketplace_cart"
    ADD CONSTRAINT "marketplace_cart_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."marketplace_cart"
    ADD CONSTRAINT "marketplace_cart_user_id_stamp_id_fabric_id_is_physical_key" UNIQUE ("user_id", "stamp_id", "fabric_id", "is_physical");



ALTER TABLE ONLY "public"."marketplace_customers"
    ADD CONSTRAINT "marketplace_customers_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."marketplace_customers"
    ADD CONSTRAINT "marketplace_customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."marketplace_favorite_folders"
    ADD CONSTRAINT "marketplace_favorite_folders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."marketplace_favorite_items"
    ADD CONSTRAINT "marketplace_favorite_items_lead_id_stamp_id_key" UNIQUE ("lead_id", "stamp_id");



ALTER TABLE ONLY "public"."marketplace_favorite_items"
    ADD CONSTRAINT "marketplace_favorite_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mj_cash_extraction_audit"
    ADD CONSTRAINT "mj_cash_extraction_audit_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mj_cash_movements"
    ADD CONSTRAINT "mj_cash_movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mj_cash_sessions"
    ADD CONSTRAINT "mj_cash_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mj_expense_categories"
    ADD CONSTRAINT "mj_expense_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mj_payables"
    ADD CONSTRAINT "mj_payables_nfe_key_key" UNIQUE ("nfe_key");



ALTER TABLE ONLY "public"."mj_payables"
    ADD CONSTRAINT "mj_payables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."nfce_outbound"
    ADD CONSTRAINT "nfce_outbound_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."nfe_outbound"
    ADD CONSTRAINT "nfe_outbound_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."operation_events"
    ADD CONSTRAINT "operation_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_drafts"
    ADD CONSTRAINT "order_drafts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_drafts"
    ADD CONSTRAINT "order_drafts_reserved_order_number_key" UNIQUE ("reserved_order_number");



ALTER TABLE ONLY "public"."order_groups"
    ADD CONSTRAINT "order_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_op_number_key" UNIQUE ("op_number");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_logs"
    ADD CONSTRAINT "order_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_payments"
    ADD CONSTRAINT "order_payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_order_number_key" UNIQUE ("order_number");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pcp_workflows"
    ADD CONSTRAINT "pcp_workflows_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pdv_price_lists"
    ADD CONSTRAINT "pdv_price_lists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pdv_product_prices"
    ADD CONSTRAINT "pdv_product_prices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pending_stock_orders"
    ADD CONSTRAINT "pending_stock_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pilot_transactions"
    ADD CONSTRAINT "pilot_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."premium_access_events"
    ADD CONSTRAINT "premium_access_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."premium_sessions"
    ADD CONSTRAINT "premium_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."premium_sessions"
    ADD CONSTRAINT "premium_sessions_session_token_key" UNIQUE ("session_token");



ALTER TABLE ONLY "public"."price_list"
    ADD CONSTRAINT "price_list_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_details"
    ADD CONSTRAINT "product_details_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."product_details"
    ADD CONSTRAINT "product_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_logs"
    ADD CONSTRAINT "production_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_machines"
    ADD CONSTRAINT "production_machines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."production_schedule"
    ADD CONSTRAINT "production_schedule_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."productivity_rules"
    ADD CONSTRAINT "productivity_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."productivity_rules"
    ADD CONSTRAINT "productivity_rules_term_key" UNIQUE ("term");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."project_columns"
    ADD CONSTRAINT "project_columns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."public_leads"
    ADD CONSTRAINT "public_leads_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."public_leads"
    ADD CONSTRAINT "public_leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchase_items"
    ADD CONSTRAINT "purchase_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales_goals"
    ADD CONSTRAINT "sales_goals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales_goals"
    ADD CONSTRAINT "sales_goals_seller_id_month_year_key" UNIQUE ("seller_id", "month", "year");



ALTER TABLE ONLY "public"."scheduled_orders"
    ADD CONSTRAINT "scheduled_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."security_events_log"
    ADD CONSTRAINT "security_events_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."security_profiles"
    ADD CONSTRAINT "security_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."security_profiles"
    ADD CONSTRAINT "security_profiles_session_id_key" UNIQUE ("session_id");



ALTER TABLE ONLY "public"."seller_activities"
    ADD CONSTRAINT "seller_activities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services_catalog"
    ADD CONSTRAINT "services_catalog_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sre_audit_logs"
    ADD CONSTRAINT "sre_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sre_incidents"
    ADD CONSTRAINT "sre_incidents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stamp_folders"
    ADD CONSTRAINT "stamp_folders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stamp_library"
    ADD CONSTRAINT "stamp_library_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_batches"
    ADD CONSTRAINT "stock_batches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_batches"
    ADD CONSTRAINT "stock_batches_stock_id_batch_code_key" UNIQUE ("stock_id", "batch_code");



ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."stock_ledger"
    ADD CONSTRAINT "stock_ledger_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stock_tabs"
    ADD CONSTRAINT "stock_tabs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_orders"
    ADD CONSTRAINT "store_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."storefront_settings"
    ADD CONSTRAINT "storefront_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."suppliers_mj"
    ADD CONSTRAINT "suppliers_mj_gestao_click_id_key" UNIQUE ("gestao_click_id");



ALTER TABLE ONLY "public"."suppliers_mj"
    ADD CONSTRAINT "suppliers_mj_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_audit_logs"
    ADD CONSTRAINT "system_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_events"
    ADD CONSTRAINT "system_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_settings"
    ADD CONSTRAINT "system_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_updates"
    ADD CONSTRAINT "system_updates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_extension_requests"
    ADD CONSTRAINT "time_extension_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_assignments"
    ADD CONSTRAINT "time_tracking_assignments_employee_id_key" UNIQUE ("employee_id");



ALTER TABLE ONLY "public"."time_tracking_assignments"
    ADD CONSTRAINT "time_tracking_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_corrections"
    ADD CONSTRAINT "time_tracking_corrections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_holidays"
    ADD CONSTRAINT "time_tracking_holidays_date_key" UNIQUE ("date");



ALTER TABLE ONLY "public"."time_tracking_holidays"
    ADD CONSTRAINT "time_tracking_holidays_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_kiosk_releases"
    ADD CONSTRAINT "time_tracking_kiosk_releases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_kiosk_users"
    ADD CONSTRAINT "time_tracking_kiosk_users_pkey" PRIMARY KEY ("kiosk_id", "employee_id");



ALTER TABLE ONLY "public"."time_tracking_kiosks"
    ADD CONSTRAINT "time_tracking_kiosks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_logs"
    ADD CONSTRAINT "time_tracking_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_overrides"
    ADD CONSTRAINT "time_tracking_overrides_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_overtime_requests"
    ADD CONSTRAINT "time_tracking_overtime_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_payroll_events"
    ADD CONSTRAINT "time_tracking_payroll_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_settings"
    ADD CONSTRAINT "time_tracking_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."time_tracking_shift_templates"
    ADD CONSTRAINT "time_tracking_shift_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_modules"
    ADD CONSTRAINT "training_modules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_user_id_module_id_key" UNIQUE ("user_id", "module_id");



ALTER TABLE ONLY "public"."stamp_library"
    ADD CONSTRAINT "uniq_stamp" UNIQUE ("image_url");



ALTER TABLE ONLY "public"."time_tracking_logs"
    ADD CONSTRAINT "unique_employee_date" UNIQUE ("employee_id", "date");



ALTER TABLE ONLY "public"."pdv_product_prices"
    ADD CONSTRAINT "unique_pdv_price_per_list" UNIQUE ("price_list_id", "product_id");



ALTER TABLE ONLY "public"."cajuia_product_prices"
    ADD CONSTRAINT "unique_price_per_list" UNIQUE ("price_list_id", "product_id");



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_notification_dismissals"
    ADD CONSTRAINT "user_notification_dismissals_pkey" PRIMARY KEY ("user_id", "notification_id");



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_presences"
    ADD CONSTRAINT "user_presences_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_screenshots"
    ADD CONSTRAINT "user_screenshots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_screenshots"
    ADD CONSTRAINT "user_screenshots_storage_path_key" UNIQUE ("storage_path");



ALTER TABLE ONLY "public"."wa_conversations"
    ADD CONSTRAINT "wa_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wa_messages"
    ADD CONSTRAINT "wa_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."work_schedules"
    ADD CONSTRAINT "work_schedules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."work_schedules"
    ADD CONSTRAINT "work_schedules_user_id_day_of_week_is_general_key" UNIQUE ("user_id", "day_of_week", "is_general");



CREATE INDEX "channels_admin_ids_gin_idx" ON "public"."channels" USING "gin" ("admin_ids");



CREATE INDEX "channels_dm_participant_ids_gin_idx" ON "public"."channels" USING "gin" ("dm_participant_ids");



CREATE INDEX "channels_moderator_ids_gin_idx" ON "public"."channels" USING "gin" ("moderator_ids");



CREATE INDEX "idx_app_tasks_assigned_to" ON "public"."app_tasks" USING "btree" ("assigned_to");



CREATE INDEX "idx_app_tasks_created_by" ON "public"."app_tasks" USING "btree" ("created_by");



CREATE INDEX "idx_app_tasks_due_date" ON "public"."app_tasks" USING "btree" ("due_date");



CREATE INDEX "idx_app_tasks_status" ON "public"."app_tasks" USING "btree" ("status");



CREATE INDEX "idx_audit_created_at" ON "public"."audit_logs" USING "btree" ("created_at");



CREATE INDEX "idx_audit_logs_action_type" ON "public"."system_audit_logs" USING "btree" ("action_type");



CREATE INDEX "idx_audit_logs_created_at" ON "public"."system_audit_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_audit_logs_user_id" ON "public"."system_audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_audit_user_id" ON "public"."audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_cajuia_bank_trans_amount" ON "public"."cajuia_bank_transactions" USING "btree" ("amount");



CREATE INDEX "idx_cajuia_bank_trans_date" ON "public"."cajuia_bank_transactions" USING "btree" ("transaction_date");



CREATE INDEX "idx_cajuia_journal_entries_date" ON "public"."cajuia_journal_entries" USING "btree" ("transaction_date");



CREATE INDEX "idx_cajuia_journal_items_account" ON "public"."cajuia_journal_items" USING "btree" ("account_id");



CREATE INDEX "idx_cajuia_journal_items_entry" ON "public"."cajuia_journal_items" USING "btree" ("journal_entry_id");



CREATE INDEX "idx_cajuia_payables_due_date" ON "public"."cajuia_payables" USING "btree" ("due_date");



CREATE INDEX "idx_cajuia_payables_gestao_id" ON "public"."cajuia_payables" USING "btree" ("gestao_click_id");



CREATE INDEX "idx_cajuia_receivables_due_date" ON "public"."cajuia_receivables" USING "btree" ("due_date");



CREATE INDEX "idx_cajuia_receivables_gestao_id" ON "public"."cajuia_receivables" USING "btree" ("gestao_click_id");



CREATE INDEX "idx_channels_is_deleted" ON "public"."channels" USING "btree" ("is_deleted");



CREATE INDEX "idx_companies_cnpj" ON "public"."companies" USING "btree" ("cnpj");



CREATE INDEX "idx_customers_gestao_id" ON "public"."customers_mj" USING "btree" ("gestao_click_id");



CREATE INDEX "idx_design_deliveries_client_email" ON "public"."client_design_deliveries" USING "btree" ("client_email");



CREATE INDEX "idx_design_deliveries_expires_at" ON "public"."client_design_deliveries" USING "btree" ("expires_at");



CREATE INDEX "idx_dfe_entries_nsu" ON "public"."dfe_entries" USING "btree" ("nsu");



CREATE INDEX "idx_fin_pay_company_id" ON "public"."finance_payables" USING "btree" ("company_id");



CREATE INDEX "idx_fin_pay_gestao_id" ON "public"."finance_payables" USING "btree" ("gestao_click_id");



CREATE INDEX "idx_fin_rec_gestao_id" ON "public"."finance_receivables" USING "btree" ("gestao_click_id");



CREATE INDEX "idx_fin_rec_store_sale_id" ON "public"."finance_receivables" USING "btree" ("store_sale_id");



CREATE INDEX "idx_finance_audit_logs_entity_id" ON "public"."finance_audit_logs" USING "btree" ("entity_id");



CREATE INDEX "idx_finance_receivables_company_id" ON "public"."finance_receivables" USING "btree" ("company_id");



CREATE INDEX "idx_finance_transactions_account_date" ON "public"."finance_transactions" USING "btree" ("account_id", "transaction_date");



CREATE INDEX "idx_mj_payables_nfe_key" ON "public"."mj_payables" USING "btree" ("nfe_key");



CREATE INDEX "idx_movements_session" ON "public"."cajuia_cash_movements" USING "btree" ("session_id");



CREATE INDEX "idx_nfe_outbound_modelo" ON "public"."nfe_outbound" USING "btree" ("modelo");



CREATE INDEX "idx_op_events_actor" ON "public"."operation_events" USING "btree" ("actor_id");



CREATE INDEX "idx_op_events_created" ON "public"."operation_events" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_op_events_entity" ON "public"."operation_events" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "idx_op_events_module" ON "public"."operation_events" USING "btree" ("module_key");



CREATE INDEX "idx_op_number" ON "public"."order_items" USING "btree" ("op_number");



CREATE INDEX "idx_orders_billing_queue_visible" ON "public"."orders" USING "btree" ("billing_queue_visible");



CREATE INDEX "idx_orders_invoiced_by" ON "public"."orders" USING "btree" ("invoiced_by");



CREATE INDEX "idx_pilot_requests_group_id" ON "public"."pilot_requests" USING "btree" ("group_id");



CREATE INDEX "idx_premium_events_lead_id" ON "public"."premium_access_events" USING "btree" ("lead_id");



CREATE INDEX "idx_premium_events_type" ON "public"."premium_access_events" USING "btree" ("event_type");



CREATE INDEX "idx_security_events_created_at" ON "public"."security_events_log" USING "btree" ("created_at");



CREATE INDEX "idx_security_events_session_id" ON "public"."security_events_log" USING "btree" ("session_id");



CREATE INDEX "idx_security_profiles_session_id" ON "public"."security_profiles" USING "btree" ("session_id");



CREATE INDEX "idx_sessions_user_status" ON "public"."cajuia_cash_sessions" USING "btree" ("user_id", "status");



CREATE INDEX "idx_stock_barcode" ON "public"."stock" USING "btree" ("barcode");



CREATE INDEX "idx_stock_batches_current_qty" ON "public"."stock_batches" USING "btree" ("current_qty");



CREATE INDEX "idx_stock_batches_stock_id" ON "public"."stock_batches" USING "btree" ("stock_id");



CREATE INDEX "idx_stock_ledger_batch_id" ON "public"."stock_ledger" USING "btree" ("batch_id");



CREATE INDEX "idx_stock_ledger_created_at" ON "public"."stock_ledger" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_stock_ledger_order_id" ON "public"."stock_ledger" USING "btree" ("order_id");



CREATE INDEX "idx_stock_ledger_stock_id" ON "public"."stock_ledger" USING "btree" ("stock_id");



CREATE INDEX "idx_stock_movements_created_at" ON "public"."stock_movements" USING "btree" ("created_at");



CREATE INDEX "idx_system_events_level" ON "public"."system_events" USING "btree" ("level");



CREATE INDEX "idx_system_events_module" ON "public"."system_events" USING "btree" ("module");



CREATE INDEX "idx_system_events_resolved" ON "public"."system_events" USING "btree" ("is_resolved");



CREATE INDEX "idx_time_tracking_logs_date" ON "public"."time_tracking_logs" USING "btree" ("date");



CREATE INDEX "idx_time_tracking_logs_employee" ON "public"."time_tracking_logs" USING "btree" ("employee_id");



CREATE UNIQUE INDEX "idx_unique_page_draft" ON "public"."builder_page_versions" USING "btree" ("page_id") WHERE ("status" = 'draft'::"text");



CREATE UNIQUE INDEX "idx_unique_page_published" ON "public"."builder_page_versions" USING "btree" ("page_id") WHERE ("status" = 'published'::"text");



CREATE OR REPLACE TRIGGER "on_cajuia_sale_created" AFTER INSERT ON "public"."cajuia_orders" FOR EACH ROW EXECUTE FUNCTION "public"."trg_cajuia_auto_post_sale"();



CREATE OR REPLACE TRIGGER "on_email_accounts_updated" BEFORE UPDATE ON "public"."email_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "on_emails_updated" BEFORE UPDATE ON "public"."emails" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "on_new_launch_order_set_forecast" BEFORE INSERT ON "public"."orders" FOR EACH ROW WHEN (("new"."is_launch" IS TRUE)) EXECUTE FUNCTION "public"."set_initial_forecast_delivery_date"();



CREATE OR REPLACE TRIGGER "on_order_draft_updated" BEFORE UPDATE ON "public"."order_drafts" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "on_order_item_update" AFTER UPDATE OF "status" ON "public"."order_items" FOR EACH ROW EXECUTE FUNCTION "public"."check_parent_order_completion"();



CREATE OR REPLACE TRIGGER "on_order_items_updated_at" BEFORE UPDATE ON "public"."order_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "on_stock_change" AFTER INSERT OR UPDATE ON "public"."stock" FOR EACH ROW EXECUTE FUNCTION "public"."log_stock_change"();



CREATE OR REPLACE TRIGGER "on_stock_update_process_pending_orders_v2" AFTER UPDATE ON "public"."stock" FOR EACH ROW EXECUTE FUNCTION "public"."process_pending_stock_orders"();



CREATE OR REPLACE TRIGGER "on_stock_update_release_scheduled" AFTER UPDATE OF "available_meters" ON "public"."stock" FOR EACH ROW EXECUTE FUNCTION "public"."check_and_release_scheduled_orders"();



CREATE OR REPLACE TRIGGER "on_stock_update_reprocess_orders" AFTER UPDATE ON "public"."stock" FOR EACH ROW EXECUTE FUNCTION "public"."reprocess_pending_stock_orders"();



CREATE OR REPLACE TRIGGER "on_user_created_update_presence" AFTER INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_user_presence"();



CREATE OR REPLACE TRIGGER "tr_time_tracking_logs_updated_at" BEFORE UPDATE ON "public"."time_tracking_logs" FOR EACH ROW EXECUTE FUNCTION "public"."update_time_tracking_updated_at"();



CREATE OR REPLACE TRIGGER "tr_time_tracking_settings_updated_at" BEFORE UPDATE ON "public"."time_tracking_settings" FOR EACH ROW EXECUTE FUNCTION "public"."update_time_tracking_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_admin_channel_members" AFTER INSERT OR DELETE OR UPDATE ON "public"."admin_channel_members" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_admin_channels" AFTER INSERT OR DELETE OR UPDATE ON "public"."admin_channels" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_admin_messages" AFTER INSERT OR DELETE OR UPDATE ON "public"."admin_messages" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_app_config" AFTER INSERT OR DELETE OR UPDATE ON "public"."app_config" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_accounting_configs" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_accounting_configs" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_bank_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_bank_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_bank_statements" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_bank_statements" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_bank_transactions" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_bank_transactions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_cash_movements" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_cash_movements" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_cash_sessions" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_cash_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_categories" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_categories" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_clients" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_clients" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_corte_tasks" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_corte_tasks" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_cost_centers" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_cost_centers" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_dashboard_layouts" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_dashboard_layouts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_expense_categories" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_expense_categories" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_fiscal_docs" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_fiscal_docs" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_journal_entries" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_journal_entries" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_journal_items" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_journal_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_order_drafts" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_order_drafts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_order_items" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_order_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_orders" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_orders" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_payables" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_payables" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_permissions" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_permissions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_price_lists" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_price_lists" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_product_prices" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_product_prices" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_products" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_products" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_receivables" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_receivables" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_tax_settings" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_tax_settings" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cajuia_widgets" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajuia_widgets" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_channel_members" AFTER INSERT OR DELETE OR UPDATE ON "public"."channel_members" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_channels" AFTER INSERT OR DELETE OR UPDATE ON "public"."channels" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_companies" AFTER INSERT OR DELETE OR UPDATE ON "public"."companies" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_company_installed_apps" AFTER INSERT OR DELETE OR UPDATE ON "public"."company_installed_apps" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_company_integrations" AFTER INSERT OR DELETE OR UPDATE ON "public"."company_integrations" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_cte_entries" AFTER INSERT OR DELETE OR UPDATE ON "public"."cte_entries" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_custom_roles" AFTER INSERT OR DELETE OR UPDATE ON "public"."custom_roles" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_customer_tags" AFTER INSERT OR DELETE OR UPDATE ON "public"."customer_tags" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_customers" AFTER INSERT OR DELETE OR UPDATE ON "public"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_customers_mj" AFTER INSERT OR DELETE OR UPDATE ON "public"."customers_mj" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_daily_stock_reports" AFTER INSERT OR DELETE OR UPDATE ON "public"."daily_stock_reports" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_assignment_requests" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_assignment_requests" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_kanban_columns" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_kanban_columns" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_queue" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_queue" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_rejection_logs" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_rejection_logs" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_requests" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_requests" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_design_user_permissions" AFTER INSERT OR DELETE OR UPDATE ON "public"."design_user_permissions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_dfe_entries" AFTER INSERT OR DELETE OR UPDATE ON "public"."dfe_entries" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_employees_mj" AFTER INSERT OR DELETE OR UPDATE ON "public"."employees_mj" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_erp_orders_cache" AFTER INSERT OR DELETE OR UPDATE ON "public"."erp_orders_cache" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_bank_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_bank_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_chart_of_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_chart_of_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_charts_of_accounts" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_charts_of_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_cost_centers" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_cost_centers" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_invoice_payments" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_invoice_payments" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_payables" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_payables" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_payment_methods" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_payment_methods" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_receivable_payments" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_receivable_payments" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_receivables" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_receivables" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_finance_transactions" AFTER INSERT OR DELETE OR UPDATE ON "public"."finance_transactions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_fiscal_companies" AFTER INSERT OR DELETE OR UPDATE ON "public"."fiscal_companies" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_fleet_refuelings" AFTER INSERT OR DELETE OR UPDATE ON "public"."fleet_refuelings" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_fleet_vehicles" AFTER INSERT OR DELETE OR UPDATE ON "public"."fleet_vehicles" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_label_presets" AFTER INSERT OR DELETE OR UPDATE ON "public"."label_presets" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_mj_cash_movements" AFTER INSERT OR DELETE OR UPDATE ON "public"."mj_cash_movements" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_mj_cash_sessions" AFTER INSERT OR DELETE OR UPDATE ON "public"."mj_cash_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_mj_expense_categories" AFTER INSERT OR DELETE OR UPDATE ON "public"."mj_expense_categories" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_mj_payables" AFTER INSERT OR DELETE OR UPDATE ON "public"."mj_payables" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_nfce_outbound" AFTER INSERT OR DELETE OR UPDATE ON "public"."nfce_outbound" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_nfe_outbound" AFTER INSERT OR DELETE OR UPDATE ON "public"."nfe_outbound" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_order_groups" AFTER INSERT OR DELETE OR UPDATE ON "public"."order_groups" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_order_items" AFTER INSERT OR DELETE OR UPDATE ON "public"."order_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_order_payments" AFTER INSERT OR DELETE OR UPDATE ON "public"."order_payments" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_orders" AFTER INSERT OR DELETE OR UPDATE ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_pending_stock_orders" AFTER INSERT OR DELETE OR UPDATE ON "public"."pending_stock_orders" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_price_list" AFTER INSERT OR DELETE OR UPDATE ON "public"."price_list" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_product_details" AFTER INSERT OR DELETE OR UPDATE ON "public"."product_details" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_production_machines" AFTER INSERT OR DELETE OR UPDATE ON "public"."production_machines" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_production_schedule" AFTER INSERT OR DELETE OR UPDATE ON "public"."production_schedule" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_productivity_rules" AFTER INSERT OR DELETE OR UPDATE ON "public"."productivity_rules" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_products" AFTER INSERT OR DELETE OR UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_profiles" AFTER INSERT OR DELETE OR UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_project_columns" AFTER INSERT OR DELETE OR UPDATE ON "public"."project_columns" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_purchase_items" AFTER INSERT OR DELETE OR UPDATE ON "public"."purchase_items" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_purchases" AFTER INSERT OR DELETE OR UPDATE ON "public"."purchases" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_sales_goals" AFTER INSERT OR DELETE OR UPDATE ON "public"."sales_goals" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_scheduled_orders" AFTER INSERT OR DELETE OR UPDATE ON "public"."scheduled_orders" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_seller_activities" AFTER INSERT OR DELETE OR UPDATE ON "public"."seller_activities" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_services_catalog" AFTER INSERT OR DELETE OR UPDATE ON "public"."services_catalog" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_stamp_folders" AFTER INSERT OR DELETE OR UPDATE ON "public"."stamp_folders" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_stamp_library" AFTER INSERT OR DELETE OR UPDATE ON "public"."stamp_library" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_stock" AFTER INSERT OR DELETE OR UPDATE ON "public"."stock" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_stock_tabs" AFTER INSERT OR DELETE OR UPDATE ON "public"."stock_tabs" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_store_sales" AFTER INSERT OR DELETE OR UPDATE ON "public"."store_sales" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_stores" AFTER INSERT OR DELETE OR UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_suppliers_mj" AFTER INSERT OR DELETE OR UPDATE ON "public"."suppliers_mj" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_system_events" AFTER INSERT OR DELETE OR UPDATE ON "public"."system_events" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_tasks" AFTER INSERT OR DELETE OR UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_time_extension_requests" AFTER INSERT OR DELETE OR UPDATE ON "public"."time_extension_requests" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_time_kiosks" AFTER INSERT OR DELETE OR UPDATE ON "public"."time_tracking_kiosks" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_training_modules" AFTER INSERT OR DELETE OR UPDATE ON "public"."training_modules" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_training_progress" AFTER INSERT OR DELETE OR UPDATE ON "public"."training_progress" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_user_preferences" AFTER INSERT OR DELETE OR UPDATE ON "public"."user_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_user_reports" AFTER INSERT OR DELETE OR UPDATE ON "public"."user_reports" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_user_screenshots" AFTER INSERT OR DELETE OR UPDATE ON "public"."user_screenshots" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_wa_conversations" AFTER INSERT OR DELETE OR UPDATE ON "public"."wa_conversations" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_audit_work_schedules" AFTER INSERT OR DELETE OR UPDATE ON "public"."work_schedules" FOR EACH ROW EXECUTE FUNCTION "public"."log_universal_activity"();



CREATE OR REPLACE TRIGGER "trg_check_channel_lock" BEFORE INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."check_channel_lock_before_insert"();



CREATE OR REPLACE TRIGGER "trg_restore_credit" AFTER UPDATE ON "public"."finance_receivables" FOR EACH ROW EXECUTE FUNCTION "public"."restore_credit_on_payment"();



CREATE OR REPLACE TRIGGER "trg_set_message_delete_history" BEFORE UPDATE ON "public"."messages" FOR EACH ROW WHEN ((("new"."is_deleted" = true) AND ("old"."is_deleted" = false))) EXECUTE FUNCTION "public"."set_message_delete_history"();



CREATE OR REPLACE TRIGGER "trg_set_message_edit_history" BEFORE UPDATE ON "public"."messages" FOR EACH ROW WHEN (("old"."content" IS DISTINCT FROM "new"."content")) EXECUTE FUNCTION "public"."set_message_edit_history"();



CREATE OR REPLACE TRIGGER "trg_set_purchase_codigo" BEFORE INSERT ON "public"."purchases" FOR EACH ROW EXECUTE FUNCTION "public"."func_set_purchase_codigo"();



CREATE OR REPLACE TRIGGER "trg_sre_draft_collision_check" AFTER INSERT OR UPDATE OF "reserved_order_number" ON "public"."order_drafts" FOR EACH ROW EXECUTE FUNCTION "public"."sre_check_collision_from_drafts"();



CREATE OR REPLACE TRIGGER "trg_sre_order_collision_check" AFTER INSERT ON "public"."orders" FOR EACH ROW EXECUTE FUNCTION "public"."sre_check_collision_from_orders"();



CREATE OR REPLACE TRIGGER "trg_sync_channel_members_delete" AFTER DELETE ON "public"."channel_members" FOR EACH ROW EXECUTE FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"();



CREATE OR REPLACE TRIGGER "trg_sync_channel_members_insert" AFTER INSERT ON "public"."channel_members" FOR EACH ROW EXECUTE FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"();



CREATE OR REPLACE TRIGGER "trg_sync_channels_delete" AFTER DELETE ON "public"."channels" FOR EACH ROW EXECUTE FUNCTION "public"."sync_channels_to_admin_channels_delete"();



CREATE OR REPLACE TRIGGER "trg_sync_channels_insert" AFTER INSERT ON "public"."channels" FOR EACH ROW EXECUTE FUNCTION "public"."sync_channels_to_admin_channels_insert"();



CREATE OR REPLACE TRIGGER "trg_sync_channels_update" AFTER UPDATE ON "public"."channels" FOR EACH ROW EXECUTE FUNCTION "public"."sync_channels_to_admin_channels_update"();



CREATE OR REPLACE TRIGGER "trg_sync_messages_delete" AFTER DELETE ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."sync_messages_to_admin_messages_delete"();



CREATE OR REPLACE TRIGGER "trg_sync_messages_insert" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."sync_messages_to_admin_messages_insert"();



CREATE OR REPLACE TRIGGER "trg_sync_messages_update" AFTER UPDATE ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."sync_messages_to_admin_messages_update"();



CREATE OR REPLACE TRIGGER "trg_update_order_financial_status" AFTER INSERT OR DELETE OR UPDATE OF "status", "value", "discount" ON "public"."finance_receivables" FOR EACH ROW EXECUTE FUNCTION "public"."update_order_financial_status"();



CREATE OR REPLACE TRIGGER "trigger_public_leads_updated_at" BEFORE UPDATE ON "public"."public_leads" FOR EACH ROW EXECUTE FUNCTION "public"."handle_public_leads_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_sync_item_date" AFTER INSERT ON "public"."cajuia_order_items" FOR EACH ROW EXECUTE FUNCTION "public"."sync_order_item_date"();



CREATE OR REPLACE TRIGGER "update_app_tasks_updated_at" BEFORE UPDATE ON "public"."app_tasks" FOR EACH ROW EXECUTE FUNCTION "public"."update_app_tasks_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_finance_accounts_modtime" BEFORE UPDATE ON "public"."finance_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_pcp_workflows_modtime" BEFORE UPDATE ON "public"."pcp_workflows" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



CREATE OR REPLACE TRIGGER "update_stock_batches_updated_at" BEFORE UPDATE ON "public"."stock_batches" FOR EACH ROW EXECUTE FUNCTION "public"."update_stock_batches_updated_at_column"();



ALTER TABLE ONLY "public"."app_tasks"
    ADD CONSTRAINT "app_tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."app_tasks"
    ADD CONSTRAINT "app_tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."builder_page_versions"
    ADD CONSTRAINT "builder_page_versions_page_id_fkey" FOREIGN KEY ("page_id") REFERENCES "public"."builder_pages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_accounting_configs"
    ADD CONSTRAINT "cajuia_accounting_configs_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."cajuia_accounts"("id");



ALTER TABLE ONLY "public"."cajuia_accounts"
    ADD CONSTRAINT "cajuia_accounts_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."cajuia_accounts"("id");



ALTER TABLE ONLY "public"."cajuia_bank_statements"
    ADD CONSTRAINT "cajuia_bank_statements_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."cajuia_accounts"("id");



ALTER TABLE ONLY "public"."cajuia_bank_statements"
    ADD CONSTRAINT "cajuia_bank_statements_imported_by_fkey" FOREIGN KEY ("imported_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_bank_transactions"
    ADD CONSTRAINT "cajuia_bank_transactions_matched_entry_id_fkey" FOREIGN KEY ("matched_entry_id") REFERENCES "public"."cajuia_journal_entries"("id");



ALTER TABLE ONLY "public"."cajuia_bank_transactions"
    ADD CONSTRAINT "cajuia_bank_transactions_statement_id_fkey" FOREIGN KEY ("statement_id") REFERENCES "public"."cajuia_bank_statements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_cash_movements"
    ADD CONSTRAINT "cajuia_cash_movements_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."cajuia_orders"("id");



ALTER TABLE ONLY "public"."cajuia_cash_movements"
    ADD CONSTRAINT "cajuia_cash_movements_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."cajuia_cash_sessions"("id");



ALTER TABLE ONLY "public"."cajuia_cash_movements"
    ADD CONSTRAINT "cajuia_cash_movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_cash_sessions"
    ADD CONSTRAINT "cajuia_cash_sessions_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id");



ALTER TABLE ONLY "public"."cajuia_cash_sessions"
    ADD CONSTRAINT "cajuia_cash_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_corte_tasks"
    ADD CONSTRAINT "cajuia_corte_tasks_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."cajuia_corte_tasks"
    ADD CONSTRAINT "cajuia_corte_tasks_stock_item_id_fkey" FOREIGN KEY ("stock_item_id") REFERENCES "public"."stock"("id");



ALTER TABLE ONLY "public"."cajuia_corte_tasks"
    ADD CONSTRAINT "cajuia_corte_tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_dashboard_layouts"
    ADD CONSTRAINT "cajuia_dashboard_layouts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_fiscal_docs"
    ADD CONSTRAINT "cajuia_fiscal_docs_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."cajuia_orders"("id");



ALTER TABLE ONLY "public"."cajuia_journal_entries"
    ADD CONSTRAINT "cajuia_journal_entries_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_journal_items"
    ADD CONSTRAINT "cajuia_journal_items_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."cajuia_accounts"("id");



ALTER TABLE ONLY "public"."cajuia_journal_items"
    ADD CONSTRAINT "cajuia_journal_items_cost_center_id_fkey" FOREIGN KEY ("cost_center_id") REFERENCES "public"."cajuia_cost_centers"("id");



ALTER TABLE ONLY "public"."cajuia_journal_items"
    ADD CONSTRAINT "cajuia_journal_items_journal_entry_id_fkey" FOREIGN KEY ("journal_entry_id") REFERENCES "public"."cajuia_journal_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_order_drafts"
    ADD CONSTRAINT "cajuia_order_drafts_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_order_drafts"
    ADD CONSTRAINT "cajuia_order_drafts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_order_items"
    ADD CONSTRAINT "cajuia_order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."cajuia_orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_order_items"
    ADD CONSTRAINT "cajuia_order_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."cajuia_products"("id");



ALTER TABLE ONLY "public"."cajuia_orders"
    ADD CONSTRAINT "cajuia_orders_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajuia_permissions"
    ADD CONSTRAINT "cajuia_permissions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_widgets"
    ADD CONSTRAINT "cajuia_widgets_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."catalog_stamp_collections"
    ADD CONSTRAINT "catalog_stamp_collections_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."catalog_collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_collections"
    ADD CONSTRAINT "catalog_stamp_collections_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_media"
    ADD CONSTRAINT "catalog_stamp_media_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_mockups"
    ADD CONSTRAINT "catalog_stamp_mockups_mockup_id_fkey" FOREIGN KEY ("mockup_id") REFERENCES "public"."catalog_mockups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_mockups"
    ADD CONSTRAINT "catalog_stamp_mockups_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_tags"
    ADD CONSTRAINT "catalog_stamp_tags_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamp_tags"
    ADD CONSTRAINT "catalog_stamp_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."catalog_tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."catalog_stamps"
    ADD CONSTRAINT "catalog_stamps_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."catalog_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."channel_members"
    ADD CONSTRAINT "channel_members_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "public"."channels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."channel_members"
    ADD CONSTRAINT "channel_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."channels"
    ADD CONSTRAINT "channels_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."client_transactions"
    ADD CONSTRAINT "client_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commerce_moodboard_items"
    ADD CONSTRAINT "commerce_moodboard_items_mockup_id_fkey" FOREIGN KEY ("mockup_id") REFERENCES "public"."catalog_mockups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."commerce_moodboard_items"
    ADD CONSTRAINT "commerce_moodboard_items_moodboard_id_fkey" FOREIGN KEY ("moodboard_id") REFERENCES "public"."commerce_moodboards"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commerce_moodboard_items"
    ADD CONSTRAINT "commerce_moodboard_items_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commerce_moodboards"
    ADD CONSTRAINT "commerce_moodboards_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."commerce_leads"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."commerce_quote_requests"
    ADD CONSTRAINT "commerce_quote_requests_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."commerce_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commerce_quote_requests"
    ADD CONSTRAINT "commerce_quote_requests_moodboard_id_fkey" FOREIGN KEY ("moodboard_id") REFERENCES "public"."commerce_moodboards"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."company_installed_apps"
    ADD CONSTRAINT "company_installed_apps_installed_by_fkey" FOREIGN KEY ("installed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."company_integrations"
    ADD CONSTRAINT "company_integrations_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crm_active_alerts"
    ADD CONSTRAINT "crm_active_alerts_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crm_lead_history"
    ADD CONSTRAINT "crm_lead_history_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."crm_lead_history"
    ADD CONSTRAINT "crm_lead_history_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."customer_tags"
    ADD CONSTRAINT "customer_tags_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."customers_mj"
    ADD CONSTRAINT "customers_mj_vendedor_responsavel_id_fkey" FOREIGN KEY ("vendedor_responsavel_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_assignment_requests"
    ADD CONSTRAINT "design_assignment_requests_designer_id_fkey" FOREIGN KEY ("designer_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_queue"
    ADD CONSTRAINT "design_queue_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_queue"
    ADD CONSTRAINT "design_queue_pending_order_id_fkey" FOREIGN KEY ("pending_order_id") REFERENCES "public"."pending_stock_orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."design_rejection_logs"
    ADD CONSTRAINT "design_rejection_logs_leader_id_fkey" FOREIGN KEY ("leader_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_requests"
    ADD CONSTRAINT "design_requests_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_requests"
    ADD CONSTRAINT "design_requests_designer_id_fkey" FOREIGN KEY ("designer_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."design_requests"
    ADD CONSTRAINT "design_requests_new_stamp_id_fkey" FOREIGN KEY ("new_stamp_id") REFERENCES "public"."stamp_library"("id");



ALTER TABLE ONLY "public"."design_requests"
    ADD CONSTRAINT "design_requests_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id");



ALTER TABLE ONLY "public"."design_user_permissions"
    ADD CONSTRAINT "design_user_permissions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."email_accounts"
    ADD CONSTRAINT "email_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."email_accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."employees_mj"
    ADD CONSTRAINT "employees_mj_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."employees_mj"
    ADD CONSTRAINT "employees_mj_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."finance_audit_logs"
    ADD CONSTRAINT "finance_audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."finance_chart_of_accounts"
    ADD CONSTRAINT "finance_chart_of_accounts_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."finance_chart_of_accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_invoice_payments"
    ADD CONSTRAINT "finance_invoice_payments_bank_account_id_fkey" FOREIGN KEY ("bank_account_id") REFERENCES "public"."finance_bank_accounts"("id");



ALTER TABLE ONLY "public"."finance_invoice_payments"
    ADD CONSTRAINT "finance_invoice_payments_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."finance_invoice_payments"
    ADD CONSTRAINT "finance_invoice_payments_receivable_id_fkey" FOREIGN KEY ("receivable_id") REFERENCES "public"."finance_receivables"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_bank_account_id_fkey" FOREIGN KEY ("bank_account_id") REFERENCES "public"."finance_accounts"("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_chart_of_accounts_id_fkey" FOREIGN KEY ("chart_of_accounts_id") REFERENCES "public"."finance_chart_of_accounts"("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_cost_center_id_fkey" FOREIGN KEY ("cost_center_id") REFERENCES "public"."finance_cost_centers"("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."finance_payment_methods"("id");



ALTER TABLE ONLY "public"."finance_payables"
    ADD CONSTRAINT "finance_payables_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "public"."customers_mj"("id");



ALTER TABLE ONLY "public"."finance_receivable_payments"
    ADD CONSTRAINT "finance_receivable_payments_bank_account_id_fkey" FOREIGN KEY ("bank_account_id") REFERENCES "public"."finance_bank_accounts"("id");



ALTER TABLE ONLY "public"."finance_receivable_payments"
    ADD CONSTRAINT "finance_receivable_payments_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."finance_receivable_payments"
    ADD CONSTRAINT "finance_receivable_payments_receivable_id_fkey" FOREIGN KEY ("receivable_id") REFERENCES "public"."finance_receivables"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_bank_account_id_fkey" FOREIGN KEY ("bank_account_id") REFERENCES "public"."finance_accounts"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_chart_of_accounts_id_fkey" FOREIGN KEY ("chart_of_accounts_id") REFERENCES "public"."finance_chart_of_accounts"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_cost_center_id_fkey" FOREIGN KEY ("cost_center_id") REFERENCES "public"."finance_cost_centers"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."finance_payment_methods"("id");



ALTER TABLE ONLY "public"."finance_receivables"
    ADD CONSTRAINT "finance_receivables_store_sale_id_fkey" FOREIGN KEY ("store_sale_id") REFERENCES "public"."store_sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_transactions"
    ADD CONSTRAINT "finance_transactions_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "public"."finance_accounts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fiscal_tax_rules"
    ADD CONSTRAINT "fiscal_tax_rules_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."admin_channel_members"
    ADD CONSTRAINT "fk_admin_channel_members_channel_id" FOREIGN KEY ("channel_id") REFERENCES "public"."admin_channels"("id");



ALTER TABLE ONLY "public"."admin_channel_members"
    ADD CONSTRAINT "fk_admin_channel_members_profile_id" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."admin_messages"
    ADD CONSTRAINT "fk_admin_messages_channel_id" FOREIGN KEY ("channel_id") REFERENCES "public"."admin_channels"("id");



ALTER TABLE ONLY "public"."admin_messages"
    ADD CONSTRAINT "fk_admin_messages_profile_id" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."cajuia_orders"
    ADD CONSTRAINT "fk_cajuia_orders_vendedor" FOREIGN KEY ("vendedor_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."mj_cash_sessions"
    ADD CONSTRAINT "fk_mj_cash_sessions_profiles" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "fk_orders_customer" FOREIGN KEY ("customer_id") REFERENCES "public"."customers_mj"("id");



ALTER TABLE ONLY "public"."cajuia_product_prices"
    ADD CONSTRAINT "fk_price_list" FOREIGN KEY ("price_list_id") REFERENCES "public"."cajuia_price_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cajuia_product_prices"
    ADD CONSTRAINT "fk_product" FOREIGN KEY ("product_id") REFERENCES "public"."cajuia_products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "fk_reply_to_message" FOREIGN KEY ("reply_to_message_id") REFERENCES "public"."messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."digital_purchases"
    ADD CONSTRAINT "fk_stamp" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fleet_refuelings"
    ADD CONSTRAINT "fleet_refuelings_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "public"."fleet_vehicles"("id");



ALTER TABLE ONLY "public"."fleet_vehicles"
    ADD CONSTRAINT "fleet_vehicles_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."label_presets"
    ADD CONSTRAINT "label_presets_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."marketplace_cart"
    ADD CONSTRAINT "marketplace_cart_fabric_id_fkey" FOREIGN KEY ("fabric_id") REFERENCES "public"."catalog_fabrics"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."marketplace_cart"
    ADD CONSTRAINT "marketplace_cart_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."marketplace_cart"
    ADD CONSTRAINT "marketplace_cart_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."marketplace_customers"
    ADD CONSTRAINT "marketplace_customers_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."marketplace_favorite_folders"
    ADD CONSTRAINT "marketplace_favorite_folders_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."marketplace_favorite_items"
    ADD CONSTRAINT "marketplace_favorite_items_folder_id_fkey" FOREIGN KEY ("folder_id") REFERENCES "public"."marketplace_favorite_folders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."marketplace_favorite_items"
    ADD CONSTRAINT "marketplace_favorite_items_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."marketplace_favorite_items"
    ADD CONSTRAINT "marketplace_favorite_items_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "public"."channels"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."mj_cash_movements"
    ADD CONSTRAINT "mj_cash_movements_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."mj_cash_movements"
    ADD CONSTRAINT "mj_cash_movements_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."mj_cash_sessions"("id");



ALTER TABLE ONLY "public"."mj_cash_movements"
    ADD CONSTRAINT "mj_cash_movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."mj_cash_sessions"
    ADD CONSTRAINT "mj_cash_sessions_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id");



ALTER TABLE ONLY "public"."mj_cash_sessions"
    ADD CONSTRAINT "mj_cash_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_drafts"
    ADD CONSTRAINT "order_drafts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_logs"
    ADD CONSTRAINT "order_logs_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."order_logs"
    ADD CONSTRAINT "order_logs_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_payments"
    ADD CONSTRAINT "order_payments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."order_payments"
    ADD CONSTRAINT "order_payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_cash_session_id_fkey" FOREIGN KEY ("cash_session_id") REFERENCES "public"."mj_cash_sessions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_designer_id_fkey" FOREIGN KEY ("designer_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."order_groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_invoiced_by_fkey" FOREIGN KEY ("invoiced_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pdv_product_prices"
    ADD CONSTRAINT "pdv_product_prices_price_list_id_fkey" FOREIGN KEY ("price_list_id") REFERENCES "public"."pdv_price_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pdv_product_prices"
    ADD CONSTRAINT "pdv_product_prices_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."stock"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pending_stock_orders"
    ADD CONSTRAINT "pending_stock_orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."pending_stock_orders"
    ADD CONSTRAINT "pending_stock_orders_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id");



ALTER TABLE ONLY "public"."pending_stock_orders"
    ADD CONSTRAINT "pending_stock_orders_target_order_id_fkey" FOREIGN KEY ("target_order_id") REFERENCES "public"."orders"("id");



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_customer_mj_id_fkey" FOREIGN KEY ("customer_mj_id") REFERENCES "public"."customers_mj"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_designer_id_fkey" FOREIGN KEY ("designer_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_fabric_id_fkey" FOREIGN KEY ("fabric_id") REFERENCES "public"."catalog_fabrics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_stamp_id_fkey" FOREIGN KEY ("stamp_id") REFERENCES "public"."catalog_stamps"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pilot_requests"
    ADD CONSTRAINT "pilot_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pilot_transactions"
    ADD CONSTRAINT "pilot_transactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."pilot_transactions"
    ADD CONSTRAINT "pilot_transactions_pilot_id_fkey" FOREIGN KEY ("pilot_id") REFERENCES "public"."pilot_requests"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."premium_access_events"
    ADD CONSTRAINT "premium_access_events_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."premium_sessions"
    ADD CONSTRAINT "premium_sessions_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."public_leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."production_logs"
    ADD CONSTRAINT "production_logs_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "public"."order_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."production_logs"
    ADD CONSTRAINT "production_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."production_schedule"
    ADD CONSTRAINT "production_schedule_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."production_schedule"
    ADD CONSTRAINT "production_schedule_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "public"."order_items"("id");



ALTER TABLE ONLY "public"."productivity_rules"
    ADD CONSTRAINT "productivity_rules_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_custom_role_id_fkey" FOREIGN KEY ("custom_role_id") REFERENCES "public"."custom_roles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."public_leads"
    ADD CONSTRAINT "public_leads_kanban_column_id_fkey" FOREIGN KEY ("kanban_column_id") REFERENCES "public"."crm_kanban_columns"("id");



ALTER TABLE ONLY "public"."purchase_items"
    ADD CONSTRAINT "purchase_items_purchase_id_fkey" FOREIGN KEY ("purchase_id") REFERENCES "public"."purchases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchase_items"
    ADD CONSTRAINT "purchase_items_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services_catalog"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sales_goals"
    ADD CONSTRAINT "sales_goals_seller_id_fkey" FOREIGN KEY ("seller_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."scheduled_orders"
    ADD CONSTRAINT "scheduled_orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."scheduled_orders"
    ADD CONSTRAINT "scheduled_orders_released_by_fkey" FOREIGN KEY ("released_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."seller_activities"
    ADD CONSTRAINT "seller_activities_seller_id_fkey" FOREIGN KEY ("seller_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."sre_audit_logs"
    ADD CONSTRAINT "sre_audit_logs_incident_id_fkey" FOREIGN KEY ("incident_id") REFERENCES "public"."sre_incidents"("id");



ALTER TABLE ONLY "public"."sre_audit_logs"
    ADD CONSTRAINT "sre_audit_logs_performed_by_fkey" FOREIGN KEY ("performed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."sre_incidents"
    ADD CONSTRAINT "sre_incidents_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."stamp_library"
    ADD CONSTRAINT "stamp_library_folder_id_fkey" FOREIGN KEY ("folder_id") REFERENCES "public"."stamp_folders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."stock_batches"
    ADD CONSTRAINT "stock_batches_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "public"."stock"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_ledger"
    ADD CONSTRAINT "stock_ledger_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "public"."stock_batches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."stock_ledger"
    ADD CONSTRAINT "stock_ledger_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."stock_ledger"
    ADD CONSTRAINT "stock_ledger_stock_id_fkey" FOREIGN KEY ("stock_id") REFERENCES "public"."stock"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "public"."order_items"("id");



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."stock"("id");



ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."stock"
    ADD CONSTRAINT "stock_tab_id_fkey" FOREIGN KEY ("tab_id") REFERENCES "public"."stock_tabs"("id");



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers_mj"("id");



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_seller_id_fkey" FOREIGN KEY ("seller_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."store_sales"
    ADD CONSTRAINT "store_sales_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id");



ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."system_audit_logs"
    ADD CONSTRAINT "system_audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."system_events"
    ADD CONSTRAINT "system_events_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."system_events"
    ADD CONSTRAINT "system_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_column_id_fkey" FOREIGN KEY ("column_id") REFERENCES "public"."project_columns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_extension_requests"
    ADD CONSTRAINT "time_extension_requests_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."time_extension_requests"
    ADD CONSTRAINT "time_extension_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_assignments"
    ADD CONSTRAINT "time_tracking_assignments_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_assignments"
    ADD CONSTRAINT "time_tracking_assignments_shift_template_id_fkey" FOREIGN KEY ("shift_template_id") REFERENCES "public"."time_tracking_shift_templates"("id");



ALTER TABLE ONLY "public"."time_tracking_corrections"
    ADD CONSTRAINT "time_tracking_corrections_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_kiosk_releases"
    ADD CONSTRAINT "time_tracking_kiosk_releases_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_kiosk_users"
    ADD CONSTRAINT "time_tracking_kiosk_users_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_kiosk_users"
    ADD CONSTRAINT "time_tracking_kiosk_users_kiosk_id_fkey" FOREIGN KEY ("kiosk_id") REFERENCES "public"."time_tracking_kiosks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_kiosks"
    ADD CONSTRAINT "time_tracking_kiosks_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_logs"
    ADD CONSTRAINT "time_tracking_logs_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_overrides"
    ADD CONSTRAINT "time_tracking_overrides_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_overtime_requests"
    ADD CONSTRAINT "time_tracking_overtime_requests_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."time_tracking_payroll_events"
    ADD CONSTRAINT "time_tracking_payroll_events_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees_mj"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_module_id_fkey" FOREIGN KEY ("module_id") REFERENCES "public"."training_modules"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_notification_dismissals"
    ADD CONSTRAINT "user_notification_dismissals_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."notifications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_notification_dismissals"
    ADD CONSTRAINT "user_notification_dismissals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_presences"
    ADD CONSTRAINT "user_presences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_screenshots"
    ADD CONSTRAINT "user_screenshots_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wa_conversations"
    ADD CONSTRAINT "wa_conversations_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."wa_messages"
    ADD CONSTRAINT "wa_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."wa_conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wa_messages"
    ADD CONSTRAINT "wa_messages_sender_profile_id_fkey" FOREIGN KEY ("sender_profile_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."work_schedules"
    ADD CONSTRAINT "work_schedules_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_assignments" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_corrections" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_kiosk_releases" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_overrides" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_overtime_requests" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_payroll_events" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso Total Autenticado" ON "public"."time_tracking_shift_templates" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso a configurações fiscais" ON "public"."cajuia_tax_settings" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso a documentos fiscais" ON "public"."cajuia_fiscal_docs" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total" ON "public"."company_installed_apps" USING (true);



CREATE POLICY "Acesso total a abastecimentos" ON "public"."fleet_refuelings" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso total a contas bancárias" ON "public"."cajuia_bank_accounts" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total a fornecedores" ON "public"."suppliers_mj" USING (true);



CREATE POLICY "Acesso total a frota" ON "public"."fleet_vehicles" USING (true) WITH CHECK (true);



CREATE POLICY "Acesso total a funcionarios" ON "public"."employees_mj" USING (true);



CREATE POLICY "Acesso total a integrações da própria loja" ON "public"."company_integrations" USING (true);



CREATE POLICY "Acesso total autenticado movements" ON "public"."mj_cash_movements" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total autenticado sessions" ON "public"."mj_cash_sessions" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total categorias" ON "public"."cajuia_expense_categories" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total contas financeiras" ON "public"."finance_accounts" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Acesso total extratos cajuia" ON "public"."cajuia_bank_statements" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total financeiro" ON "public"."finance_payables" USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total para administradores" ON "public"."client_design_deliveries" USING ((("auth"."role"() = 'service_role'::"text") OR ("auth"."role"() = 'authenticated'::"text")));



CREATE POLICY "Acesso total para admins" ON "public"."companies" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Acesso total purchase_items" ON "public"."purchase_items" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total purchases" ON "public"."purchases" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Acesso total transacoes cajuia" ON "public"."cajuia_bank_transactions" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Admins and Sales can view all orders" ON "public"."orders" FOR SELECT TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'vendedor'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Admins can manage payments" ON "public"."finance_receivable_payments" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Admins can manage permissions" ON "public"."cajuia_permissions" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins can manage productivity rules" ON "public"."productivity_rules" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins can see all" ON "public"."finance_receivables" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can update all orders" ON "public"."orders" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Admins can update any profile" ON "public"."profiles" FOR UPDATE USING ((( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Admins can view all orders" ON "public"."orders" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Admins e Super Admins Full Access" ON "public"."finance_bank_accounts" TO "authenticated" USING ("public"."is_admin_or_super"()) WITH CHECK ("public"."is_admin_or_super"());



CREATE POLICY "Admins e Super Admins Full Access" ON "public"."finance_chart_of_accounts" TO "authenticated" USING ("public"."is_admin_or_super"()) WITH CHECK ("public"."is_admin_or_super"());



CREATE POLICY "Admins e Super Admins Full Access" ON "public"."finance_payment_methods" TO "authenticated" USING ("public"."is_admin_or_super"()) WITH CHECK ("public"."is_admin_or_super"());



CREATE POLICY "Admins e Super Admins Full Access" ON "public"."finance_receivables" TO "authenticated" USING ("public"."is_admin_or_super"()) WITH CHECK ("public"."is_admin_or_super"());



CREATE POLICY "Admins full access stores" ON "public"."stores" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Admins podem atualizar qualquer chamado" ON "public"."design_requests" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Admins podem ler todas as atividades" ON "public"."user_activity" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins total acesso compras" ON "public"."digital_purchases" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Admins total acesso pedidos" ON "public"."store_orders" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow Cajuia admins to MANAGE products" ON "public"."cajuia_products" USING ((("public"."get_my_cajuia_role"() = 'admin_cajuia'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"))) WITH CHECK ((("public"."get_my_cajuia_role"() = 'admin_cajuia'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")));



CREATE POLICY "Allow Cajuia users to SELECT products" ON "public"."cajuia_products" FOR SELECT USING ((("public"."get_my_cajuia_role"() = ANY (ARRAY['admin_cajuia'::"text", 'vendedor_cajuia'::"text"])) OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")));



CREATE POLICY "Allow Cajuia users to manage order items" ON "public"."cajuia_order_items" USING ((("public"."get_my_cajuia_role"() = ANY (ARRAY['admin_cajuia'::"text", 'vendedor_cajuia'::"text"])) OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"))) WITH CHECK ((("public"."get_my_cajuia_role"() = ANY (ARRAY['admin_cajuia'::"text", 'vendedor_cajuia'::"text"])) OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")));



CREATE POLICY "Allow Cajuia users to manage orders" ON "public"."cajuia_orders" USING ((("public"."get_my_cajuia_role"() = ANY (ARRAY['admin_cajuia'::"text", 'vendedor_cajuia'::"text"])) OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"))) WITH CHECK ((("public"."get_my_cajuia_role"() = ANY (ARRAY['admin_cajuia'::"text", 'vendedor_cajuia'::"text"])) OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")));



CREATE POLICY "Allow access based on role (Payments)" ON "public"."finance_receivable_payments" USING ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_receivable_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"()))))))) WITH CHECK ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_receivable_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"())))))));



CREATE POLICY "Allow access based on role (Receivables)" ON "public"."finance_receivables" USING ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND ("created_by" = "auth"."uid"())))) WITH CHECK ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND ("created_by" = "auth"."uid"()))));



CREATE POLICY "Allow admin full access" ON "public"."price_list" TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow admin full access" ON "public"."time_extension_requests" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow admin full access" ON "public"."work_schedules" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow admin read access on reports" ON "public"."daily_stock_reports" FOR SELECT TO "authenticated" USING (("public"."get_my_claim"('user_role'::"text") = '"admin"'::"jsonb"));



CREATE POLICY "Allow admin to manage scheduled orders" ON "public"."scheduled_orders" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Allow admins and designers to manage folders" ON "public"."stamp_folders" TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'designer'::"public"."user_role"])));



CREATE POLICY "Allow admins full access to customer_tags" ON "public"."customer_tags" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Allow admins full access to customers" ON "public"."customers" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Allow admins full access to sales_goals" ON "public"."sales_goals" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "Allow admins to read all screenshot records" ON "public"."user_screenshots" FOR SELECT USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow admins to read seller activities" ON "public"."seller_activities" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Allow admins to update products" ON "public"."products" FOR UPDATE USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow admins to update profiles" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))) WITH CHECK ((( SELECT "profiles_1"."role"
   FROM "public"."profiles" "profiles_1"
  WHERE ("profiles_1"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Allow all authenticated users" ON "public"."pdv_price_lists" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Allow all authenticated users" ON "public"."pdv_product_prices" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Allow authenticated read access" ON "public"."app_config" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow authenticated read access to products" ON "public"."products" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow authenticated users to add members to channels" ON "public"."channel_members" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."channels"
  WHERE (("channels"."id" = "channel_members"."channel_id") AND ("channels"."created_by" = "auth"."uid"())))) OR ("profile_id" = "auth"."uid"())));



CREATE POLICY "Allow authenticated users to add members to their channels or s" ON "public"."channel_members" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."channels"
  WHERE (("channels"."id" = "channel_members"."channel_id") AND ("channels"."created_by" = "auth"."uid"())))) OR ("profile_id" = "auth"."uid"())));



CREATE POLICY "Allow authenticated users to create order logs" ON "public"."order_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated users to create their own channels" ON "public"."channels" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Allow authenticated users to edit their own messages" ON "public"."messages" FOR UPDATE TO "authenticated" USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "Allow authenticated users to insert design requests" ON "public"."design_requests" FOR INSERT WITH CHECK ((("public"."get_my_role"() = ANY (ARRAY['vendedor'::"text", 'admin'::"text"])) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Allow authenticated users to insert their own orders" ON "public"."orders" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Allow authenticated users to read folders" ON "public"."stamp_folders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read modules" ON "public"."training_modules" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read order logs" ON "public"."order_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read schedule" ON "public"."production_schedule" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read stock" ON "public"."stock" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to read stores" ON "public"."stores" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated users to remove members from channels" ON "public"."channel_members" FOR DELETE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."channels"
  WHERE (("channels"."id" = "channel_members"."channel_id") AND ("channels"."created_by" = "auth"."uid"())))) OR ("profile_id" = "auth"."uid"())));



CREATE POLICY "Allow authenticated users to remove members from their channels" ON "public"."channel_members" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."channels"
  WHERE (("channels"."id" = "channel_members"."channel_id") AND ("channels"."created_by" = "auth"."uid"())))));



CREATE POLICY "Allow authenticated users to soft delete their own messages" ON "public"."messages" FOR UPDATE TO "authenticated" USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "Allow authenticated users to update schedule entries" ON "public"."production_schedule" FOR UPDATE USING (true) WITH CHECK (true);



CREATE POLICY "Allow authenticated users to update their own profiles" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Allow authenticated users to view all profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow creator, designers and admins to view" ON "public"."design_requests" FOR SELECT USING ((("created_by" = "auth"."uid"()) OR ("public"."get_my_role"() = ANY (ARRAY['designer'::"text", 'admin'::"text"]))));



CREATE POLICY "Allow delete for admins only" ON "public"."order_payments" FOR DELETE USING (("public"."get_my_role"() = 'admin'::"text"));



CREATE POLICY "Allow designers and admins to see all" ON "public"."design_queue" FOR SELECT USING (("public"."get_my_role"() = ANY (ARRAY['designer'::"text", 'admin'::"text"])));



CREATE POLICY "Allow designers and admins to update" ON "public"."design_requests" FOR UPDATE USING (("public"."get_my_role"() = ANY (ARRAY['designer'::"text", 'admin'::"text"]))) WITH CHECK (("public"."get_my_role"() = ANY (ARRAY['designer'::"text", 'admin'::"text"])));



CREATE POLICY "Allow full control for owner and admins" ON "public"."pending_stock_orders" USING ((("auth"."uid"() = "created_by") OR "public"."is_admin"())) WITH CHECK ((("auth"."uid"() = "created_by") OR "public"."is_admin"()));



CREATE POLICY "Allow global admins to manage permissions" ON "public"."cajuia_permissions" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role")) WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role"));



CREATE POLICY "Allow individual user update" ON "public"."user_presences" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow individual user update on channel_members" ON "public"."channel_members" FOR UPDATE USING (("auth"."uid"() = "profile_id")) WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Allow insert for sellers and admins" ON "public"."order_payments" FOR INSERT WITH CHECK ((("public"."get_my_role"() = ANY (ARRAY['admin'::"text", 'vendedor'::"text"])) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "Allow members to read messages in their channels" ON "public"."messages" FOR SELECT USING (("channel_id" IN ( SELECT "channel_members"."channel_id"
   FROM "public"."channel_members"
  WHERE ("channel_members"."profile_id" = "auth"."uid"()))));



CREATE POLICY "Allow members to send messages in their channels" ON "public"."messages" FOR INSERT WITH CHECK (("channel_id" IN ( SELECT "channel_members"."channel_id"
   FROM "public"."channel_members"
  WHERE ("channel_members"."profile_id" = "auth"."uid"()))));



CREATE POLICY "Allow members to view their own channels" ON "public"."channels" FOR SELECT USING ((("is_private_dm" AND ("dm_participant_ids" @> ARRAY["auth"."uid"()])) OR ("id" IN ( SELECT "channel_members"."channel_id"
   FROM "public"."channel_members"
  WHERE ("channel_members"."profile_id" = "auth"."uid"())))));



CREATE POLICY "Allow owner to manage their items" ON "public"."design_queue" USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Allow read access to related users" ON "public"."order_payments" FOR SELECT USING (("public"."get_my_role"() = ANY (ARRAY['admin'::"text", 'vendedor'::"text"])));



CREATE POLICY "Allow read/write for authenticated" ON "public"."store_sales" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Allow relevant roles to insert notifications" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'vendedor'::"public"."user_role", 'designer'::"public"."user_role", 'producao'::"public"."user_role"])));



CREATE POLICY "Allow relevant roles to view active orders" ON "public"."orders" FOR SELECT TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'vendedor'::"public"."user_role", 'designer'::"public"."user_role", 'producao'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Allow sellers and admins to manage invoice payments" ON "public"."finance_invoice_payments" USING ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_invoice_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"()))))))) WITH CHECK ((("public"."get_my_role"() = 'admin'::"text") OR (("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_invoice_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"())))))));



CREATE POLICY "Allow sellers to manage their own activities" ON "public"."seller_activities" USING (("auth"."uid"() = "seller_id")) WITH CHECK (("auth"."uid"() = "seller_id"));



CREATE POLICY "Allow sellers to see their own scheduled orders" ON "public"."scheduled_orders" FOR SELECT TO "authenticated" USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Allow sellers to view their region's prices" ON "public"."price_list" FOR SELECT TO "authenticated" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'vendedor'::"public"."user_role") AND (( SELECT "profiles"."allowed_regions"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) IS NOT NULL)));



CREATE POLICY "Allow service role to insert screenshot records" ON "public"."user_screenshots" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow service role to read for realtime" ON "public"."pending_stock_orders" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow specific roles to create schedule entries" ON "public"."production_schedule" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'vendedor'::"public"."user_role", 'designer'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Allow update by creator or admin" ON "public"."order_payments" FOR UPDATE USING ((("created_by" = "auth"."uid"()) OR ("public"."get_my_role"() = 'admin'::"text"))) WITH CHECK ((("created_by" = "auth"."uid"()) OR ("public"."get_my_role"() = 'admin'::"text")));



CREATE POLICY "Allow user read own schedules" ON "public"."work_schedules" FOR SELECT USING ((("auth"."uid"() = "user_id") OR ("is_general" = true)));



CREATE POLICY "Allow user to create and read own requests" ON "public"."time_extension_requests" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to insert their own presence" ON "public"."user_presences" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to insert their own progress" ON "public"."training_progress" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to see other users presence" ON "public"."user_presences" FOR SELECT USING (true);



CREATE POLICY "Allow users to see their own channel memberships" ON "public"."channel_members" FOR SELECT USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "Allow users to see their own permission" ON "public"."cajuia_permissions" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Allow users to see their own progress" ON "public"."training_progress" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Allow users to update their own presence" ON "public"."user_presences" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Apenas admins podem visualizar logs" ON "public"."audit_logs" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Atendentes podem gerenciar mensagens de suas conversas" ON "public"."wa_messages" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role") OR (( SELECT "count"(*) AS "count"
   FROM "public"."wa_conversations"
  WHERE ("wa_conversations"."id" = "wa_messages"."conversation_id")) > 0))) WITH CHECK (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role") OR (( SELECT "count"(*) AS "count"
   FROM "public"."wa_conversations"
  WHERE ("wa_conversations"."id" = "wa_messages"."conversation_id")) > 0)));



CREATE POLICY "Atendentes podem gerenciar suas próprias conversas" ON "public"."wa_conversations" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role") OR ("assigned_to" = "auth"."uid"()))) WITH CHECK (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'admin'::"public"."user_role") OR ("assigned_to" = "auth"."uid"())));



CREATE POLICY "Auth insert finance logs" ON "public"."finance_audit_logs" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Auth read finance logs" ON "public"."finance_audit_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."admin_channel_members" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."admin_channels" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."admin_messages" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."app_config" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."audit_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_accounting_configs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_bank_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_bank_statements" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_bank_transactions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_cash_movements" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_cash_sessions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_categories" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_clients" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_corte_tasks" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_cost_centers" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_dashboard_layouts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_expense_categories" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_fiscal_docs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_journal_entries" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_journal_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_order_drafts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_order_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_orders" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_payables" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_permissions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_price_lists" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_product_prices" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_products" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_receivables" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_tax_settings" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."cajuia_widgets" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."channel_members" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."channels" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."companies" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."company_installed_apps" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."company_integrations" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."custom_roles" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."customer_tags" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."customers" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."customers_mj" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."daily_stock_reports" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."debug_payload_log" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."design_queue" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."design_requests" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."dfe_entries" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."employees_mj" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_audit_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_bank_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_chart_of_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_charts_of_accounts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_cost_centers" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_invoice_payments" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_payables" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_payment_methods" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_receivable_payments" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_receivables" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."finance_transactions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."fiscal_companies" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."fleet_refuelings" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."fleet_vehicles" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."mj_cash_movements" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."mj_cash_sessions" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."mj_expense_categories" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."mj_payables" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."nfce_outbound" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."nfe_outbound" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."order_drafts" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."order_groups" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."order_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."order_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."order_payments" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."orders" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."pending_stock_orders" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."price_list" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."product_details" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."production_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."production_machines" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."production_schedule" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."productivity_rules" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."products" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."project_columns" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."purchase_items" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."purchases" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."sales_goals" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."scheduled_orders" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."seller_activities" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."services_catalog" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stamp_folders" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stamp_library" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stock" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stock_movements" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stock_tabs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."store_sales" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."stores" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."suppliers_mj" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."system_audit_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."tasks" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."time_extension_requests" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."training_modules" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."training_progress" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_activity" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_notification_dismissals" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_preferences" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_presences" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_reports" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."user_screenshots" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."wa_conversations" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."wa_messages" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Criar Autenticados" ON "public"."work_schedules" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."admin_channel_members" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."admin_channels" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."admin_messages" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."app_config" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."audit_logs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_accounting_configs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_bank_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_bank_statements" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_bank_transactions" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_cash_movements" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_cash_sessions" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_categories" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_clients" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_corte_tasks" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_cost_centers" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_dashboard_layouts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_expense_categories" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_fiscal_docs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_journal_entries" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_journal_items" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_order_drafts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_order_items" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_orders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_payables" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_permissions" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_price_lists" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_product_prices" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_products" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_receivables" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_tax_settings" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."cajuia_widgets" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."channel_members" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."channels" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."companies" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."company_installed_apps" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."company_integrations" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."custom_roles" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."customer_tags" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."customers" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."customers_mj" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."daily_stock_reports" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."debug_payload_log" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."design_queue" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."design_requests" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."dfe_entries" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."employees_mj" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_audit_logs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_bank_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_chart_of_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_charts_of_accounts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_cost_centers" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_invoice_payments" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_payables" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_payment_methods" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_receivable_payments" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_receivables" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."finance_transactions" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."fiscal_companies" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."fleet_refuelings" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."fleet_vehicles" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."messages" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."mj_cash_movements" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."mj_cash_sessions" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."mj_expense_categories" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."mj_payables" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."nfce_outbound" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."nfe_outbound" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."notifications" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."order_drafts" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."order_groups" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."order_items" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."order_logs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."order_payments" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."orders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."pending_stock_orders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."price_list" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."product_details" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."production_logs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."production_machines" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."production_schedule" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."productivity_rules" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."products" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."project_columns" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."purchase_items" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."purchases" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."sales_goals" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."scheduled_orders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."seller_activities" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."services_catalog" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stamp_folders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stamp_library" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stock" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stock_movements" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stock_tabs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."store_sales" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."stores" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."suppliers_mj" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."system_audit_logs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."tasks" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."time_extension_requests" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."training_modules" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."training_progress" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_activity" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_notification_dismissals" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_preferences" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_presences" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_reports" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."user_screenshots" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."wa_conversations" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."wa_messages" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Editar Autenticados" ON "public"."work_schedules" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."admin_channel_members" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."admin_channels" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."admin_messages" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."app_config" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."audit_logs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_accounting_configs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_bank_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_bank_statements" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_bank_transactions" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_cash_movements" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_cash_sessions" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_categories" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_clients" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_corte_tasks" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_cost_centers" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_dashboard_layouts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_expense_categories" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_fiscal_docs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_journal_entries" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_journal_items" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_order_drafts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_order_items" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_orders" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_payables" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_permissions" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_price_lists" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_product_prices" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_products" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_receivables" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_tax_settings" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."cajuia_widgets" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."channel_members" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."channels" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."companies" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."company_installed_apps" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."company_integrations" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."custom_roles" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."customer_tags" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."customers" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."customers_mj" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."daily_stock_reports" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."debug_payload_log" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."design_queue" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."design_requests" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."dfe_entries" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."employees_mj" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_audit_logs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_bank_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_chart_of_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_charts_of_accounts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_cost_centers" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_invoice_payments" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_payables" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_payment_methods" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_receivable_payments" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_receivables" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."finance_transactions" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."fiscal_companies" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."fleet_refuelings" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."fleet_vehicles" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."messages" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."mj_cash_movements" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."mj_cash_sessions" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."mj_expense_categories" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."mj_payables" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."nfce_outbound" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."nfe_outbound" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."notifications" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."order_drafts" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."order_groups" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."order_items" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."order_logs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."order_payments" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."orders" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."pending_stock_orders" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."price_list" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."product_details" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."production_logs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."production_machines" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."production_schedule" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."productivity_rules" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."products" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."profiles" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."project_columns" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."purchase_items" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."purchases" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."sales_goals" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."scheduled_orders" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."seller_activities" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."services_catalog" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stamp_folders" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stamp_library" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stock" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stock_movements" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stock_tabs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."store_sales" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."stores" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."suppliers_mj" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."system_audit_logs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."tasks" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."time_extension_requests" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."training_modules" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."training_progress" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_activity" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_notification_dismissals" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_preferences" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_presences" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_reports" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."user_screenshots" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."wa_conversations" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."wa_messages" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Excluir Base Permissiva" ON "public"."work_schedules" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."admin_channel_members" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."admin_channels" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."admin_messages" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."app_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."audit_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_accounting_configs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_bank_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_bank_statements" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_bank_transactions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_cash_movements" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_cash_sessions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_categories" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_clients" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_corte_tasks" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_cost_centers" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_dashboard_layouts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_expense_categories" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_fiscal_docs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_journal_entries" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_journal_items" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_order_drafts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_order_items" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_orders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_payables" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_price_lists" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_product_prices" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_products" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_receivables" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_tax_settings" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."cajuia_widgets" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."channel_members" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."channels" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."companies" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."company_installed_apps" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."company_integrations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."custom_roles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."customer_tags" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."customers" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."customers_mj" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."daily_stock_reports" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."debug_payload_log" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."design_queue" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."design_requests" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."dfe_entries" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."employees_mj" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_audit_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_bank_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_chart_of_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_charts_of_accounts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_cost_centers" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_invoice_payments" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_payables" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_payment_methods" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_receivable_payments" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_receivables" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."finance_transactions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."fiscal_companies" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."fleet_refuelings" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."fleet_vehicles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."messages" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."mj_cash_movements" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."mj_cash_sessions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."mj_expense_categories" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."mj_payables" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."nfce_outbound" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."nfe_outbound" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."notifications" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."order_drafts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."order_groups" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."order_items" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."order_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."order_payments" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."orders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."pending_stock_orders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."price_list" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."product_details" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."production_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."production_machines" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."production_schedule" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."productivity_rules" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."products" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."project_columns" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."purchase_items" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."purchases" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."sales_goals" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."scheduled_orders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."seller_activities" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."services_catalog" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stamp_folders" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stamp_library" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stock" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stock_movements" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stock_tabs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."store_sales" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."stores" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."suppliers_mj" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."system_audit_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."tasks" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."time_extension_requests" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."training_modules" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."training_progress" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_activity" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_notification_dismissals" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_preferences" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_presences" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_reports" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."user_screenshots" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."wa_conversations" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."wa_messages" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Auto: Ler Autenticados" ON "public"."work_schedules" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."admin_channel_members" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('admin_channel_members'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."admin_channels" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('admin_channels'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."admin_messages" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('admin_messages'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."app_config" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('app_config'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."audit_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('audit_logs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_accounting_configs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_accounting_configs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_bank_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_bank_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_bank_statements" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_bank_statements'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_bank_transactions" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_bank_transactions'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_cash_movements" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_cash_movements'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_cash_sessions" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_cash_sessions'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_categories" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_categories'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_clients" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_clients'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_corte_tasks" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_corte_tasks'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_cost_centers" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_cost_centers'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_dashboard_layouts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_dashboard_layouts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_expense_categories" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_expense_categories'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_fiscal_docs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_fiscal_docs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_journal_entries" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_journal_entries'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_journal_items" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_journal_items'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_order_drafts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_order_drafts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_order_items" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_order_items'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_orders" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_orders'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_payables" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_payables'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_permissions" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_permissions'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_price_lists" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_price_lists'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_product_prices" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_product_prices'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_products" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_products'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_receivables" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_receivables'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_tax_settings" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_tax_settings'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."cajuia_widgets" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('cajuia_widgets'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."channel_members" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('channel_members'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."channels" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('channels'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."companies" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('companies'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."company_installed_apps" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('company_installed_apps'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."company_integrations" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('company_integrations'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."custom_roles" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('custom_roles'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."customer_tags" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('customer_tags'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."customers" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('customers'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."customers_mj" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('customers_mj'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."daily_stock_reports" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('daily_stock_reports'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."debug_payload_log" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('debug_payload_log'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."design_queue" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('design_queue'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."design_requests" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('design_requests'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."dfe_entries" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('dfe_entries'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."employees_mj" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('employees_mj'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_audit_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_audit_logs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_bank_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_bank_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_chart_of_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_chart_of_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_charts_of_accounts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_charts_of_accounts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_cost_centers" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_cost_centers'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_invoice_payments" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_invoice_payments'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_payables" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_payables'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_payment_methods" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_payment_methods'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_receivable_payments" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_receivable_payments'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_receivables" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_receivables'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."finance_transactions" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('finance_transactions'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."fiscal_companies" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('fiscal_companies'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."fleet_refuelings" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('fleet_refuelings'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."fleet_vehicles" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('fleet_vehicles'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."messages" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('messages'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."mj_cash_movements" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('mj_cash_movements'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."mj_cash_sessions" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('mj_cash_sessions'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."mj_expense_categories" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('mj_expense_categories'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."mj_payables" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('mj_payables'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."nfce_outbound" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('nfce_outbound'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."nfe_outbound" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('nfe_outbound'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."notifications" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('notifications'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."order_drafts" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('order_drafts'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."order_groups" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('order_groups'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."order_items" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('order_items'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."order_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('order_logs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."order_payments" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('order_payments'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."orders" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('orders'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."pending_stock_orders" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('pending_stock_orders'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."price_list" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('price_list'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."product_details" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('product_details'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."production_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('production_logs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."production_machines" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('production_machines'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."production_schedule" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('production_schedule'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."productivity_rules" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('productivity_rules'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."products" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('products'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."profiles" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('profiles'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."project_columns" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('project_columns'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."purchase_items" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('purchase_items'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."purchases" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('purchases'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."sales_goals" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('sales_goals'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."scheduled_orders" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('scheduled_orders'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."seller_activities" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('seller_activities'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."services_catalog" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('services_catalog'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stamp_folders" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stamp_folders'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stamp_library" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stamp_library'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stock" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stock'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stock_movements" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stock_movements'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stock_tabs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stock_tabs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."store_sales" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('store_sales'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."stores" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('stores'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."suppliers_mj" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('suppliers_mj'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."system_audit_logs" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('system_audit_logs'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."tasks" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('tasks'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."time_extension_requests" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('time_extension_requests'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."training_modules" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('training_modules'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."training_progress" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('training_progress'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_activity" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_activity'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_notification_dismissals" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_notification_dismissals'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_preferences" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_preferences'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_presences" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_presences'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_reports" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_reports'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."user_screenshots" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('user_screenshots'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."wa_conversations" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('wa_conversations'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."wa_messages" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('wa_messages'::"text"));



CREATE POLICY "Bloqueio Absoluto de Exclusao" ON "public"."work_schedules" AS RESTRICTIVE FOR DELETE TO "authenticated" USING ("public"."has_delete_permission"('work_schedules'::"text"));



CREATE POLICY "Clientes podem ver suas proprias transacoes" ON "public"."client_transactions" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Clientes veem apenas suas próprias entregas" ON "public"."client_design_deliveries" FOR SELECT USING ((("auth"."jwt"() ->> 'email'::"text") = "client_email"));



CREATE POLICY "Clientes veem seus proprios pedidos" ON "public"."store_orders" FOR SELECT USING ((("auth"."jwt"() ->> 'email'::"text") = "client_email"));



CREATE POLICY "Clientes veem suas proprias compras" ON "public"."digital_purchases" FOR SELECT USING ((("auth"."jwt"() ->> 'email'::"text") = "client_email"));



CREATE POLICY "Criar Widgets" ON "public"."cajuia_widgets" FOR INSERT WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Designers can manage delivery logistics" ON "public"."orders" FOR UPDATE TO "authenticated" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'designer'::"public"."user_role") AND ("status" = ANY (ARRAY['ready_for_delivery'::"text", 'completed'::"text", 'delivered'::"text"])))) WITH CHECK (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'designer'::"public"."user_role") AND ("status" = ANY (ARRAY['ready_for_delivery'::"text", 'completed'::"text", 'delivered'::"text"]))));



CREATE POLICY "Designers can move orders" ON "public"."orders" FOR UPDATE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'designer'::"public"."user_role")))) AND ("status" = ANY (ARRAY['design_pending'::"text", 'in_design'::"text", 'changes_requested'::"text", 'finalizing'::"text", 'customer_approval'::"text"]))));



CREATE POLICY "Designers can view design-related orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'designer'::"public"."user_role") AND ("status" = ANY (ARRAY['design_pending'::"text", 'in_design'::"text", 'changes_requested'::"text", 'finalizing'::"text", 'customer_approval'::"text"]))));



CREATE POLICY "Designers can view their kanban orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'designer'::"public"."user_role")))) AND ("status" = ANY (ARRAY['design_pending'::"text", 'in_design'::"text", 'changes_requested'::"text", 'finalizing'::"text", 'customer_approval'::"text"]))));



CREATE POLICY "Designers podem inserir clones" ON "public"."design_requests" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable access to all users" ON "public"."stores" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access" ON "public"."nfce_outbound" USING (true) WITH CHECK (true);



CREATE POLICY "Enable all access to stores" ON "public"."stores" USING (true) WITH CHECK (true);



CREATE POLICY "Enable delete for authenticated users" ON "public"."stock_batches" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Enable delete for authenticated users only" ON "public"."stamp_library" FOR DELETE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable delete for users based on user_id" ON "public"."order_drafts" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Enable insert for authenticated users" ON "public"."order_drafts" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Enable insert for authenticated users" ON "public"."stock_batches" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users" ON "public"."stock_ledger" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable insert for authenticated users only" ON "public"."production_logs" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable insert for authenticated users only" ON "public"."stamp_library" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable read access for all authenticated users" ON "public"."order_drafts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."stamp_library" FOR SELECT USING (true);



CREATE POLICY "Enable read access for authenticated users" ON "public"."stock_batches" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read access for authenticated users" ON "public"."stock_ledger" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable read for authenticated users only" ON "public"."production_logs" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable update for authenticated users" ON "public"."stock_batches" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Enable update for authenticated users only" ON "public"."stamp_library" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Enable update for users based on user_id" ON "public"."order_drafts" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Escrita para admin/producao" ON "public"."production_machines" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Everyone can read stores" ON "public"."stores" FOR SELECT USING (true);



CREATE POLICY "Faturador e Impressor veem itens" ON "public"."order_items" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'faturador'::"public"."user_role", 'impressor'::"public"."user_role"]))))) OR (EXISTS ( SELECT 1
   FROM "public"."orders"
  WHERE (("orders"."id" = "order_items"."order_id") AND ("orders"."created_by" = "auth"."uid"()))))));



CREATE POLICY "Faturador e Impressor veem todos pedidos" ON "public"."orders" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'faturador'::"public"."user_role", 'impressor'::"public"."user_role"]))))) OR ("created_by" = "auth"."uid"())));



CREATE POLICY "Faturador gerencia recebiveis" ON "public"."finance_receivables" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'faturador'::"public"."user_role"]))))));



CREATE POLICY "Faturador pode atualizar pedidos" ON "public"."orders" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'faturador'::"public"."user_role"]))))));



CREATE POLICY "Faturador ve clientes" ON "public"."customers_mj" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'faturador'::"public"."user_role", 'vendedor'::"public"."user_role", 'designer'::"public"."user_role", 'impressor'::"public"."user_role"]))))));



CREATE POLICY "Financeiro ver clientes" ON "public"."customers_mj" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'role'::"text") = 'financeiro'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'financeiro'::"public"."user_role")));



CREATE POLICY "Financeiro ver dfe" ON "public"."dfe_entries" TO "authenticated" USING (((("auth"."jwt"() ->> 'role'::"text") = 'financeiro'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'financeiro'::"public"."user_role")));



CREATE POLICY "Financeiro ver pedidos" ON "public"."orders" FOR SELECT TO "authenticated" USING (((("auth"."jwt"() ->> 'role'::"text") = 'financeiro'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'financeiro'::"public"."user_role")));



CREATE POLICY "Financeiro ver recebiveis" ON "public"."finance_receivables" TO "authenticated" USING (((("auth"."jwt"() ->> 'role'::"text") = 'financeiro'::"text") OR (( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'financeiro'::"public"."user_role")));



CREATE POLICY "Gerenciar Layout" ON "public"."cajuia_dashboard_layouts" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Insercao liberada geral" ON "public"."pilot_transactions" FOR INSERT WITH CHECK (true);



CREATE POLICY "Leitura global de eventos" ON "public"."security_events_log" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Leitura global de seguranca" ON "public"."security_profiles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Leitura liberada geral" ON "public"."pilot_transactions" FOR SELECT USING (true);



CREATE POLICY "Leitura para logados" ON "public"."production_machines" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Leitura para todos autenticados" ON "public"."companies" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Marketplace: Cliente atualiza próprio perfil" ON "public"."marketplace_customers" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Marketplace: Cliente insere próprio perfil" ON "public"."marketplace_customers" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Marketplace: Cliente lê próprio perfil" ON "public"."marketplace_customers" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Modificar regras" ON "public"."fiscal_tax_rules" USING (true);



CREATE POLICY "Nova Permissao: Editar Estoque" ON "public"."stock" FOR UPDATE TO "authenticated" USING ("public"."has_screen_permission"('prod_stock'::"text")) WITH CHECK ("public"."has_screen_permission"('prod_stock'::"text"));



CREATE POLICY "Nova Permissao: Excluir Estoque" ON "public"."stock" FOR DELETE TO "authenticated" USING ("public"."has_screen_permission"('prod_stock'::"text"));



CREATE POLICY "Nova Permissao: Inserir Estoque" ON "public"."stock" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_screen_permission"('prod_stock'::"text"));



CREATE POLICY "Nova Permissao: Visualizar Estoque" ON "public"."stock" FOR SELECT TO "authenticated" USING ("public"."has_screen_permission"('prod_stock'::"text"));



CREATE POLICY "Permite edicao de tarefas de corte" ON "public"."cajuia_corte_tasks" USING (("public"."has_permission"('operacional_corte'::"text") OR "public"."has_permission"('admin_general'::"text"))) WITH CHECK (("public"."has_permission"('operacional_corte'::"text") OR "public"."has_permission"('admin_general'::"text")));



CREATE POLICY "Permite leitura de estoque" ON "public"."stock" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Permite leitura de tarefas de corte" ON "public"."cajuia_corte_tasks" FOR SELECT USING (("public"."has_permission"('operacional_corte'::"text") OR "public"."has_permission"('admin_general'::"text")));



CREATE POLICY "Permitir Atualização de Pedidos (Financeiro/Admin)" ON "public"."orders" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir Insert do proprio lead" ON "public"."public_leads" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."jwt"() ->> 'email'::"text") = "email"));



CREATE POLICY "Permitir Leitura de NFCe para Todos Autenticados" ON "public"."nfce_outbound" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir Select do proprio lead" ON "public"."public_leads" FOR SELECT TO "authenticated" USING ((("auth"."jwt"() ->> 'email'::"text") = "email"));



CREATE POLICY "Permitir Update do proprio lead" ON "public"."public_leads" FOR UPDATE TO "authenticated" USING ((("auth"."jwt"() ->> 'email'::"text") = "email")) WITH CHECK ((("auth"."jwt"() ->> 'email'::"text") = "email"));



CREATE POLICY "Permitir acesso total ao Kiosk Users" ON "public"."time_tracking_kiosk_users" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total aos feriados para usuários autenticados" ON "public"."time_tracking_holidays" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total aos itens" ON "public"."marketplace_favorite_items" USING (true);



CREATE POLICY "Permitir acesso total aos logs para usuários autenticados" ON "public"."time_tracking_logs" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total as configuracoes para usuários autentica" ON "public"."time_tracking_settings" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total para autenticados" ON "public"."nfe_outbound" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total para usuários autenticados" ON "public"."finance_accounts" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir acesso total para usuários autenticados" ON "public"."pcp_workflows" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir acesso total às pastas" ON "public"."marketplace_favorite_folders" USING (true);



CREATE POLICY "Permitir atualizacao autenticada cte" ON "public"."cte_entries" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir atualizacao de pilotos" ON "public"."pilot_requests" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Permitir atualizacao do painel" ON "public"."system_settings" FOR UPDATE USING (true);



CREATE POLICY "Permitir atualizacao no estoque (Equipe)" ON "public"."stock" FOR UPDATE TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role", 'vendedor'::"public"."user_role", 'designer'::"public"."user_role", 'producao'::"public"."user_role"])));



CREATE POLICY "Permitir atualizacao pelo proprio email" ON "public"."public_leads" FOR UPDATE TO "authenticated" USING (("email" = ("auth"."jwt"() ->> 'email'::"text"))) WITH CHECK (("email" = ("auth"."jwt"() ->> 'email'::"text")));



CREATE POLICY "Permitir atualização de estoque" ON "public"."stock" FOR UPDATE TO "anon" USING (true);



CREATE POLICY "Permitir atualização para usuários logados" ON "public"."purchases" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir criacao de pilotos" ON "public"."pilot_requests" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Permitir delete de leads para admins" ON "public"."public_leads" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Permitir delete do proprio rascunho" ON "public"."order_drafts" FOR DELETE USING ((("auth"."uid"() = "user_id") OR ("auth"."uid"() IS NOT NULL)));



CREATE POLICY "Permitir edicao admin" ON "public"."catalog_fabrics" TO "service_role" USING (true);



CREATE POLICY "Permitir escrita total Cajuia Accounts" ON "public"."cajuia_accounts" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir escrita total Cajuia Configs" ON "public"."cajuia_accounting_configs" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir escrita total Cajuia Cost Centers" ON "public"."cajuia_cost_centers" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir escrita total Cajuia Items" ON "public"."cajuia_journal_items" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir escrita total Cajuia Journal" ON "public"."cajuia_journal_entries" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir exclusao de pilotos (Rollback de erro)" ON "public"."pilot_requests" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Permitir exclusao no estoque (Admins)" ON "public"."stock" FOR DELETE TO "authenticated" USING ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Permitir exclusão para usuários logados" ON "public"."purchases" FOR DELETE USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir insercao" ON "public"."digital_purchases" FOR INSERT WITH CHECK (true);



CREATE POLICY "Permitir insercao autenticada cte" ON "public"."cte_entries" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir insercao no estoque (Admins)" ON "public"."stock" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])));



CREATE POLICY "Permitir insert para usuários autenticados" ON "public"."catalog_fabrics" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Permitir inserção anonima e autenticada" ON "public"."public_leads" FOR INSERT WITH CHECK (true);



CREATE POLICY "Permitir inserção de logs" ON "public"."system_audit_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Permitir inserção de logs para usuários autenticados" ON "public"."audit_logs" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Permitir inserção de mensagens" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Permitir inserção para logados" ON "public"."production_logs" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir inserção para usuários logados" ON "public"."purchases" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir inserção/atualização para autenticados" ON "public"."dfe_entries" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura anonima" ON "public"."catalog_fabrics" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Permitir leitura anônima em stock" ON "public"."stock" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Permitir leitura autenticada" ON "public"."catalog_fabrics" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura autenticada Cajuia Accounts" ON "public"."cajuia_accounts" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura autenticada Cajuia Configs" ON "public"."cajuia_accounting_configs" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura autenticada Cajuia Cost Centers" ON "public"."cajuia_cost_centers" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura autenticada Cajuia Items" ON "public"."cajuia_journal_items" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura autenticada Cajuia Journal" ON "public"."cajuia_journal_entries" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura autenticada cte" ON "public"."cte_entries" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura de clientes" ON "public"."cajuia_clients" FOR SELECT USING (true);



CREATE POLICY "Permitir leitura de estoque" ON "public"."stock" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Permitir leitura de formas de pagamento" ON "public"."finance_payment_methods" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura de itens de pedido para usuários autenticados" ON "public"."order_items" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura de pedidos" ON "public"."cajuia_orders" FOR SELECT USING (true);



CREATE POLICY "Permitir leitura de pilotos" ON "public"."pilot_requests" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura de produtos" ON "public"."cajuia_products" FOR SELECT USING (true);



CREATE POLICY "Permitir leitura de updates" ON "public"."system_updates" FOR SELECT USING (true);



CREATE POLICY "Permitir leitura para autenticados" ON "public"."dfe_entries" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura para autenticados" ON "public"."order_payments" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura para logados" ON "public"."production_logs" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir leitura para painel admin" ON "public"."public_leads" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura para todos" ON "public"."system_settings" FOR SELECT USING (true);



CREATE POLICY "Permitir leitura para usuários autenticados" ON "public"."system_audit_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Permitir leitura para usuários logados" ON "public"."purchases" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir que administradores leiam as movimentações" ON "public"."stock_movements" FOR SELECT TO "authenticated" USING (("public"."get_my_claim"('user_role'::"text") = '"admin"'::"jsonb"));



CREATE POLICY "Permitir que usuários logados registrem movimentações" ON "public"."stock_movements" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Permitir select para proprio email" ON "public"."digital_purchases" FOR SELECT TO "authenticated" USING (("client_email" = ("auth"."jwt"() ->> 'email'::"text")));



CREATE POLICY "Permitir tudo para autenticados" ON "public"."finance_chart_of_accounts" USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Permitir update de leads para admins" ON "public"."public_leads" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))));



CREATE POLICY "Permitir update de leitura" ON "public"."messages" FOR UPDATE TO "authenticated" USING (true);



CREATE POLICY "Permitir update em store_sales" ON "public"."store_sales" FOR UPDATE USING (true);



CREATE POLICY "Permitir update no proprio canal" ON "public"."channels" FOR UPDATE TO "authenticated" USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Permitir update para autenticados" ON "public"."catalog_fabrics" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Permitir update para criador ou admin" ON "public"."design_requests" FOR UPDATE TO "authenticated" USING ((("auth"."uid"() = "created_by") OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])))))));



CREATE POLICY "Permitir update para proprio email" ON "public"."digital_purchases" FOR UPDATE TO "authenticated" USING (("client_email" = ("auth"."jwt"() ->> 'email'::"text")));



CREATE POLICY "Production can move orders" ON "public"."orders" FOR UPDATE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'producao'::"public"."user_role")))) AND ("status" = ANY (ARRAY['production_queue'::"text", 'in_printing'::"text", 'in_cutting'::"text", 'completed'::"text"]))));



CREATE POLICY "Production can view production-related orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (((( SELECT "profiles"."role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'producao'::"public"."user_role") AND ("status" = ANY (ARRAY['production_queue'::"text", 'in_printing'::"text", 'in_cutting'::"text", 'completed'::"text", 'delivered'::"text"]))));



CREATE POLICY "Production can view their kanban orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'producao'::"public"."user_role")))) AND ("status" = ANY (ARRAY['production_queue'::"text", 'in_printing'::"text", 'in_cutting'::"text", 'completed'::"text"]))));



CREATE POLICY "Public Access" ON "public"."cajuia_clients" USING (true);



CREATE POLICY "Public Access" ON "public"."fiscal_companies" USING (true);



CREATE POLICY "Public access cost centers" ON "public"."finance_cost_centers" USING (true);



CREATE POLICY "Salespeople can view all orders" ON "public"."orders" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'vendedor'::"public"."user_role")))));



CREATE POLICY "Salesperson can approve or request changes" ON "public"."orders" FOR UPDATE TO "authenticated" USING ((("created_by" = "auth"."uid"()) AND ("status" = 'customer_approval'::"text"))) WITH CHECK ((("status" = 'production_queue'::"text") OR ("status" = 'changes_requested'::"text")));



CREATE POLICY "Service role pode inserir atividades" ON "public"."user_activity" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Sistema pode registrar transacoes para o cliente" ON "public"."client_transactions" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Update liberado geral" ON "public"."pilot_transactions" FOR UPDATE USING (true) WITH CHECK (true);



CREATE POLICY "Users can delete their created tasks" ON "public"."app_tasks" FOR DELETE TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])))))));



CREATE POLICY "Users can delete their own notifications" ON "public"."notifications" FOR DELETE USING (("auth"."uid"() = "recipient_id"));



CREATE POLICY "Users can insert own preferences" ON "public"."user_preferences" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert tasks" ON "public"."app_tasks" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Users can listen for their notifications" ON "public"."notifications" FOR SELECT TO "authenticated" USING ((("recipient_id" = "auth"."uid"()) OR ("recipient_id" IS NULL)));



CREATE POLICY "Users can manage their own cart" ON "public"."marketplace_cart" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own dismissals" ON "public"."user_notification_dismissals" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own drafts" ON "public"."order_drafts" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own emails" ON "public"."emails" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own movements" ON "public"."cajuia_cash_movements" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own notification dismissals" ON "public"."user_notification_dismissals" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own preferences" ON "public"."user_preferences" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can manage their own sessions" ON "public"."cajuia_cash_sessions" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can only manage their own tasks" ON "public"."tasks" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update own preferences" ON "public"."user_preferences" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update relevant tasks" ON "public"."app_tasks" FOR UPDATE TO "authenticated" USING ((("assigned_to" = "auth"."uid"()) OR ("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"]))))))) WITH CHECK (true);



CREATE POLICY "Users can update their own orders" ON "public"."orders" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "created_by")) WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view all profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Users can view own preferences" ON "public"."user_preferences" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view relevant tasks" ON "public"."app_tasks" FOR SELECT TO "authenticated" USING ((("assigned_to" = "auth"."uid"()) OR ("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['admin'::"public"."user_role", 'super_admin'::"public"."user_role"])))))));



CREATE POLICY "Users can view their own orders" ON "public"."orders" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Usuários autenticados podem ver conversas não atribuídas" ON "public"."wa_conversations" FOR SELECT USING (("assigned_to" IS NULL));



CREATE POLICY "Usuários deletam seus próprios relatórios" ON "public"."user_reports" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuários gerenciam suas próprias contas de email" ON "public"."email_accounts" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuários inserem seus próprios relatórios" ON "public"."user_reports" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Usuários logados podem ler regras" ON "public"."productivity_rules" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Usuários podem inserir notificações" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "sender_id"));



CREATE POLICY "Usuários podem ver suas próprias notificações" ON "public"."notifications" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "recipient_id"));



CREATE POLICY "Usuários veem apenas seus próprios relatórios" ON "public"."user_reports" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Vendedores Update All Receivables" ON "public"."finance_receivables" FOR UPDATE TO "authenticated" USING ((( SELECT ("profiles"."role")::"text" AS "role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'vendedor'::"text"));



CREATE POLICY "Vendedores View All Receivables" ON "public"."finance_receivables" FOR SELECT TO "authenticated" USING ((( SELECT ("profiles"."role")::"text" AS "role"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 'vendedor'::"text"));



CREATE POLICY "Vendedores can manage their payments" ON "public"."finance_receivable_payments" USING ((("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_receivable_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"())))))) WITH CHECK ((("public"."get_my_role"() = 'vendedor'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."finance_receivables" "r"
  WHERE (("r"."id" = "finance_receivable_payments"."receivable_id") AND ("r"."created_by" = "auth"."uid"()))))));



CREATE POLICY "Vendedores can see their receivables" ON "public"."finance_receivables" FOR SELECT USING (("created_by" = "auth"."uid"()));



CREATE POLICY "Vendedores podem atualizar seus próprios chamados" ON "public"."design_requests" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "created_by")) WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Ver Widgets" ON "public"."cajuia_widgets" FOR SELECT USING ((("is_system" = true) OR ("created_by" = "auth"."uid"())));



CREATE POLICY "Ver regras da propria empresa" ON "public"."fiscal_tax_rules" FOR SELECT USING (true);



ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_accounting_configs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_bank_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_bank_statements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_bank_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_cash_movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_cash_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_clients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_cost_centers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_dashboard_layouts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_expense_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_fiscal_docs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_journal_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_journal_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_order_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_tax_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajuia_widgets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."catalog_fabrics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."channel_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."channels" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."client_design_deliveries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."client_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."company_installed_apps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."company_integrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crm_active_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crm_lead_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crm_workflows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cte_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."customer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."daily_stock_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."design_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."design_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."dfe_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."digital_purchases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."email_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."emails" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."employees_mj" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_bank_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_chart_of_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_cost_centers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_invoice_payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_payables" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_payment_methods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_receivable_payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_receivables" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fiscal_companies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fiscal_tax_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fleet_refuelings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fleet_vehicles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."marketplace_cart" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."marketplace_customers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."marketplace_favorite_folders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."marketplace_favorite_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mj_cash_movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mj_cash_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."nfce_outbound" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."nfe_outbound" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."order_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."order_payments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pcp_workflows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pdv_price_lists" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pdv_product_prices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pending_stock_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pilot_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."pilot_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."premium_access_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."premium_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."price_list" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."production_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."production_machines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."production_schedule" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."productivity_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_columns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchase_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."purchases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sales_goals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."scheduled_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."security_events_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."security_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."seller_activities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stamp_folders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stamp_library" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_ledger" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stock_movements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."store_sales" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."suppliers_mj" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."system_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."system_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_extension_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_corrections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_holidays" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_kiosk_releases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_kiosk_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_overrides" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_overtime_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_payroll_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."time_tracking_shift_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_modules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_progress" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_activity" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_notification_dismissals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_presences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_screenshots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wa_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."work_schedules" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."channels";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."finance_audit_logs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."finance_payables";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."finance_receivables";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."order_payments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."orders";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."pending_stock_orders";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."productivity_rules";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."public_leads";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."sre_incidents";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."system_updates";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."time_extension_requests";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."user_activity";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."user_notification_dismissals";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."work_schedules";



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";























































































































































































GRANT ALL ON FUNCTION "public"."add_business_days"("start_date" "date", "number_of_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."add_business_days"("start_date" "date", "number_of_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_business_days"("start_date" "date", "number_of_days" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_group_members"("p_channel_id" bigint, "p_new_member_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."add_group_members"("p_channel_id" bigint, "p_new_member_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_group_members"("p_channel_id" bigint, "p_new_member_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."adiantar_item_producao"("p_item_id" "uuid", "p_admin_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."adiantar_item_producao"("p_item_id" "uuid", "p_admin_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."adiantar_item_producao"("p_item_id" "uuid", "p_admin_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."adiantar_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."adiantar_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."adiantar_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_manage_security"("p_user_id" "uuid", "p_action" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_manage_security"("p_user_id" "uuid", "p_action" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_manage_security"("p_user_id" "uuid", "p_action" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."approve_order_and_schedule"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."approve_order_and_schedule"("p_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_order_and_schedule"("p_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."are_all_items_in_stock"("p_order_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."are_all_items_in_stock"("p_order_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."are_all_items_in_stock"("p_order_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."cajuia_get_account_config"("config_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."cajuia_get_account_config"("config_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cajuia_get_account_config"("config_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."cajuia_get_period_balance"("p_start_date" "date", "p_end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."cajuia_get_period_balance"("p_start_date" "date", "p_end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cajuia_get_period_balance"("p_start_date" "date", "p_end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."cajuia_post_sale_to_ledger"("target_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."cajuia_post_sale_to_ledger"("target_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cajuia_post_sale_to_ledger"("target_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_delivery_forecast"("p_op_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_delivery_forecast"("p_op_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_delivery_forecast"("p_op_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_and_finalize_order"("p_order_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_and_finalize_order"("p_order_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_and_finalize_order"("p_order_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_and_release_scheduled_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_and_release_scheduled_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_and_release_scheduled_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_channel_lock_before_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_channel_lock_before_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_channel_lock_before_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_parent_order_completion"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_parent_order_completion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_parent_order_completion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_premium_context"("p_email" "text", "p_context" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."check_premium_context"("p_email" "text", "p_context" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_premium_context"("p_email" "text", "p_context" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_stale_presences"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_stale_presences"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_stale_presences"() TO "service_role";



GRANT ALL ON FUNCTION "public"."concluir_todos_itens_pedido"("p_order_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."concluir_todos_itens_pedido"("p_order_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."concluir_todos_itens_pedido"("p_order_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."confirmar_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."confirmar_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."confirmar_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_cajuia_order"("p_vendedor_id" "uuid", "p_customer_id" "text", "p_customer_name" "text", "p_total_value" numeric, "p_payment_method" "text", "p_gestaoclick_sale_id" "text", "p_order_items" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_cajuia_order"("p_vendedor_id" "uuid", "p_customer_id" "text", "p_customer_name" "text", "p_total_value" numeric, "p_payment_method" "text", "p_gestaoclick_sale_id" "text", "p_order_items" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_cajuia_order"("p_vendedor_id" "uuid", "p_customer_id" "text", "p_customer_name" "text", "p_total_value" numeric, "p_payment_method" "text", "p_gestaoclick_sale_id" "text", "p_order_items" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_channel_with_participants"("p_name" "text", "p_created_by" "uuid", "p_is_private_dm" boolean, "p_participant_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."create_channel_with_participants"("p_name" "text", "p_created_by" "uuid", "p_is_private_dm" boolean, "p_participant_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_channel_with_participants"("p_name" "text", "p_created_by" "uuid", "p_is_private_dm" boolean, "p_participant_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_design_items_from_pending_order"("p_order_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_design_items_from_pending_order"("p_order_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_design_items_from_pending_order"("p_order_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_design_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_design_items" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."create_design_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_design_items" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_design_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_design_items" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid", "p_request_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid", "p_request_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_design_request"("p_general_notes" "text", "p_store_id" "uuid", "p_design_items" "jsonb", "p_created_by" "uuid", "p_request_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[], "p_admin_ids" "uuid"[], "p_moderator_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[], "p_admin_ids" "uuid"[], "p_moderator_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_group_channel"("channel_name" "text", "member_ids" "uuid"[], "p_admin_ids" "uuid"[], "p_moderator_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_launch_order"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."create_launch_order"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_launch_order"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_launch_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."create_launch_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_launch_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_order_and_update_stock"("p_customer_name" "text", "p_quantity_meters" numeric, "p_details" "jsonb", "p_store_id" "uuid", "p_created_by" "uuid", "p_value" numeric, "p_has_down_payment" boolean, "p_down_payment_proof_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_order_and_update_stock"("p_customer_name" "text", "p_quantity_meters" numeric, "p_details" "jsonb", "p_store_id" "uuid", "p_created_by" "uuid", "p_value" numeric, "p_has_down_payment" boolean, "p_down_payment_proof_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_order_and_update_stock"("p_customer_name" "text", "p_quantity_meters" numeric, "p_details" "jsonb", "p_store_id" "uuid", "p_created_by" "uuid", "p_value" numeric, "p_has_down_payment" boolean, "p_down_payment_proof_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric, "p_customer_id" integer, "p_observation" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric, "p_customer_id" integer, "p_observation" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_order_with_stock_check"("p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric, "p_customer_id" integer, "p_observation" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_production_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_fabric_type" "text", "p_quantity_meters" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."create_production_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_fabric_type" "text", "p_quantity_meters" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_production_order"("p_customer_name" "text", "p_general_notes" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_fabric_type" "text", "p_quantity_meters" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_ready_delivery_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."create_ready_delivery_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_ready_delivery_order"("p_order_number" integer, "p_customer_name" "text", "p_created_by" "uuid", "p_store_id" "uuid", "p_has_down_payment" boolean, "p_down_payment_proof_url" "text", "p_order_items" "jsonb", "p_total_value" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "service_role";



GRANT ALL ON FUNCTION "public"."designer_complete_development"("p_request_id" "uuid", "p_final_art_url" "text", "p_new_stamp_name" "text", "p_designer_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."designer_complete_development"("p_request_id" "uuid", "p_final_art_url" "text", "p_new_stamp_name" "text", "p_designer_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."designer_complete_development"("p_request_id" "uuid", "p_final_art_url" "text", "p_new_stamp_name" "text", "p_designer_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."dismiss_all_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."dismiss_all_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."dismiss_all_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."execute_sql"("query_text" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."execute_sql"("query_text" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."execute_sql"("query_text" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."extract_required_stock"("p_order_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."extract_required_stock"("p_order_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."extract_required_stock"("p_order_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."faturar_pedido"("p_order_id" "uuid", "p_chart_of_accounts_id" "uuid", "p_bank_account_id" "uuid", "p_payment_method_id" "uuid", "p_due_date" "date", "p_competence_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."faturar_pedido"("p_order_id" "uuid", "p_chart_of_accounts_id" "uuid", "p_bank_account_id" "uuid", "p_payment_method_id" "uuid", "p_due_date" "date", "p_competence_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."faturar_pedido"("p_order_id" "uuid", "p_chart_of_accounts_id" "uuid", "p_bank_account_id" "uuid", "p_payment_method_id" "uuid", "p_due_date" "date", "p_competence_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."faturar_recebivel"("p_receivable_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."faturar_recebivel"("p_receivable_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."faturar_recebivel"("p_receivable_id" "uuid") TO "service_role";



GRANT ALL ON TABLE "public"."orders" TO "anon";
GRANT ALL ON TABLE "public"."orders" TO "authenticated";
GRANT ALL ON TABLE "public"."orders" TO "service_role";



GRANT ALL ON FUNCTION "public"."fetch_approval_group"("p_group_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."fetch_approval_group"("p_group_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fetch_approval_group"("p_group_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."find_or_create_dm_channel"("p_user1_id" "uuid", "p_user2_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."find_or_create_dm_channel"("p_user1_id" "uuid", "p_user2_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_or_create_dm_channel"("p_user1_id" "uuid", "p_user2_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."forcar_conclusao_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."forcar_conclusao_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."forcar_conclusao_pedido"("p_order_id" "uuid", "p_admin_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."func_set_purchase_codigo"() TO "anon";
GRANT ALL ON FUNCTION "public"."func_set_purchase_codigo"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."func_set_purchase_codigo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_op_number"("p_item_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_op_number"("p_item_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_op_number"("p_item_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_premium_access_code"("p_email" "text", "p_admin_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_premium_access_code"("p_email" "text", "p_admin_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_premium_access_code"("p_email" "text", "p_admin_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_all_channel_members"("p_channel_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_channel_members"("p_channel_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_channel_members"("p_channel_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_all_sellers_performance"("start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_sellers_performance"("start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_sellers_performance"("start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_all_users_with_status"("p_exclude_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_all_users_with_status"("p_exclude_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_all_users_with_status"("p_exclude_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_and_increment_order_number"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_and_increment_order_number"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_and_increment_order_number"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_app_usage_ranking"("p_user_id" "uuid", "p_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_app_usage_ranking"("p_user_id" "uuid", "p_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_app_usage_ranking"("p_user_id" "uuid", "p_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_comprehensive_report_data"("start_date" "text", "end_date" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_comprehensive_report_data"("start_date" "text", "end_date" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_comprehensive_report_data"("start_date" "text", "end_date" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_crm_overview_data"("start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_crm_overview_data"("start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_crm_overview_data"("start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_delivery_forecast_date"("p_order_items" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."get_delivery_forecast_date"("p_order_items" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_delivery_forecast_date"("p_order_items" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_design_kanban_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_design_kanban_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_design_kanban_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_detailed_report_data"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_detailed_report_data"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_detailed_report_data"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_full_order_details_for_sync"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_full_order_details_for_sync"("p_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_full_order_details_for_sync"("p_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_full_production_schedule"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_full_production_schedule"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_full_production_schedule"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_inactive_customers"("inactive_since_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_inactive_customers"("inactive_since_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_inactive_customers"("inactive_since_days" integer) TO "service_role";



GRANT ALL ON TABLE "public"."stock" TO "anon";
GRANT ALL ON TABLE "public"."stock" TO "authenticated";
GRANT ALL ON TABLE "public"."stock" TO "service_role";



GRANT ALL ON FUNCTION "public"."get_low_stock_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_low_stock_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_low_stock_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_machine_type_for_fabric"("fabric_type_arg" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_machine_type_for_fabric"("fabric_type_arg" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_machine_type_for_fabric"("fabric_type_arg" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_cajuia_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_cajuia_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_cajuia_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_channels"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_channels"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_channels"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_channels_with_unread_and_preview"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_channels_with_unread_and_preview"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_channels_with_unread_and_preview"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_business_day"("from_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_business_day"("from_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_business_day"("from_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_delivery_day"("from_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_delivery_day"("from_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_delivery_day"("from_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_order_number"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_order_number"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_order_number"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_orders_with_attachments"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_orders_with_attachments"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_orders_with_attachments"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_pending_stock_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_pending_stock_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_pending_stock_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_productive_sites_ranking"("p_user_id" "uuid", "p_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_productive_sites_ranking"("p_user_id" "uuid", "p_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_productive_sites_ranking"("p_user_id" "uuid", "p_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_sales_by_region"("start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_sales_by_region"("start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_sales_by_region"("start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_sales_orders_list"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_sales_orders_list"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_sales_orders_list"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_sales_rankings"("start_date" "date", "end_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."get_sales_rankings"("start_date" "date", "end_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_sales_rankings"("start_date" "date", "end_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_stock_audit_filters"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_stock_audit_filters"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_stock_audit_filters"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_stock_movements_report"("start_date" "text", "end_date" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_stock_movements_report"("start_date" "text", "end_date" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_stock_movements_report"("start_date" "text", "end_date" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_activity_report"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_activity_report"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_activity_report"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_activity_summary_with_presence"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_activity_summary_with_presence"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_activity_summary_with_presence"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_stamp_upload"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_stamp_upload"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_stamp_upload"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user_to_lead"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user_to_lead"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user_to_lead"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_order_submission_v2"("p_order_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."handle_order_submission_v2"("p_order_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_order_submission_v2"("p_order_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_public_leads_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_public_leads_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_public_leads_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_delete_permission"("required_permission" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_delete_permission"("required_permission" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_delete_permission"("required_permission" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_permission"("p_permission" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_permission"("p_permission" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_permission"("p_permission" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_screen_permission"("required_permission" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_screen_permission"("required_permission" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_screen_permission"("required_permission" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment"("table_name" "text", "row_id" "uuid", "x" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."increment"("table_name" "text", "row_id" "uuid", "x" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment"("table_name" "text", "row_id" "uuid", "x" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticator";



GRANT ALL ON FUNCTION "public"."is_admin_or_super"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_or_super"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_or_super"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_channel_member"("_channel_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."is_channel_member"("_channel_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_channel_member"("_channel_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_user_member_of_channel"("p_channel_id" bigint, "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_user_member_of_channel"("p_channel_id" bigint, "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_user_member_of_channel"("p_channel_id" bigint, "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_security_events"("p_events" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_security_events"("p_events" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_security_events"("p_events" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_stock_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_stock_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_stock_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_universal_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_universal_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_universal_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."manually_recheck_pending_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."manually_recheck_pending_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."manually_recheck_pending_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_designers_about_decision"("p_item_id" "uuid", "p_sender_id" "uuid", "p_is_approved" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."notify_designers_about_decision"("p_item_id" "uuid", "p_sender_id" "uuid", "p_is_approved" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_designers_about_decision"("p_item_id" "uuid", "p_sender_id" "uuid", "p_is_approved" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_designers_about_new_item"("p_order_id" "uuid", "p_item_id" "uuid", "p_sender_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_designers_about_new_item"("p_order_id" "uuid", "p_item_id" "uuid", "p_sender_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_designers_about_new_item"("p_order_id" "uuid", "p_item_id" "uuid", "p_sender_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_seller_about_order_completion"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_seller_about_order_completion"("p_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_seller_about_order_completion"("p_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_seller_about_production_scheduling"("p_item_id" "uuid", "p_scheduled_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_seller_about_production_scheduling"("p_item_id" "uuid", "p_scheduled_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_seller_about_production_scheduling"("p_item_id" "uuid", "p_scheduled_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_seller_for_approval"("p_item_id" "uuid", "p_sender_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."notify_seller_for_approval"("p_item_id" "uuid", "p_sender_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_seller_for_approval"("p_item_id" "uuid", "p_sender_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_approval_decision"("p_decisions" "jsonb", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_approval_decision"("p_decisions" "jsonb", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_approval_decision"("p_decisions" "jsonb", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_item_approval_and_schedule"("p_item_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_item_approval_and_schedule"("p_item_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_item_approval_and_schedule"("p_item_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."process_pending_stock_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."process_pending_stock_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_pending_stock_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_seller_item_decision"("p_item_id" "uuid", "p_decision" "text", "p_comment" "text", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_seller_item_decision"("p_item_id" "uuid", "p_decision" "text", "p_comment" "text", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_seller_item_decision"("p_item_id" "uuid", "p_decision" "text", "p_comment" "text", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reagendar_entrega"("p_order_id" "uuid", "p_new_delivery_date" "date", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reagendar_entrega"("p_order_id" "uuid", "p_new_delivery_date" "date", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reagendar_entrega"("p_order_id" "uuid", "p_new_delivery_date" "date", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."recheck_stock_for_entire_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."recheck_stock_for_entire_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recheck_stock_for_entire_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."recheck_stock_for_pending_items"() TO "anon";
GRANT ALL ON FUNCTION "public"."recheck_stock_for_pending_items"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recheck_stock_for_pending_items"() TO "service_role";



GRANT ALL ON FUNCTION "public"."release_item_to_production_v2"("p_item_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."release_item_to_production_v2"("p_item_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."release_item_to_production_v2"("p_item_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."release_order_to_production"("p_order_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."release_order_to_production"("p_order_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."release_order_to_production"("p_order_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."release_scheduled_order"("p_scheduled_order_id" "uuid", "p_releaser_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."release_scheduled_order"("p_scheduled_order_id" "uuid", "p_releaser_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."release_scheduled_order"("p_scheduled_order_id" "uuid", "p_releaser_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_group_member"("p_channel_id" bigint, "p_target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remove_group_member"("p_channel_id" bigint, "p_target_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_group_member"("p_channel_id" bigint, "p_target_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reprocess_pending_stock_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."reprocess_pending_stock_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reprocess_pending_stock_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."request_item_changes"("p_item_id" "uuid", "p_comment" "text", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."request_item_changes"("p_item_id" "uuid", "p_comment" "text", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_item_changes"("p_item_id" "uuid", "p_comment" "text", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reschedule_production_item"("p_item_id" "uuid", "p_new_date" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."reschedule_production_item"("p_item_id" "uuid", "p_new_date" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reschedule_production_item"("p_item_id" "uuid", "p_new_date" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."restore_credit_on_payment"() TO "anon";
GRANT ALL ON FUNCTION "public"."restore_credit_on_payment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."restore_credit_on_payment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."revert_item_to_design"("p_item_id" "uuid", "p_admin_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."revert_item_to_design"("p_item_id" "uuid", "p_admin_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."revert_item_to_design"("p_item_id" "uuid", "p_admin_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reverter_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reverter_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reverter_entrega"("p_order_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_item_for_production"("p_item_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_item_for_production"("p_item_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_item_for_production"("p_item_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_order"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_order"("p_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_order"("p_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_order_automatically"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_order_automatically"("p_order_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_order_automatically"("p_order_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_order_with_limits"("p_order_id" "uuid", "p_fabric_type" "text", "p_quantity" numeric, "p_daily_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_order_with_limits"("p_order_id" "uuid", "p_fabric_type" "text", "p_quantity" numeric, "p_daily_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_order_with_limits"("p_order_id" "uuid", "p_fabric_type" "text", "p_quantity" numeric, "p_daily_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_production_for_item"("p_fabric_type" "text", "p_quantity" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_production_for_item"("p_fabric_type" "text", "p_quantity" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_production_for_item"("p_fabric_type" "text", "p_quantity" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_solid_items_for_production"() TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_solid_items_for_production"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_solid_items_for_production"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_initial_forecast_delivery_date"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_initial_forecast_delivery_date"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_initial_forecast_delivery_date"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_message_delete_history"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_message_delete_history"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_message_delete_history"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_message_edit_history"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_message_edit_history"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_message_edit_history"() TO "service_role";



GRANT ALL ON FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) TO "service_role";
GRANT ALL ON FUNCTION "public"."soft_delete_channel"("p_channel_id" bigint) TO "authenticator";



GRANT ALL ON FUNCTION "public"."sre_check_collision_from_drafts"() TO "anon";
GRANT ALL ON FUNCTION "public"."sre_check_collision_from_drafts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sre_check_collision_from_drafts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sre_check_collision_from_orders"() TO "anon";
GRANT ALL ON FUNCTION "public"."sre_check_collision_from_orders"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sre_check_collision_from_orders"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sre_get_infra_metrics"() TO "anon";
GRANT ALL ON FUNCTION "public"."sre_get_infra_metrics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sre_get_infra_metrics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sre_run_reconciliation"() TO "anon";
GRANT ALL ON FUNCTION "public"."sre_run_reconciliation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sre_run_reconciliation"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_channel_members_to_admin_channel_members_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_channels_to_admin_channels_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_messages_to_admin_messages_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_order_item_date"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_order_item_date"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_order_item_date"() TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_item_op_generation"("p_item_id" "uuid", "p_is_generated" boolean, "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_item_op_generation"("p_item_id" "uuid", "p_is_generated" boolean, "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_item_op_generation"("p_item_id" "uuid", "p_is_generated" boolean, "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_cajuia_auto_post_sale"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_cajuia_auto_post_sale"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_cajuia_auto_post_sale"() TO "service_role";



GRANT ALL ON FUNCTION "public"."unlock_orders_with_sufficient_stock"() TO "anon";
GRANT ALL ON FUNCTION "public"."unlock_orders_with_sufficient_stock"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."unlock_orders_with_sufficient_stock"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_app_tasks_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_app_tasks_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_app_tasks_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_client_credit"("client_id" "uuid", "amount" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."update_client_credit"("client_id" "uuid", "amount" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_client_credit"("client_id" "uuid", "amount" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_item_stamp_ref"("p_item_id" "uuid", "p_new_ref" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_item_stamp_ref"("p_item_id" "uuid", "p_new_ref" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_item_stamp_ref"("p_item_id" "uuid", "p_new_ref" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_last_read"("p_channel_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."update_last_read"("p_channel_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_last_read"("p_channel_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_member_role"("p_channel_id" bigint, "p_target_user_id" "uuid", "p_new_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_member_role"("p_channel_id" bigint, "p_target_user_id" "uuid", "p_new_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_member_role"("p_channel_id" bigint, "p_target_user_id" "uuid", "p_new_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_order_financial_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_order_financial_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_order_financial_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_order_item_status"("p_item_id" "uuid", "p_new_status" "text", "p_final_art_url" "text", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_order_item_status"("p_item_id" "uuid", "p_new_status" "text", "p_final_art_url" "text", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_order_item_status"("p_item_id" "uuid", "p_new_status" "text", "p_final_art_url" "text", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_session_risk"("p_session_id" "text", "p_user_id" "uuid", "p_score_add" integer, "p_reason" "text", "p_context" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_session_risk"("p_session_id" "text", "p_user_id" "uuid", "p_score_add" integer, "p_reason" "text", "p_context" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_session_risk"("p_session_id" "text", "p_user_id" "uuid", "p_score_add" integer, "p_reason" "text", "p_context" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_stock_batches_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_stock_batches_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_stock_batches_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_stock_quantity"("p_stock_id_to_update" "uuid", "p_quantity_to_add" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."update_stock_quantity"("p_stock_id_to_update" "uuid", "p_quantity_to_add" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_stock_quantity"("p_stock_id_to_update" "uuid", "p_quantity_to_add" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_time_tracking_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_time_tracking_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_time_tracking_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_user_presence"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_user_presence"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user_presence"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_premium_access"("p_email" "text", "p_code" "text", "p_context" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."validate_premium_access"("p_email" "text", "p_code" "text", "p_context" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_premium_access"("p_email" "text", "p_code" "text", "p_context" "jsonb") TO "service_role";
























GRANT ALL ON TABLE "public"."admin_channel_members" TO "anon";
GRANT ALL ON TABLE "public"."admin_channel_members" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_channel_members" TO "service_role";



GRANT ALL ON TABLE "public"."admin_channels" TO "anon";
GRANT ALL ON TABLE "public"."admin_channels" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_channels" TO "service_role";



GRANT ALL ON TABLE "public"."admin_messages" TO "anon";
GRANT ALL ON TABLE "public"."admin_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_messages" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."admin_orders_view" TO "anon";
GRANT ALL ON TABLE "public"."admin_orders_view" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_orders_view" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."app_tasks" TO "anon";
GRANT ALL ON TABLE "public"."app_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."app_tasks" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."audit_logs" TO "anon";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."audit_logs" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."builder_assets" TO "anon";
GRANT ALL ON TABLE "public"."builder_assets" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_assets" TO "service_role";



GRANT ALL ON TABLE "public"."builder_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."builder_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."builder_menus" TO "anon";
GRANT ALL ON TABLE "public"."builder_menus" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_menus" TO "service_role";



GRANT ALL ON TABLE "public"."builder_page_versions" TO "anon";
GRANT ALL ON TABLE "public"."builder_page_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_page_versions" TO "service_role";



GRANT ALL ON TABLE "public"."builder_pages" TO "anon";
GRANT ALL ON TABLE "public"."builder_pages" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_pages" TO "service_role";



GRANT ALL ON TABLE "public"."builder_themes" TO "anon";
GRANT ALL ON TABLE "public"."builder_themes" TO "authenticated";
GRANT ALL ON TABLE "public"."builder_themes" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_accounting_configs" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_accounting_configs" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_accounting_configs" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_accounts" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_bank_accounts" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_bank_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_bank_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_bank_statements" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_bank_statements" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_bank_statements" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_bank_transactions" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_bank_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_bank_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_cash_movements" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_cash_movements" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_cash_movements" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_cash_sessions" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_cash_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_cash_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_categories" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_categories" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_clients" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_clients" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_clients" TO "service_role";



GRANT ALL ON SEQUENCE "public"."cajuia_clients_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."cajuia_clients_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."cajuia_clients_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_corte_tasks" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_corte_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_corte_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_cost_centers" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_cost_centers" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_cost_centers" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_dashboard_layouts" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_dashboard_layouts" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_dashboard_layouts" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_expense_categories" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_expense_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_expense_categories" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_fiscal_docs" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_fiscal_docs" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_fiscal_docs" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_journal_entries" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_journal_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_journal_entries" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_journal_items" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_journal_items" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_journal_items" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_order_drafts" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_order_drafts" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_order_drafts" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_order_items" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_order_items" TO "service_role";



GRANT ALL ON SEQUENCE "public"."cajuia_order_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."cajuia_order_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."cajuia_order_number_seq" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_orders" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_orders" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_payables" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_payables" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_payables" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_permissions" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_price_lists" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_price_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_price_lists" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_product_prices" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_product_prices" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_product_prices" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_products" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_products" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_products" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_receivables" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_receivables" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_receivables" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_tax_settings" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_tax_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_tax_settings" TO "service_role";



GRANT ALL ON TABLE "public"."cajuia_widgets" TO "anon";
GRANT ALL ON TABLE "public"."cajuia_widgets" TO "authenticated";
GRANT ALL ON TABLE "public"."cajuia_widgets" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_banners" TO "anon";
GRANT ALL ON TABLE "public"."catalog_banners" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_banners" TO "service_role";



GRANT ALL ON SEQUENCE "public"."catalog_banners_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."catalog_banners_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."catalog_banners_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_categories" TO "anon";
GRANT ALL ON TABLE "public"."catalog_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_categories" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_collections" TO "anon";
GRANT ALL ON TABLE "public"."catalog_collections" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_collections" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_fabrics" TO "anon";
GRANT ALL ON TABLE "public"."catalog_fabrics" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_fabrics" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_mockups" TO "anon";
GRANT ALL ON TABLE "public"."catalog_mockups" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_mockups" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_settings" TO "anon";
GRANT ALL ON TABLE "public"."catalog_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_settings" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_stamp_collections" TO "anon";
GRANT ALL ON TABLE "public"."catalog_stamp_collections" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_stamp_collections" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_stamp_media" TO "anon";
GRANT ALL ON TABLE "public"."catalog_stamp_media" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_stamp_media" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_stamp_mockups" TO "anon";
GRANT ALL ON TABLE "public"."catalog_stamp_mockups" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_stamp_mockups" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_stamp_tags" TO "anon";
GRANT ALL ON TABLE "public"."catalog_stamp_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_stamp_tags" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_stamps" TO "anon";
GRANT ALL ON TABLE "public"."catalog_stamps" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_stamps" TO "service_role";



GRANT ALL ON TABLE "public"."catalog_tags" TO "anon";
GRANT ALL ON TABLE "public"."catalog_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."catalog_tags" TO "service_role";



GRANT ALL ON TABLE "public"."channel_members" TO "anon";
GRANT ALL ON TABLE "public"."channel_members" TO "authenticated";
GRANT ALL ON TABLE "public"."channel_members" TO "service_role";



GRANT ALL ON TABLE "public"."channels" TO "anon";
GRANT ALL ON TABLE "public"."channels" TO "authenticated";
GRANT ALL ON TABLE "public"."channels" TO "service_role";



GRANT ALL ON SEQUENCE "public"."channels_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."channels_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."channels_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."client_design_deliveries" TO "anon";
GRANT ALL ON TABLE "public"."client_design_deliveries" TO "authenticated";
GRANT ALL ON TABLE "public"."client_design_deliveries" TO "service_role";



GRANT ALL ON TABLE "public"."client_transactions" TO "anon";
GRANT ALL ON TABLE "public"."client_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."client_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."commerce_leads" TO "anon";
GRANT ALL ON TABLE "public"."commerce_leads" TO "authenticated";
GRANT ALL ON TABLE "public"."commerce_leads" TO "service_role";



GRANT ALL ON TABLE "public"."commerce_moodboard_items" TO "anon";
GRANT ALL ON TABLE "public"."commerce_moodboard_items" TO "authenticated";
GRANT ALL ON TABLE "public"."commerce_moodboard_items" TO "service_role";



GRANT ALL ON TABLE "public"."commerce_moodboards" TO "anon";
GRANT ALL ON TABLE "public"."commerce_moodboards" TO "authenticated";
GRANT ALL ON TABLE "public"."commerce_moodboards" TO "service_role";



GRANT ALL ON TABLE "public"."commerce_quote_requests" TO "anon";
GRANT ALL ON TABLE "public"."commerce_quote_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."commerce_quote_requests" TO "service_role";



GRANT ALL ON TABLE "public"."companies" TO "anon";
GRANT ALL ON TABLE "public"."companies" TO "authenticated";
GRANT ALL ON TABLE "public"."companies" TO "service_role";



GRANT ALL ON TABLE "public"."company_installed_apps" TO "anon";
GRANT ALL ON TABLE "public"."company_installed_apps" TO "authenticated";
GRANT ALL ON TABLE "public"."company_installed_apps" TO "service_role";



GRANT ALL ON TABLE "public"."company_integrations" TO "anon";
GRANT ALL ON TABLE "public"."company_integrations" TO "authenticated";
GRANT ALL ON TABLE "public"."company_integrations" TO "service_role";



GRANT ALL ON TABLE "public"."crm_active_alerts" TO "anon";
GRANT ALL ON TABLE "public"."crm_active_alerts" TO "authenticated";
GRANT ALL ON TABLE "public"."crm_active_alerts" TO "service_role";



GRANT ALL ON TABLE "public"."crm_automations" TO "anon";
GRANT ALL ON TABLE "public"."crm_automations" TO "authenticated";
GRANT ALL ON TABLE "public"."crm_automations" TO "service_role";



GRANT ALL ON TABLE "public"."crm_kanban_columns" TO "anon";
GRANT ALL ON TABLE "public"."crm_kanban_columns" TO "authenticated";
GRANT ALL ON TABLE "public"."crm_kanban_columns" TO "service_role";



GRANT ALL ON TABLE "public"."crm_lead_history" TO "anon";
GRANT ALL ON TABLE "public"."crm_lead_history" TO "authenticated";
GRANT ALL ON TABLE "public"."crm_lead_history" TO "service_role";



GRANT ALL ON TABLE "public"."crm_workflows" TO "anon";
GRANT ALL ON TABLE "public"."crm_workflows" TO "authenticated";
GRANT ALL ON TABLE "public"."crm_workflows" TO "service_role";



GRANT ALL ON TABLE "public"."cte_entries" TO "anon";
GRANT ALL ON TABLE "public"."cte_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."cte_entries" TO "service_role";



GRANT ALL ON TABLE "public"."custom_roles" TO "anon";
GRANT ALL ON TABLE "public"."custom_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."custom_roles" TO "service_role";



GRANT ALL ON TABLE "public"."customer_tags" TO "anon";
GRANT ALL ON TABLE "public"."customer_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."customer_tags" TO "service_role";



GRANT ALL ON SEQUENCE "public"."customer_tags_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."customer_tags_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."customer_tags_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."customers" TO "anon";
GRANT ALL ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";



GRANT ALL ON TABLE "public"."customers_mj" TO "anon";
GRANT ALL ON TABLE "public"."customers_mj" TO "authenticated";
GRANT ALL ON TABLE "public"."customers_mj" TO "service_role";



GRANT ALL ON TABLE "public"."daily_stock_reports" TO "anon";
GRANT ALL ON TABLE "public"."daily_stock_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_stock_reports" TO "service_role";



GRANT ALL ON SEQUENCE "public"."daily_stock_reports_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."daily_stock_reports_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."daily_stock_reports_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."debug_payload_log" TO "anon";
GRANT ALL ON TABLE "public"."debug_payload_log" TO "authenticated";
GRANT ALL ON TABLE "public"."debug_payload_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."debug_payload_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."debug_payload_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."debug_payload_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."design_assignment_requests" TO "anon";
GRANT ALL ON TABLE "public"."design_assignment_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."design_assignment_requests" TO "service_role";



GRANT ALL ON TABLE "public"."design_kanban_columns" TO "anon";
GRANT ALL ON TABLE "public"."design_kanban_columns" TO "authenticated";
GRANT ALL ON TABLE "public"."design_kanban_columns" TO "service_role";



GRANT ALL ON TABLE "public"."design_queue" TO "anon";
GRANT ALL ON TABLE "public"."design_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."design_queue" TO "service_role";



GRANT ALL ON TABLE "public"."design_rejection_logs" TO "anon";
GRANT ALL ON TABLE "public"."design_rejection_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."design_rejection_logs" TO "service_role";



GRANT ALL ON TABLE "public"."design_requests" TO "anon";
GRANT ALL ON TABLE "public"."design_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."design_requests" TO "service_role";



GRANT ALL ON SEQUENCE "public"."design_requests_dev_code_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."design_requests_dev_code_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."design_requests_dev_code_seq" TO "service_role";



GRANT ALL ON TABLE "public"."design_user_permissions" TO "anon";
GRANT ALL ON TABLE "public"."design_user_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."design_user_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."dfe_entries" TO "anon";
GRANT ALL ON TABLE "public"."dfe_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."dfe_entries" TO "service_role";



GRANT ALL ON TABLE "public"."digital_purchases" TO "anon";
GRANT ALL ON TABLE "public"."digital_purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."digital_purchases" TO "service_role";



GRANT ALL ON TABLE "public"."email_accounts" TO "anon";
GRANT ALL ON TABLE "public"."email_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."email_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."emails" TO "anon";
GRANT ALL ON TABLE "public"."emails" TO "authenticated";
GRANT ALL ON TABLE "public"."emails" TO "service_role";



GRANT ALL ON TABLE "public"."employees_mj" TO "anon";
GRANT ALL ON TABLE "public"."employees_mj" TO "authenticated";
GRANT ALL ON TABLE "public"."employees_mj" TO "service_role";



GRANT ALL ON TABLE "public"."erp_orders_cache" TO "anon";
GRANT ALL ON TABLE "public"."erp_orders_cache" TO "authenticated";
GRANT ALL ON TABLE "public"."erp_orders_cache" TO "service_role";



GRANT ALL ON TABLE "public"."finance_accounts" TO "anon";
GRANT ALL ON TABLE "public"."finance_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."finance_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."finance_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."finance_bank_accounts" TO "anon";
GRANT ALL ON TABLE "public"."finance_bank_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_bank_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."finance_chart_of_accounts" TO "anon";
GRANT ALL ON TABLE "public"."finance_chart_of_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_chart_of_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."finance_charts_of_accounts" TO "anon";
GRANT ALL ON TABLE "public"."finance_charts_of_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_charts_of_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."finance_cost_centers" TO "anon";
GRANT ALL ON TABLE "public"."finance_cost_centers" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_cost_centers" TO "service_role";



GRANT ALL ON TABLE "public"."finance_invoice_payments" TO "anon";
GRANT ALL ON TABLE "public"."finance_invoice_payments" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_invoice_payments" TO "service_role";



GRANT ALL ON TABLE "public"."finance_payables" TO "anon";
GRANT ALL ON TABLE "public"."finance_payables" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_payables" TO "service_role";



GRANT ALL ON SEQUENCE "public"."finance_payables_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."finance_payables_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."finance_payables_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."finance_payment_methods" TO "anon";
GRANT ALL ON TABLE "public"."finance_payment_methods" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_payment_methods" TO "service_role";



GRANT ALL ON TABLE "public"."finance_receivable_payments" TO "anon";
GRANT ALL ON TABLE "public"."finance_receivable_payments" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_receivable_payments" TO "service_role";



GRANT ALL ON TABLE "public"."finance_receivables" TO "anon";
GRANT ALL ON TABLE "public"."finance_receivables" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_receivables" TO "service_role";



GRANT ALL ON TABLE "public"."finance_transactions" TO "anon";
GRANT ALL ON TABLE "public"."finance_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."fiscal_companies" TO "anon";
GRANT ALL ON TABLE "public"."fiscal_companies" TO "authenticated";
GRANT ALL ON TABLE "public"."fiscal_companies" TO "service_role";



GRANT ALL ON TABLE "public"."fiscal_tax_rules" TO "anon";
GRANT ALL ON TABLE "public"."fiscal_tax_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."fiscal_tax_rules" TO "service_role";



GRANT ALL ON TABLE "public"."fleet_refuelings" TO "anon";
GRANT ALL ON TABLE "public"."fleet_refuelings" TO "authenticated";
GRANT ALL ON TABLE "public"."fleet_refuelings" TO "service_role";



GRANT ALL ON SEQUENCE "public"."fleet_refuelings_request_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."fleet_refuelings_request_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."fleet_refuelings_request_number_seq" TO "service_role";



GRANT ALL ON TABLE "public"."fleet_vehicles" TO "anon";
GRANT ALL ON TABLE "public"."fleet_vehicles" TO "authenticated";
GRANT ALL ON TABLE "public"."fleet_vehicles" TO "service_role";



GRANT ALL ON TABLE "public"."label_presets" TO "anon";
GRANT ALL ON TABLE "public"."label_presets" TO "authenticated";
GRANT ALL ON TABLE "public"."label_presets" TO "service_role";



GRANT ALL ON TABLE "public"."marketplace_cart" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_cart" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_cart" TO "service_role";



GRANT ALL ON TABLE "public"."marketplace_customers" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_customers" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_customers" TO "service_role";



GRANT ALL ON TABLE "public"."marketplace_favorite_folders" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_favorite_folders" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_favorite_folders" TO "service_role";



GRANT ALL ON TABLE "public"."marketplace_favorite_items" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_favorite_items" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_favorite_items" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."mj_cash_extraction_audit" TO "anon";
GRANT ALL ON TABLE "public"."mj_cash_extraction_audit" TO "authenticated";
GRANT ALL ON TABLE "public"."mj_cash_extraction_audit" TO "service_role";



GRANT ALL ON TABLE "public"."mj_cash_movements" TO "anon";
GRANT ALL ON TABLE "public"."mj_cash_movements" TO "authenticated";
GRANT ALL ON TABLE "public"."mj_cash_movements" TO "service_role";



GRANT ALL ON TABLE "public"."mj_cash_sessions" TO "anon";
GRANT ALL ON TABLE "public"."mj_cash_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."mj_cash_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."mj_expense_categories" TO "anon";
GRANT ALL ON TABLE "public"."mj_expense_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."mj_expense_categories" TO "service_role";



GRANT ALL ON TABLE "public"."mj_payables" TO "anon";
GRANT ALL ON TABLE "public"."mj_payables" TO "authenticated";
GRANT ALL ON TABLE "public"."mj_payables" TO "service_role";



GRANT ALL ON TABLE "public"."nfce_outbound" TO "anon";
GRANT ALL ON TABLE "public"."nfce_outbound" TO "authenticated";
GRANT ALL ON TABLE "public"."nfce_outbound" TO "service_role";



GRANT ALL ON TABLE "public"."nfe_outbound" TO "anon";
GRANT ALL ON TABLE "public"."nfe_outbound" TO "authenticated";
GRANT ALL ON TABLE "public"."nfe_outbound" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."operation_events" TO "anon";
GRANT ALL ON TABLE "public"."operation_events" TO "authenticated";
GRANT ALL ON TABLE "public"."operation_events" TO "service_role";



GRANT ALL ON TABLE "public"."order_drafts" TO "anon";
GRANT ALL ON TABLE "public"."order_drafts" TO "authenticated";
GRANT ALL ON TABLE "public"."order_drafts" TO "service_role";



GRANT ALL ON TABLE "public"."order_groups" TO "anon";
GRANT ALL ON TABLE "public"."order_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."order_groups" TO "service_role";



GRANT ALL ON TABLE "public"."order_items" TO "anon";
GRANT ALL ON TABLE "public"."order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."order_items" TO "service_role";



GRANT ALL ON TABLE "public"."order_logs" TO "anon";
GRANT ALL ON TABLE "public"."order_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."order_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."order_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."order_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."order_logs_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."order_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."order_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."order_number_seq" TO "service_role";



GRANT ALL ON TABLE "public"."order_payments" TO "anon";
GRANT ALL ON TABLE "public"."order_payments" TO "authenticated";
GRANT ALL ON TABLE "public"."order_payments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."orders_order_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."orders_order_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."orders_order_number_seq" TO "service_role";



GRANT ALL ON TABLE "public"."pcp_workflows" TO "anon";
GRANT ALL ON TABLE "public"."pcp_workflows" TO "authenticated";
GRANT ALL ON TABLE "public"."pcp_workflows" TO "service_role";



GRANT ALL ON TABLE "public"."pdv_price_lists" TO "anon";
GRANT ALL ON TABLE "public"."pdv_price_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."pdv_price_lists" TO "service_role";



GRANT ALL ON TABLE "public"."pdv_product_prices" TO "anon";
GRANT ALL ON TABLE "public"."pdv_product_prices" TO "authenticated";
GRANT ALL ON TABLE "public"."pdv_product_prices" TO "service_role";



GRANT ALL ON TABLE "public"."pending_stock_orders" TO "anon";
GRANT ALL ON TABLE "public"."pending_stock_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_stock_orders" TO "service_role";



GRANT ALL ON TABLE "public"."pilot_requests" TO "anon";
GRANT ALL ON TABLE "public"."pilot_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."pilot_requests" TO "service_role";



GRANT ALL ON TABLE "public"."pilot_transactions" TO "anon";
GRANT ALL ON TABLE "public"."pilot_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."pilot_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."premium_access_events" TO "anon";
GRANT ALL ON TABLE "public"."premium_access_events" TO "authenticated";
GRANT ALL ON TABLE "public"."premium_access_events" TO "service_role";



GRANT ALL ON TABLE "public"."premium_sessions" TO "anon";
GRANT ALL ON TABLE "public"."premium_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."premium_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."price_list" TO "anon";
GRANT ALL ON TABLE "public"."price_list" TO "authenticated";
GRANT ALL ON TABLE "public"."price_list" TO "service_role";



GRANT ALL ON TABLE "public"."product_details" TO "anon";
GRANT ALL ON TABLE "public"."product_details" TO "authenticated";
GRANT ALL ON TABLE "public"."product_details" TO "service_role";



GRANT ALL ON SEQUENCE "public"."product_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."product_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."product_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."production_logs" TO "anon";
GRANT ALL ON TABLE "public"."production_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."production_logs" TO "service_role";



GRANT ALL ON TABLE "public"."production_machines" TO "anon";
GRANT ALL ON TABLE "public"."production_machines" TO "authenticated";
GRANT ALL ON TABLE "public"."production_machines" TO "service_role";



GRANT ALL ON TABLE "public"."production_schedule" TO "anon";
GRANT ALL ON TABLE "public"."production_schedule" TO "authenticated";
GRANT ALL ON TABLE "public"."production_schedule" TO "service_role";



GRANT ALL ON SEQUENCE "public"."production_schedule_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."production_schedule_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."production_schedule_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."productivity_rules" TO "anon";
GRANT ALL ON TABLE "public"."productivity_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."productivity_rules" TO "service_role";



GRANT ALL ON TABLE "public"."products" TO "anon";
GRANT ALL ON TABLE "public"."products" TO "authenticated";
GRANT ALL ON TABLE "public"."products" TO "service_role";



GRANT ALL ON TABLE "public"."profiles_with_email" TO "anon";
GRANT ALL ON TABLE "public"."profiles_with_email" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles_with_email" TO "service_role";



GRANT ALL ON TABLE "public"."project_columns" TO "anon";
GRANT ALL ON TABLE "public"."project_columns" TO "authenticated";
GRANT ALL ON TABLE "public"."project_columns" TO "service_role";



GRANT ALL ON TABLE "public"."public_leads" TO "anon";
GRANT ALL ON TABLE "public"."public_leads" TO "authenticated";
GRANT ALL ON TABLE "public"."public_leads" TO "service_role";



GRANT ALL ON TABLE "public"."purchase_items" TO "anon";
GRANT ALL ON TABLE "public"."purchase_items" TO "authenticated";
GRANT ALL ON TABLE "public"."purchase_items" TO "service_role";



GRANT ALL ON TABLE "public"."purchases" TO "anon";
GRANT ALL ON TABLE "public"."purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."purchases" TO "service_role";



GRANT ALL ON SEQUENCE "public"."purchases_codigo_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."purchases_codigo_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."purchases_codigo_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."purchases_product_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."purchases_product_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."purchases_product_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."purchases_sequential_code_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."purchases_sequential_code_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."purchases_sequential_code_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."purchases_service_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."purchases_service_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."purchases_service_seq" TO "service_role";



GRANT ALL ON TABLE "public"."sales_goals" TO "anon";
GRANT ALL ON TABLE "public"."sales_goals" TO "authenticated";
GRANT ALL ON TABLE "public"."sales_goals" TO "service_role";



GRANT ALL ON TABLE "public"."scheduled_orders" TO "anon";
GRANT ALL ON TABLE "public"."scheduled_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."scheduled_orders" TO "service_role";



GRANT ALL ON TABLE "public"."security_events_log" TO "anon";
GRANT ALL ON TABLE "public"."security_events_log" TO "authenticated";
GRANT ALL ON TABLE "public"."security_events_log" TO "service_role";



GRANT ALL ON TABLE "public"."security_profiles" TO "anon";
GRANT ALL ON TABLE "public"."security_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."security_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."seller_activities" TO "anon";
GRANT ALL ON TABLE "public"."seller_activities" TO "authenticated";
GRANT ALL ON TABLE "public"."seller_activities" TO "service_role";



GRANT ALL ON TABLE "public"."services_catalog" TO "anon";
GRANT ALL ON TABLE "public"."services_catalog" TO "authenticated";
GRANT ALL ON TABLE "public"."services_catalog" TO "service_role";



GRANT ALL ON TABLE "public"."sre_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."sre_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."sre_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."sre_incidents" TO "anon";
GRANT ALL ON TABLE "public"."sre_incidents" TO "authenticated";
GRANT ALL ON TABLE "public"."sre_incidents" TO "service_role";



GRANT ALL ON TABLE "public"."user_activity" TO "anon";
GRANT ALL ON TABLE "public"."user_activity" TO "authenticated";
GRANT ALL ON TABLE "public"."user_activity" TO "service_role";



GRANT ALL ON TABLE "public"."sre_live_telemetry" TO "anon";
GRANT ALL ON TABLE "public"."sre_live_telemetry" TO "authenticated";
GRANT ALL ON TABLE "public"."sre_live_telemetry" TO "service_role";



GRANT ALL ON TABLE "public"."stamp_folders" TO "anon";
GRANT ALL ON TABLE "public"."stamp_folders" TO "authenticated";
GRANT ALL ON TABLE "public"."stamp_folders" TO "service_role";



GRANT ALL ON SEQUENCE "public"."stamp_folders_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."stamp_folders_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."stamp_folders_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."stamp_library" TO "anon";
GRANT ALL ON TABLE "public"."stamp_library" TO "authenticated";
GRANT ALL ON TABLE "public"."stamp_library" TO "service_role";



GRANT ALL ON SEQUENCE "public"."stamp_library_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."stamp_library_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."stamp_library_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."stock_batches" TO "anon";
GRANT ALL ON TABLE "public"."stock_batches" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_batches" TO "service_role";



GRANT ALL ON TABLE "public"."stock_ledger" TO "anon";
GRANT ALL ON TABLE "public"."stock_ledger" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_ledger" TO "service_role";



GRANT ALL ON TABLE "public"."stock_movements" TO "anon";
GRANT ALL ON TABLE "public"."stock_movements" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_movements" TO "service_role";



GRANT ALL ON SEQUENCE "public"."stock_movements_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."stock_movements_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."stock_movements_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."stock_tabs" TO "anon";
GRANT ALL ON TABLE "public"."stock_tabs" TO "authenticated";
GRANT ALL ON TABLE "public"."stock_tabs" TO "service_role";



GRANT ALL ON TABLE "public"."store_orders" TO "anon";
GRANT ALL ON TABLE "public"."store_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."store_orders" TO "service_role";



GRANT ALL ON TABLE "public"."store_sales" TO "anon";
GRANT ALL ON TABLE "public"."store_sales" TO "authenticated";
GRANT ALL ON TABLE "public"."store_sales" TO "service_role";



GRANT ALL ON TABLE "public"."storefront_settings" TO "anon";
GRANT ALL ON TABLE "public"."storefront_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."storefront_settings" TO "service_role";



GRANT ALL ON TABLE "public"."stores" TO "anon";
GRANT ALL ON TABLE "public"."stores" TO "authenticated";
GRANT ALL ON TABLE "public"."stores" TO "service_role";



GRANT ALL ON TABLE "public"."suppliers_mj" TO "anon";
GRANT ALL ON TABLE "public"."suppliers_mj" TO "authenticated";
GRANT ALL ON TABLE "public"."suppliers_mj" TO "service_role";



GRANT ALL ON TABLE "public"."system_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."system_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."system_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."system_events" TO "anon";
GRANT ALL ON TABLE "public"."system_events" TO "authenticated";
GRANT ALL ON TABLE "public"."system_events" TO "service_role";



GRANT ALL ON TABLE "public"."system_settings" TO "anon";
GRANT ALL ON TABLE "public"."system_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."system_settings" TO "service_role";



GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."system_settings_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."system_updates" TO "anon";
GRANT ALL ON TABLE "public"."system_updates" TO "authenticated";
GRANT ALL ON TABLE "public"."system_updates" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."time_extension_requests" TO "anon";
GRANT ALL ON TABLE "public"."time_extension_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."time_extension_requests" TO "service_role";



GRANT ALL ON SEQUENCE "public"."time_extension_requests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."time_extension_requests_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."time_extension_requests_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_assignments" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_corrections" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_corrections" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_corrections" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_holidays" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_holidays" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_holidays" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_kiosk_releases" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_kiosk_releases" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_kiosk_releases" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_kiosk_users" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_kiosk_users" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_kiosk_users" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_kiosks" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_kiosks" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_kiosks" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_logs" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_logs" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_overrides" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_overrides" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_overrides" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_overtime_requests" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_overtime_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_overtime_requests" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_payroll_events" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_payroll_events" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_payroll_events" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_settings" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_settings" TO "service_role";



GRANT ALL ON TABLE "public"."time_tracking_shift_templates" TO "anon";
GRANT ALL ON TABLE "public"."time_tracking_shift_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."time_tracking_shift_templates" TO "service_role";



GRANT ALL ON TABLE "public"."training_modules" TO "anon";
GRANT ALL ON TABLE "public"."training_modules" TO "authenticated";
GRANT ALL ON TABLE "public"."training_modules" TO "service_role";



GRANT ALL ON TABLE "public"."training_progress" TO "anon";
GRANT ALL ON TABLE "public"."training_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."training_progress" TO "service_role";



GRANT ALL ON SEQUENCE "public"."training_progress_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."training_progress_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."training_progress_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_activity_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_activity_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_activity_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_notification_dismissals" TO "anon";
GRANT ALL ON TABLE "public"."user_notification_dismissals" TO "authenticated";
GRANT ALL ON TABLE "public"."user_notification_dismissals" TO "service_role";



GRANT ALL ON TABLE "public"."user_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."user_presences" TO "anon";
GRANT ALL ON TABLE "public"."user_presences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_presences" TO "service_role";



GRANT ALL ON TABLE "public"."user_reports" TO "anon";
GRANT ALL ON TABLE "public"."user_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."user_reports" TO "service_role";



GRANT ALL ON TABLE "public"."user_screenshots" TO "anon";
GRANT ALL ON TABLE "public"."user_screenshots" TO "authenticated";
GRANT ALL ON TABLE "public"."user_screenshots" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_screenshots_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_screenshots_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_screenshots_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."v_sre_unified_logs" TO "anon";
GRANT ALL ON TABLE "public"."v_sre_unified_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."v_sre_unified_logs" TO "service_role";



GRANT ALL ON TABLE "public"."wa_conversations" TO "anon";
GRANT ALL ON TABLE "public"."wa_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_conversations" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wa_conversations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wa_conversations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wa_conversations_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."wa_messages" TO "anon";
GRANT ALL ON TABLE "public"."wa_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."wa_messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wa_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wa_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wa_messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."work_schedules" TO "anon";
GRANT ALL ON TABLE "public"."work_schedules" TO "authenticated";
GRANT ALL ON TABLE "public"."work_schedules" TO "service_role";



GRANT ALL ON SEQUENCE "public"."work_schedules_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."work_schedules_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."work_schedules_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;
