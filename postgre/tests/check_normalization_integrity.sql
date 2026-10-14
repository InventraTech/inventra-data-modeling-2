-- Valida as proteções da V012 sobre as redundâncias controladas (NORMALIZATION.md, R1 e R4).
-- Roda numa transação desfeita no fim: não deixa dado no banco.
-- Uso: psql -v ON_ERROR_STOP=1 -f check_normalization_integrity.sql

BEGIN;

DO $$
DECLARE
    v_unit INTEGER;
    v_kitchen INTEGER;
    v_other_kitchen INTEGER;
    v_product INTEGER;
    v_other_product INTEGER;
    v_batch INTEGER;
    v_user UUID := '00000000-0000-0000-0000-0000000000ff';
    v_inventory INTEGER;
    v_count INTEGER;
    v_alert INTEGER;
    v_divergence DECIMAL(12,3);
    v_id_product INTEGER;
    v_id_kitchen INTEGER;
    v_failed BOOLEAN;
BEGIN

    INSERT INTO tb_measurement_unit (symbol, description) VALUES ('nrm', 'Unidade do teste') RETURNING id_unit INTO v_unit;
    INSERT INTO tb_kitchen (name, code) VALUES ('Cozinha Teste 1', 'NRM1') RETURNING id_kitchen INTO v_kitchen;
    INSERT INTO tb_kitchen (name, code) VALUES ('Cozinha Teste 2', 'NRM2') RETURNING id_kitchen INTO v_other_kitchen;
    INSERT INTO tb_product (name, id_unit) VALUES ('Produto Teste 1', v_unit) RETURNING id_product INTO v_product;
    INSERT INTO tb_product (name, id_unit) VALUES ('Produto Teste 2', v_unit) RETURNING id_product INTO v_other_product;
    INSERT INTO tb_profile (access_type) VALUES ('nrm_teste') ON CONFLICT DO NOTHING;
    INSERT INTO tb_user (id_user, name, email, id_profile)
    SELECT v_user, 'Teste', 'nrm@teste.com', id_profile FROM tb_profile WHERE access_type = 'nrm_teste';

    INSERT INTO tb_stock_batch (id_product, id_kitchen, batch_number, initial_quantity, current_quantity, entry_date, expiration_date)
    VALUES (v_product, v_kitchen, 'NRM-L1', 10, 10, CURRENT_DATE, CURRENT_DATE + 30)
    RETURNING id_batch INTO v_batch;

    -- R1: valor escrito à mão em divergence é recalculado
    INSERT INTO tb_inventory (id_kitchen, id_responsible_user) VALUES (v_kitchen, v_user) RETURNING id_inventory INTO v_inventory;
    INSERT INTO tb_inventory_count (id_inventory, id_batch, registered_quantity, physical_quantity)
    VALUES (v_inventory, v_batch, 10, 7)
    RETURNING id_count INTO v_count;

    UPDATE tb_inventory_count SET divergence = 99 WHERE id_count = v_count;
    SELECT divergence INTO v_divergence FROM tb_inventory_count WHERE id_count = v_count;
    IF v_divergence <> -3 THEN
        RAISE EXCEPTION 'R1: divergence deveria ser -3 após UPDATE manual, ficou %', v_divergence;
    END IF;

    -- R4: alerta com lote e sem produto -> produto preenchido pelo lote
    INSERT INTO tb_alert (type, severity, id_batch, id_kitchen, message)
    VALUES ('EXPIRING', 'LOW', v_batch, v_kitchen, 'teste')
    RETURNING id_alert INTO v_alert;

    SELECT id_product, id_kitchen INTO v_id_product, v_id_kitchen FROM tb_alert WHERE id_alert = v_alert;
    IF v_id_product IS DISTINCT FROM v_product OR v_id_kitchen <> v_kitchen THEN
        RAISE EXCEPTION 'R4: alerta deveria herdar produto % e cozinha % do lote, ficou % e %',
            v_product, v_kitchen, v_id_product, v_id_kitchen;
    END IF;

    -- R4: produto diferente do lote -> recusado
    v_failed := false;
    BEGIN
        INSERT INTO tb_alert (type, severity, id_batch, id_product, id_kitchen, message)
        VALUES ('EXPIRING', 'LOW', v_batch, v_other_product, v_kitchen, 'teste');
    EXCEPTION WHEN raise_exception THEN
        v_failed := true;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'R4: alerta com produto diferente do lote deveria ser recusado';
    END IF;

    -- R4: trocar a cozinha de um alerta com lote -> recusado
    v_failed := false;
    BEGIN
        UPDATE tb_alert SET id_kitchen = v_other_kitchen WHERE id_alert = v_alert;
    EXCEPTION WHEN raise_exception THEN
        v_failed := true;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'R4: trocar a cozinha de alerta com lote deveria ser recusado';
    END IF;

    -- alerta sem lote (ex.: STOCK) continua livre
    INSERT INTO tb_alert (type, severity, id_product, id_kitchen, message)
    VALUES ('STOCK', 'HIGH', v_other_product, v_other_kitchen, 'teste');

    RAISE NOTICE 'V012: divergence recalculada; alerta herda e protege produto e cozinha do lote.';

END;
$$;

ROLLBACK;
