-- Valida o registro automático de acessos da V013 (DAU): trigger, tabela e views.
-- Usa datas de 2001, que nenhum dado real ou do seed tem, para não depender do banco estar vazio.
-- Roda numa transação desfeita no fim: não deixa dado no banco.
-- Uso: psql -v ON_ERROR_STOP=1 -f check_daily_access.sql

BEGIN;

DO $$
DECLARE
    v_kitchen INTEGER;
    v_user UUID := '00000000-0000-0000-0000-0000000000da';
    v_other_user UUID := '00000000-0000-0000-0000-0000000000db';
    v_rows INTEGER;
    v_count INTEGER;
    v_first TIME;
    v_last TIME;
    v_dau INTEGER;
    v_mau INTEGER;
    v_adoption DECIMAL;
BEGIN

    INSERT INTO tb_kitchen (name, code) VALUES ('Cozinha Teste DAU', 'DAU1') RETURNING id_kitchen INTO v_kitchen;
    INSERT INTO tb_profile (access_type) VALUES ('dau_teste') ON CONFLICT DO NOTHING;
    INSERT INTO tb_user (id_user, name, email, id_profile, id_kitchen)
    SELECT u.id_user, u.name, u.email, p.id_profile, v_kitchen
    FROM (VALUES
        (v_user, 'Teste DAU', 'dau@teste.com'),
        (v_other_user, 'Teste DAU 2', 'dau2@teste.com')
    ) AS u(id_user, name, email)
    CROSS JOIN tb_profile p
    WHERE p.access_type = 'dau_teste';

    -- primeiro login do dia -> uma linha com access_count 1
    UPDATE tb_user SET last_login = '2001-03-05 08:00' WHERE id_user = v_user;
    SELECT COUNT(*) INTO v_rows FROM tb_user_daily_access WHERE id_user = v_user;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION 'primeiro login deveria gerar 1 linha, gerou %', v_rows;
    END IF;

    -- segundo login no mesmo dia -> mesma linha, access_count 2, período 08:00-14:30
    UPDATE tb_user SET last_login = '2001-03-05 14:30' WHERE id_user = v_user;
    SELECT access_count, first_access_time, last_access_time INTO v_count, v_first, v_last
    FROM tb_user_daily_access WHERE id_user = v_user AND access_date = '2001-03-05';
    IF v_count <> 2 OR v_first <> '08:00' OR v_last <> '14:30' THEN
        RAISE EXCEPTION 'mesmo dia deveria somar na linha (2, 08:00, 14:30), ficou (%, %, %)', v_count, v_first, v_last;
    END IF;

    -- editar outra coluna não é acesso
    UPDATE tb_user SET name = 'Teste DAU editado' WHERE id_user = v_user;

    -- login no dia seguinte -> nova linha
    UPDATE tb_user SET last_login = '2001-03-06 09:00' WHERE id_user = v_user;

    -- last_login voltando no tempo (ex.: sp_restore_from_audit) ou apagado não é acesso
    UPDATE tb_user SET last_login = '2001-03-05 14:30' WHERE id_user = v_user;
    UPDATE tb_user SET last_login = NULL WHERE id_user = v_user;

    SELECT COUNT(*), SUM(access_count) INTO v_rows, v_count FROM tb_user_daily_access WHERE id_user = v_user;
    IF v_rows <> 2 OR v_count <> 3 THEN
        RAISE EXCEPTION 'esperado 2 dias e 3 acessos, ficou % dias e % acessos', v_rows, v_count;
    END IF;

    -- segundo usuário no primeiro dia
    UPDATE tb_user SET last_login = '2001-03-05 10:00' WHERE id_user = v_other_user;

    -- vw_dau: 2 no dia 5, 1 no dia 6, 0 no dia 7 (dia sem acesso aparece)
    SELECT dau, mau_30d INTO v_dau, v_mau FROM vw_dau WHERE access_date = '2001-03-05';
    IF v_dau <> 2 OR v_mau <> 2 THEN
        RAISE EXCEPTION 'vw_dau em 05/03: esperado DAU 2 e MAU 2, ficou % e %', v_dau, v_mau;
    END IF;

    SELECT dau, mau_30d INTO v_dau, v_mau FROM vw_dau WHERE access_date = '2001-03-06';
    IF v_dau <> 1 OR v_mau <> 2 THEN
        RAISE EXCEPTION 'vw_dau em 06/03: esperado DAU 1 e MAU 2, ficou % e %', v_dau, v_mau;
    END IF;

    SELECT dau INTO v_dau FROM vw_dau WHERE access_date = '2001-03-07';
    IF v_dau IS DISTINCT FROM 0 THEN
        RAISE EXCEPTION 'vw_dau em 07/03: dia sem acesso deveria aparecer com DAU 0, ficou %', v_dau;
    END IF;

    -- vw_dau_by_kitchen: os 2 usuários ativos da cozinha acessaram no dia 5 -> 100%
    SELECT dau, adoption_pct INTO v_dau, v_adoption
    FROM vw_dau_by_kitchen WHERE id_kitchen = v_kitchen AND access_date = '2001-03-05';
    IF v_dau <> 2 OR v_adoption <> 100 THEN
        RAISE EXCEPTION 'vw_dau_by_kitchen em 05/03: esperado DAU 2 e adoção 100, ficou % e %', v_dau, v_adoption;
    END IF;

    -- apagar o usuário apaga o histórico dele
    DELETE FROM tb_user WHERE id_user = v_user;
    SELECT COUNT(*) INTO v_rows FROM tb_user_daily_access WHERE id_user = v_user;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION 'histórico deveria ser apagado junto com o usuário, sobraram % linhas', v_rows;
    END IF;

    RAISE NOTICE 'V013: acesso registrado por dia, views de DAU corretas e histórico apagado com o usuário.';

END;
$$;

ROLLBACK;
