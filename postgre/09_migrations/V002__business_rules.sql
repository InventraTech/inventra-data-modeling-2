-- ---------------------------------------------------
-- CRIAÇÃO DE FUNCTIONS
-- ---------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_estoque()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.qtd_atual < 0 THEN
        RAISE EXCEPTION
            'A quantidade atual do lote não pode ser negativa. Lote: %',
            NEW.id_lote;
    END IF;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION fn_atualizar_status_lote()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.qtd_atual = 0
       AND NEW.status = 'ATIVO' THEN

        NEW.status := 'BAIXA';

    END IF;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION fn_calcular_divergencia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    NEW.divergencia :=
        NEW.qtd_fisica - NEW.qtd_registrada;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION fn_aprovacao_requisicao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.status = 'APROVADO'
       AND OLD.status IS DISTINCT FROM 'APROVADO' THEN

        NEW.data_aprovacao := CURRENT_TIMESTAMP;

    END IF;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION fn_alerta_estoque()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_estoque_minimo DECIMAL(12,3);
    v_alerta_existente INTEGER;
BEGIN

    SELECT estoque_minimo
    INTO v_estoque_minimo
    FROM tb_produto_parametro_cozinha
    WHERE id_produto = NEW.id_produto
      AND id_cozinha = NEW.id_cozinha;

    IF v_estoque_minimo IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.qtd_atual <= v_estoque_minimo THEN

        SELECT id_alerta
        INTO v_alerta_existente
        FROM tb_alerta
        WHERE id_produto = NEW.id_produto
          AND id_cozinha = NEW.id_cozinha
          AND tipo = 'ESTOQUE'
          AND lido = false
        LIMIT 1;

        IF v_alerta_existente IS NULL THEN

            INSERT INTO tb_alerta
            (
                tipo,
                severidade,
                id_lote,
                id_produto,
                id_cozinha,
                mensagem
            )
            VALUES
            (
                'ESTOQUE',
                'ALTA',
                NEW.id_lote,
                NEW.id_produto,
                NEW.id_cozinha,
                'Produto abaixo do estoque mínimo.'
            );

        END IF;

    END IF;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION fn_alerta_validade()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_alerta_existente INTEGER;
BEGIN

    IF NEW.data_validade IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.data_validade < CURRENT_DATE THEN

        SELECT id_alerta
        INTO v_alerta_existente
        FROM tb_alerta
        WHERE id_lote = NEW.id_lote
          AND tipo = 'VALIDADE'
          AND lido = false
        LIMIT 1;

        IF v_alerta_existente IS NULL THEN

            INSERT INTO tb_alerta
            (
                tipo,
                severidade,
                id_lote,
                id_produto,
                id_cozinha,
                mensagem
            )
            VALUES
            (
                'VALIDADE',
                'CRITICA',
                NEW.id_lote,
                NEW.id_produto,
                NEW.id_cozinha,
                'Lote vencido. Verifique a validade do produto.'
            );

        END IF;

    END IF;

    RETURN NEW;

END;
$$;

