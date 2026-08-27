-- ---------------------------------------------------
-- CRIAÇÃO DE FUNCTIONS
-- ---------------------------------------------------

CREATE FUNCTION fn_validar_estoque()
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

CREATE FUNCTION fn_atualizar_status_lote()
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

CREATE FUNCTION fn_calcular_divergencia()
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

CREATE FUNCTION fn_aprovacao_requisicao()
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

CREATE FUNCTION fn_alerta_estoque()
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

CREATE FUNCTION fn_alerta_validade()
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