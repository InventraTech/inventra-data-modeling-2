-- ===================================================
-- PROCEDURES
-- ===================================================

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