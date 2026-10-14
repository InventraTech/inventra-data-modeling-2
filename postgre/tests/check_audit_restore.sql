-- Valida sp_restore_from_audit nos três casos (UPDATE, DELETE, INSERT) e nos erros.
-- Deixa um produto e uma unidade no banco, para o backup do teste seguinte ter dados.
-- Uso: psql -v ON_ERROR_STOP=1 -f check_audit_restore.sql

DELETE FROM tb_product WHERE barcode LIKE 'BKP-TEST-%';

INSERT INTO tb_measurement_unit (symbol, description)
VALUES ('bkp', 'Unidade do teste de backup')
ON CONFLICT (symbol) DO NOTHING;

DO $$
DECLARE
    v_unit INTEGER;
    v_id INTEGER;
    v_id_insert INTEGER;
    v_log INTEGER;
    v_name VARCHAR(150);
    v_barcode VARCHAR(50);
    v_failed BOOLEAN;
BEGIN

    SELECT id_unit INTO v_unit FROM tb_measurement_unit WHERE symbol = 'bkp';

    INSERT INTO tb_product (name, id_unit, barcode)
    VALUES ('Produto Teste Backup', v_unit, 'BKP-TEST-0001')
    RETURNING id_product INTO v_id;

    -- UPDATE errado -> volta ao nome original
    UPDATE tb_product SET name = 'Nome Errado' WHERE id_product = v_id;

    SELECT MAX(id_log) INTO v_log
    FROM tb_log_product
    WHERE id_product = v_id AND operation = 'UPDATE';

    CALL sp_restore_from_audit(v_log);

    SELECT name INTO v_name FROM tb_product WHERE id_product = v_id;
    IF v_name IS DISTINCT FROM 'Produto Teste Backup' THEN
        RAISE EXCEPTION 'UPDATE não foi desfeito: name = %', v_name;
    END IF;

    -- DELETE acidental -> linha volta com o mesmo id
    DELETE FROM tb_product WHERE id_product = v_id;

    SELECT MAX(id_log) INTO v_log
    FROM tb_log_product
    WHERE id_product = v_id AND operation = 'DELETE';

    CALL sp_restore_from_audit(v_log);

    SELECT barcode INTO v_barcode FROM tb_product WHERE id_product = v_id;
    IF v_barcode IS DISTINCT FROM 'BKP-TEST-0001' THEN
        RAISE EXCEPTION 'DELETE não foi desfeito: produto % não voltou', v_id;
    END IF;

    -- restaurar o mesmo DELETE de novo precisa falhar (a linha já existe)
    v_failed := false;
    BEGIN
        CALL sp_restore_from_audit(v_log);
    EXCEPTION WHEN raise_exception THEN
        v_failed := true;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Restaurar um DELETE de linha existente deveria falhar';
    END IF;

    -- INSERT indevido -> linha removida
    INSERT INTO tb_product (name, id_unit, barcode)
    VALUES ('Produto Inserido por Engano', v_unit, 'BKP-TEST-0002')
    RETURNING id_product INTO v_id_insert;

    SELECT MAX(id_log) INTO v_log
    FROM tb_log_product
    WHERE id_product = v_id_insert AND operation = 'INSERT';

    CALL sp_restore_from_audit(v_log);

    IF EXISTS (SELECT 1 FROM tb_product WHERE id_product = v_id_insert) THEN
        RAISE EXCEPTION 'INSERT não foi desfeito: produto % ainda existe', v_id_insert;
    END IF;

    -- id de log inexistente
    v_failed := false;
    BEGIN
        CALL sp_restore_from_audit(-1);
    EXCEPTION WHEN raise_exception THEN
        v_failed := true;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'Log inexistente deveria falhar';
    END IF;

    -- a recuperação também é auditada: INSERT, UPDATE, UPDATE (restore), DELETE, INSERT (restore)
    IF (SELECT COUNT(*) FROM tb_log_product WHERE id_product = v_id) <> 5 THEN
        RAISE EXCEPTION 'Esperava 5 registros de auditoria para o produto %', v_id;
    END IF;

    RAISE NOTICE 'sp_restore_from_audit: UPDATE, DELETE e INSERT desfeitos; erros tratados.';

END;
$$;
