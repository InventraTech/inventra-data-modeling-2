-- Valida o contador de cliques da V014: linha única, soma por coluna, view de ranking e catálogo.
-- Roda numa transação desfeita no fim: não deixa dado no banco e não zera os contadores reais.
-- Uso: psql -v ON_ERROR_STOP=1 -f check_ui_click_counter.sql

BEGIN;

DO $$
DECLARE
    v_rows INTEGER;
    v_columns INTEGER;
    v_documented INTEGER;
    v_before BIGINT;
    v_after BIGINT;
    v_mobile_before BIGINT;
    v_view BIGINT;
    v_failed BOOLEAN;
    v_share DECIMAL;
BEGIN

    -- a linha única nasce com a migration
    SELECT COUNT(*) INTO v_rows FROM tb_ui_click_counter;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION 'o contador deveria ter 1 linha, tem %', v_rows;
    END IF;

    -- uma coluna por coisa clicável (fora id_counter), web e mobile
    SELECT COUNT(*) INTO v_columns
    FROM information_schema.columns
    WHERE table_name = 'tb_ui_click_counter' AND column_name <> 'id_counter';
    IF v_columns < 200 THEN
        RAISE EXCEPTION 'o contador deveria ter uma coluna por elemento clicável, tem %', v_columns;
    END IF;
    SELECT COUNT(*) INTO v_rows
    FROM information_schema.columns
    WHERE table_name = 'tb_ui_click_counter' AND column_name LIKE '%\_wb\_%';
    IF v_rows < 100 THEN
        RAISE EXCEPTION 'faltam colunas web (wb): %', v_rows;
    END IF;
    SELECT COUNT(*) INTO v_rows
    FROM information_schema.columns
    WHERE table_name = 'tb_ui_click_counter' AND column_name LIKE '%\_mb\_%';
    IF v_rows < 50 THEN
        RAISE EXCEPTION 'faltam colunas mobile (mb): %', v_rows;
    END IF;

    -- só existe a linha 1
    v_failed := false;
    BEGIN
        INSERT INTO tb_ui_click_counter (id_counter) VALUES (2);
    EXCEPTION WHEN check_violation THEN
        v_failed := true;
    END;
    IF NOT v_failed THEN
        RAISE EXCEPTION 'uma segunda linha no contador deveria ser recusada';
    END IF;

    -- cada clique soma 1 na coluna do elemento e em mais nenhuma
    SELECT bt_wb_login_sign_in INTO v_before FROM tb_ui_click_counter;
    SELECT bt_mb_login_sign_in INTO v_mobile_before FROM tb_ui_click_counter;
    UPDATE tb_ui_click_counter SET bt_wb_login_sign_in = bt_wb_login_sign_in + 1;
    UPDATE tb_ui_click_counter SET bt_wb_login_sign_in = bt_wb_login_sign_in + 1;
    SELECT bt_wb_login_sign_in INTO v_after FROM tb_ui_click_counter;
    IF v_after <> v_before + 2 THEN
        RAISE EXCEPTION 'dois cliques deveriam somar 2: era %, ficou %', v_before, v_after;
    END IF;
    SELECT bt_mb_login_sign_in INTO v_after FROM tb_ui_click_counter;
    IF v_after <> v_mobile_before THEN
        RAISE EXCEPTION 'o clique no web não deveria mexer no botão do mobile';
    END IF;

    -- vw_ui_click_ranking: uma linha por coluna, valores iguais aos da tabela, plataforma sempre preenchida
    SELECT COUNT(*) INTO v_rows FROM vw_ui_click_ranking;
    IF v_rows <> v_columns THEN
        RAISE EXCEPTION 'a view deveria ter % linhas, tem %', v_columns, v_rows;
    END IF;
    SELECT clicks INTO v_view FROM vw_ui_click_ranking WHERE column_name = 'bt_wb_login_sign_in';
    SELECT bt_wb_login_sign_in INTO v_after FROM tb_ui_click_counter;
    IF v_view <> v_after THEN
        RAISE EXCEPTION 'a view deveria mostrar % cliques em bt_wb_login_sign_in, mostrou %', v_after, v_view;
    END IF;
    SELECT COUNT(*) INTO v_rows FROM vw_ui_click_ranking WHERE platform IS NULL;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION '% colunas sem plataforma na view (nome fora do padrão tipo_plataforma_tela_nome)', v_rows;
    END IF;
    SELECT SUM(share_pct) INTO v_share FROM vw_ui_click_ranking WHERE platform = 'WEB';
    IF v_share IS NOT NULL AND ABS(v_share - 100) > 2 THEN
        RAISE EXCEPTION 'as participações da web deveriam somar ~100%%, somaram %', v_share;
    END IF;
    SELECT COUNT(*) INTO v_rows FROM vw_ui_click_ranking WHERE description IS NULL;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION '% colunas do contador sem descrição no catálogo', v_rows;
    END IF;

    -- catálogo: toda coluna documentada
    SELECT COUNT(*) INTO v_documented
    FROM vw_data_catalog
    WHERE table_name = 'tb_ui_click_counter' AND is_documented;
    IF v_documented <> v_columns + 1 THEN
        RAISE EXCEPTION 'o catálogo deveria documentar % colunas do contador, documentou %', v_columns + 1, v_documented;
    END IF;

    RAISE NOTICE 'V014: linha única, soma por coluna, ranking e catálogo corretos.';

END;
$$;

ROLLBACK;
