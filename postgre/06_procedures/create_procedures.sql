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
            'Requisition % not found.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status = 'UNDER_REVIEW'
    ) THEN
        RAISE EXCEPTION
            'Requisition % is not under review.',
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
            'Requisition % not found.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status = 'UNDER_REVIEW'
    ) THEN
        RAISE EXCEPTION
            'Requisition % is not under review.',
            p_id_requisition;
    END IF;

    UPDATE tb_requisition
    SET
        status = 'REJECTED',
        id_approver_user = p_id_approver_user,
        reason = p_reason,
        approved_at = CURRENT_TIMESTAMP
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
            'Requisition % not found.',
            p_id_requisition;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_requisition
        WHERE id_requisition = p_id_requisition
          AND status IN ('UNDER_REVIEW', 'APPROVED')
    ) THEN
        RAISE EXCEPTION
            'Requisition % cannot be cancelled in its current status.',
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
BEGIN

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Entry quantity must be greater than zero.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_stock_batch
        WHERE id_batch = p_id_batch
    ) THEN
        RAISE EXCEPTION
            'Batch % not found.',
            p_id_batch;
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
BEGIN

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION
            'Write-off quantity must be greater than zero.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_stock_batch
        WHERE id_batch = p_id_batch
    ) THEN
        RAISE EXCEPTION
            'Batch % not found.',
            p_id_batch;
    END IF;

    IF (
        SELECT current_quantity
        FROM tb_stock_batch
        WHERE id_batch = p_id_batch
    ) < p_quantity THEN
        RAISE EXCEPTION
            'Insufficient stock to write off batch %.',
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
            'Inventory % not found.',
            p_id_inventory;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM tb_inventory
        WHERE id_inventory = p_id_inventory
          AND status = 'OPEN'
    ) THEN
        RAISE EXCEPTION
            'Inventory % is not open.',
            p_id_inventory;
    END IF;

    UPDATE tb_inventory
    SET
        status = 'CLOSED',
        closed_at = CURRENT_TIMESTAMP
    WHERE id_inventory = p_id_inventory;

END;
$$;