-- ---------------------------------------------------
-- CRIAÇÃO DE PROCEDURES
-- ---------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_aprovar_requisicao(
    p_id_requisicao INTEGER,
    p_id_usuario_aprovador UUID
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisicao;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
          AND status = 'EM_ANALISE'
    ) THEN
        RAISE EXCEPTION
            'A requisição % não está em análise.',
            p_id_requisicao;
    END IF;

    UPDATE tb_requisicao
    SET
        status = 'APROVADO',
        id_usuario_aprovador = p_id_usuario_aprovador
    WHERE id_requisicao = p_id_requisicao;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_reprovar_requisicao(
    p_id_requisicao INTEGER,
    p_id_usuario_aprovador UUID,
    p_motivo VARCHAR(255)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisicao;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
          AND status = 'EM_ANALISE'
    ) THEN
        RAISE EXCEPTION
            'A requisição % não está em análise.',
            p_id_requisicao;
    END IF;

    UPDATE tb_requisicao
    SET
        status = 'REPROVADO',
        id_usuario_aprovador = p_id_usuario_aprovador,
        motivo = p_motivo,
        data_aprovacao = CURRENT_TIMESTAMP
    WHERE id_requisicao = p_id_requisicao;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_cancelar_requisicao(
    p_id_requisicao INTEGER,
    p_motivo VARCHAR(255)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisicao;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisicao
        WHERE id_requisicao = p_id_requisicao
          AND status IN ('EM_ANALISE', 'APROVADO')
    ) THEN
        RAISE EXCEPTION
            'A requisição % não pode ser cancelada no status atual.',
            p_id_requisicao;
    END IF;

    UPDATE tb_requisicao
    SET
        status = 'CANCELADO',
        motivo = p_motivo
    WHERE id_requisicao = p_id_requisicao;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_registrar_entrada_estoque(
    p_id_lote INTEGER,
    p_quantidade DECIMAL(12,3)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF p_quantidade <= 0 THEN
        RAISE EXCEPTION
            'A quantidade de entrada deve ser maior que zero.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_estoque_lote
        WHERE id_lote = p_id_lote
    ) THEN
        RAISE EXCEPTION
            'Lote % não encontrado.',
            p_id_lote;
    END IF;

    UPDATE tb_estoque_lote
    SET
        qtd_atual = qtd_atual + p_quantidade,
        status = 'ATIVO'
    WHERE id_lote = p_id_lote;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_baixar_estoque(
    p_id_lote INTEGER,
    p_quantidade DECIMAL(12,3)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF p_quantidade <= 0 THEN
        RAISE EXCEPTION
            'A quantidade da baixa deve ser maior que zero.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_estoque_lote
        WHERE id_lote = p_id_lote
    ) THEN
        RAISE EXCEPTION
            'Lote % não encontrado.',
            p_id_lote;
    END IF;

    IF (
        SELECT qtd_atual
        FROM tb_estoque_lote
        WHERE id_lote = p_id_lote
    ) < p_quantidade THEN
        RAISE EXCEPTION
            'Estoque insuficiente para realizar a baixa do lote %.',
            p_id_lote;
    END IF;

    UPDATE tb_estoque_lote
    SET
        qtd_atual = qtd_atual - p_quantidade
    WHERE id_lote = p_id_lote;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_fechar_inventario(
    p_id_inventario INTEGER
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_inventario
        WHERE id_inventario = p_id_inventario
    ) THEN
        RAISE EXCEPTION
            'Inventário % não encontrado.',
            p_id_inventario;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_inventario
        WHERE id_inventario = p_id_inventario
          AND status = 'ABERTO'
    ) THEN
        RAISE EXCEPTION
            'O inventário % não está aberto.',
            p_id_inventario;
    END IF;

    UPDATE tb_inventario
    SET
        status = 'FECHADO',
        data_fechamento = CURRENT_TIMESTAMP
    WHERE id_inventario = p_id_inventario;

END;
$$;

-- ---------------------------------------------------
-- CRIAÇÃO DE TRIGGERS
-- ---------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_validar_estoque') THEN
        CREATE TRIGGER trg_validar_estoque
        BEFORE INSERT OR UPDATE OF qtd_atual
        ON tb_estoque_lote
        FOR EACH ROW
        EXECUTE FUNCTION fn_validar_estoque();
    END IF;
END;
$$;        

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_atualizar_status_lote') THEN
        CREATE TRIGGER trg_atualizar_status_lote
        BEFORE INSERT OR UPDATE OF qtd_atual, status
        ON tb_estoque_lote
        FOR EACH ROW
        EXECUTE FUNCTION fn_atualizar_status_lote();
    END IF;
END;
$$;        

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_calcular_divergencia') THEN
        CREATE TRIGGER trg_calcular_divergencia
        BEFORE INSERT OR UPDATE OF qtd_registrada, qtd_fisica
        ON tb_inventario_contagem
        FOR EACH ROW
        EXECUTE FUNCTION fn_calcular_divergencia();
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_aprovacao_requisicao') THEN
        CREATE TRIGGER trg_aprovacao_requisicao
        BEFORE UPDATE OF status
        ON tb_requisicao
        FOR EACH ROW
        EXECUTE FUNCTION fn_aprovacao_requisicao();
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_alerta_estoque') THEN
        CREATE TRIGGER trg_alerta_estoque
        AFTER INSERT OR UPDATE OF qtd_atual
        ON tb_estoque_lote
        FOR EACH ROW
        EXECUTE FUNCTION fn_alerta_estoque();
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_alerta_validade') THEN
        CREATE TRIGGER trg_alerta_validade
        AFTER INSERT OR UPDATE OF data_validade
        ON tb_estoque_lote
        FOR EACH ROW
        EXECUTE FUNCTION fn_alerta_validade();
    END IF;
END;
$$;