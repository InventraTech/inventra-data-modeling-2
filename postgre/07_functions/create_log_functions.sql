-- ---------------------------------------------------
-- LOG FUNCTION CREATION
-- ---------------------------------------------------

CREATE FUNCTION fn_log_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tb_log_user
        (id_user, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_user, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;  

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_user
        (id_user, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_user, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_user
        (id_user, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_user, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_product()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_product
        (id_product, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_product, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_product
        (id_product, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_product, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_product
        (id_product, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_product, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_supplier()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_supplier
        (id_supplier, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_supplier, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_supplier
        (id_supplier, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_supplier, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_supplier
        (id_supplier, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_supplier, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_stock_batch()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_stock_batch
        (id_batch, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_batch, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_stock_batch
        (id_batch, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_batch, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_stock_batch
        (id_batch, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_batch, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_requisition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_requisition
        (id_requisition, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_requisition, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_requisition
        (id_requisition, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_requisition, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_requisition
        (id_requisition, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_requisition, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_inventory()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_inventory
        (id_inventory, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_inventory, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_inventory
        (id_inventory, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_inventory, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_inventory
        (id_inventory, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_inventory, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE FUNCTION fn_log_alert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_alert
        (id_alert, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_alert, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_alert
        (id_alert, operation, db_user, previous_data, new_data)
        VALUES
        (NEW.id_alert, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_alert
        (id_alert, operation, db_user, previous_data, new_data)
        VALUES
        (OLD.id_alert, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;