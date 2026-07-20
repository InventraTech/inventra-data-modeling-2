-- ===================================================
-- LOG FUNCTIONS
-- ===================================================

CREATE OR REPLACE FUNCTION fn_log_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tb_log_usuario
        (id_usuario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_usuario, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;  

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_usuario
        (id_usuario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_usuario, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_usuario
        (id_usuario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_usuario, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION fn_log_produto()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_produto
        (id_produto, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_produto, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_produto
        (id_produto, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_produto, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_produto
        (id_produto, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_produto, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_log_fornecedor()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_fornecedor
        (id_fornecedor, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_fornecedor, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_fornecedor
        (id_fornecedor, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_fornecedor, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_fornecedor
        (id_fornecedor, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_fornecedor, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_log_estoque_lote()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_estoque_lote
        (id_lote, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_lote, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_estoque_lote
        (id_lote, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_lote, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_estoque_lote
        (id_lote, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_lote, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_log_requisicao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_requisicao
        (id_requisicao, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_requisicao, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_requisicao
        (id_requisicao, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_requisicao, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_requisicao
        (id_requisicao, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_requisicao, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_log_inventario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_inventario
        (id_inventario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_inventario, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_inventario
        (id_inventario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_inventario, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_inventario
        (id_inventario, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_inventario, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;


CREATE OR REPLACE FUNCTION fn_log_alerta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN

        INSERT INTO tb_log_alerta
        (id_alerta, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_alerta, TG_OP, CURRENT_USER, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO tb_log_alerta
        (id_alerta, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (NEW.id_alerta, TG_OP, CURRENT_USER, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO tb_log_alerta
        (id_alerta, operacao, usuario_bd, dados_anteriores, dados_novos)
        VALUES
        (OLD.id_alerta, TG_OP, CURRENT_USER, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;
END;
$$;