-- ---------------------------------------------------
-- FUNCTION CREATION
-- ---------------------------------------------------

CREATE FUNCTION fn_validate_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.current_quantity < 0 THEN
        RAISE EXCEPTION
            'O saldo do lote não pode ficar negativo.';
    END IF;

    RETURN NEW;

END;
$$;

CREATE FUNCTION fn_update_batch_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.current_quantity = 0
       AND NEW.status = 'ACTIVE' THEN

        NEW.status := 'WRITTEN_OFF';

    END IF;

    RETURN NEW;

END;
$$;

CREATE FUNCTION fn_calculate_divergence()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    NEW.divergence :=
        NEW.physical_quantity - NEW.registered_quantity;

    RETURN NEW;

END;
$$;

CREATE FUNCTION fn_requisition_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.status = 'APPROVED'
       AND OLD.status IS DISTINCT FROM 'APPROVED' THEN

        NEW.approved_at := CURRENT_TIMESTAMP;

    END IF;

    RETURN NEW;

END;
$$;

CREATE FUNCTION fn_stock_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_min_stock DECIMAL(12,3);
    v_total_quantity DECIMAL(12,3);
    v_existing_alert INTEGER;
BEGIN

    SELECT min_stock
    INTO v_min_stock
    FROM tb_product_kitchen_parameter
    WHERE id_product = NEW.id_product
      AND id_kitchen = NEW.id_kitchen;

    IF v_min_stock IS NULL THEN
        RETURN NEW;
    END IF;

    -- trigger AFTER: a linha alterada já aparece com o valor novo nessa soma; lote vencido não conta
    SELECT COALESCE(SUM(current_quantity), 0)
    INTO v_total_quantity
    FROM tb_stock_batch
    WHERE id_product = NEW.id_product
      AND id_kitchen = NEW.id_kitchen
      AND status = 'ACTIVE'
      AND (expiration_date IS NULL OR expiration_date >= CURRENT_DATE);

    IF v_total_quantity < v_min_stock THEN

        SELECT id_alert
        INTO v_existing_alert
        FROM tb_alert
        WHERE id_product = NEW.id_product
          AND id_kitchen = NEW.id_kitchen
          AND type = 'STOCK'
          AND is_read = false
        LIMIT 1;

        IF v_existing_alert IS NULL THEN

            INSERT INTO tb_alert
            (
                type,
                severity,
                id_batch,
                id_product,
                id_kitchen,
                message
            )
            VALUES
            (
                'STOCK',
                'HIGH',
                NEW.id_batch,
                NEW.id_product,
                NEW.id_kitchen,
                'Produto abaixo do estoque mínimo.'
            );

        END IF;

    END IF;

    RETURN NEW;

END;
$$;

CREATE FUNCTION fn_expiration_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    v_existing_alert INTEGER;
BEGIN

    IF NEW.expiration_date IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.expiration_date < CURRENT_DATE THEN

        SELECT id_alert
        INTO v_existing_alert
        FROM tb_alert
        WHERE id_batch = NEW.id_batch
          AND type = 'EXPIRATION'
          AND is_read = false
        LIMIT 1;

        IF v_existing_alert IS NULL THEN

            INSERT INTO tb_alert
            (
                type,
                severity,
                id_batch,
                id_product,
                id_kitchen,
                message
            )
            VALUES
            (
                'EXPIRATION',
                'CRITICAL',
                NEW.id_batch,
                NEW.id_product,
                NEW.id_kitchen,
                'Lote vencido. Verifique a validade do produto.'
            );

        END IF;

    END IF;

    RETURN NEW;

END;
$$;
