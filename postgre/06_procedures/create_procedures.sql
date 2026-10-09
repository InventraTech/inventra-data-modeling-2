-- ---------------------------------------------------
-- PROCEDURE CREATION
-- ---------------------------------------------------

CREATE PROCEDURE sp_approve_requisition(
    p_id_requisition INTEGER,
    p_id_approver_user UUID
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status = 'UNDER_REVIEW'
    ) THEN
        RAISE EXCEPTION
            'Requisição % não está mais em análise.',
            p_id_requisition;
    END IF;

    UPDATE tb_requisition
    SET
        status = 'APPROVED',
        id_approver_user = p_id_approver_user
    WHERE id_requisition = p_id_requisition;

END;
$$;

CREATE PROCEDURE sp_reject_requisition(
    p_id_requisition INTEGER,
    p_id_approver_user UUID,
    p_reason VARCHAR(255)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status = 'UNDER_REVIEW'
    ) THEN
        RAISE EXCEPTION
            'Requisição % não está mais em análise.',
            p_id_requisition;
    END IF;

    UPDATE tb_requisition
    SET
        status = 'REJECTED',
        id_approver_user = p_id_approver_user,
        reason = p_reason
    WHERE id_requisition = p_id_requisition;

END;
$$;

CREATE PROCEDURE sp_cancel_requisition(
    p_id_requisition INTEGER,
    p_reason VARCHAR(255)
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
    ) THEN
        RAISE EXCEPTION
            'Requisição % não encontrada.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status IN ('UNDER_REVIEW', 'APPROVED')
    ) THEN
        RAISE EXCEPTION
            'Requisição % não pode ser cancelada no status atual.',
            p_id_requisition;
    END IF;

    UPDATE tb_requisition
    SET
        status = 'CANCELLED',
        reason = p_reason
    WHERE id_requisition = p_id_requisition;

END;
$$;

CREATE PROCEDURE sp_register_stock_entry(
    p_id_batch INTEGER,
    p_quantity DECIMAL(12,3)
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_status VARCHAR(20);
BEGIN

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION
            'A quantidade de entrada deve ser maior que zero.';
    END IF;

    SELECT status
    INTO v_status
    FROM tb_stock_batch
    WHERE id_batch = p_id_batch;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Lote % não encontrado.',
            p_id_batch;
    END IF;

    IF v_status IN ('EXPIRED', 'CANCELLED') THEN
        RAISE EXCEPTION
            'Não é possível dar entrada em lote vencido ou cancelado.';
    END IF;

    UPDATE tb_stock_batch
    SET
        current_quantity = current_quantity + p_quantity,
        status = 'ACTIVE'
    WHERE id_batch = p_id_batch;

END;
$$;

CREATE PROCEDURE sp_write_off_stock(
    p_id_batch INTEGER,
    p_quantity DECIMAL(12,3)
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_status VARCHAR(20);
    v_current_quantity DECIMAL(12,3);
BEGIN

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION
            'A quantidade de baixa deve ser maior que zero.';
    END IF;

    SELECT status, current_quantity
    INTO v_status, v_current_quantity
    FROM tb_stock_batch
    WHERE id_batch = p_id_batch
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Lote % não encontrado.',
            p_id_batch;
    END IF;

    IF v_status <> 'ACTIVE' THEN
        RAISE EXCEPTION
            'Só é possível dar baixa em lote ativo.';
    END IF;

    IF v_current_quantity < p_quantity THEN
        RAISE EXCEPTION
            'Saldo insuficiente para dar baixa no lote %.',
            p_id_batch;
    END IF;

    UPDATE tb_stock_batch
    SET
        current_quantity = current_quantity - p_quantity
    WHERE id_batch = p_id_batch;

END;
$$;

CREATE PROCEDURE sp_close_inventory(
    p_id_inventory INTEGER
)
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM tb_inventory
        WHERE id_inventory = p_id_inventory
    ) THEN
        RAISE EXCEPTION
            'Inventário % não encontrado.',
            p_id_inventory;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_inventory
        WHERE id_inventory = p_id_inventory
          AND status = 'OPEN'
    ) THEN
        RAISE EXCEPTION
            'Inventário % não está mais aberto.',
            p_id_inventory;
    END IF;

    UPDATE tb_inventory
    SET
        status = 'CLOSED',
        closed_at = CURRENT_TIMESTAMP
    WHERE id_inventory = p_id_inventory;

END;
$$;

CREATE PROCEDURE sp_expire_batches()
LANGUAGE plpgsql
AS
$$
BEGIN

    CREATE TEMP TABLE tmp_expired_batches ON COMMIT DROP AS
    SELECT id_batch, id_product, id_kitchen
    FROM tb_stock_batch
    WHERE status = 'ACTIVE'
      AND expiration_date < CURRENT_DATE;

    UPDATE tb_stock_batch sb
    SET status = 'EXPIRED'
    FROM tmp_expired_batches e
    WHERE sb.id_batch = e.id_batch;

    INSERT INTO tb_alert (type, severity, id_batch, id_product, id_kitchen, message)
    SELECT 'EXPIRATION', 'CRITICAL', e.id_batch, e.id_product, e.id_kitchen,
           'Lote vencido. Verifique a validade do produto.'
    FROM tmp_expired_batches e
    WHERE NOT EXISTS (
        SELECT 1 FROM tb_alert a
        WHERE a.id_batch = e.id_batch
          AND a.type = 'EXPIRATION'
          AND a.is_read = false
    );

    INSERT INTO tb_alert (type, severity, id_product, id_kitchen, message)
    SELECT DISTINCT 'STOCK', 'HIGH', p.id_product, p.id_kitchen, 'Produto abaixo do estoque mínimo.'
    FROM tmp_expired_batches e
    JOIN tb_product_kitchen_parameter p
      ON p.id_product = e.id_product AND p.id_kitchen = e.id_kitchen
    WHERE p.min_stock > (
        SELECT COALESCE(SUM(sb.current_quantity), 0)
        FROM tb_stock_batch sb
        WHERE sb.id_product = p.id_product
          AND sb.id_kitchen = p.id_kitchen
          AND sb.status = 'ACTIVE'
          AND (sb.expiration_date IS NULL OR sb.expiration_date >= CURRENT_DATE)
    )
      AND NOT EXISTS (
        SELECT 1 FROM tb_alert a
        WHERE a.id_product = p.id_product
          AND a.id_kitchen = p.id_kitchen
          AND a.type = 'STOCK'
          AND a.is_read = false
    );

    DROP TABLE tmp_expired_batches;

END;
$$;
