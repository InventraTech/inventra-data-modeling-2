-- ---------------------------------------------------
-- MONITORING FUNCTION CREATION
-- ---------------------------------------------------

-- Registra o acesso do dia a cada login: a API grava tb_user.last_login e a trigger
-- trg_register_daily_access chama esta function. Uma linha por usuário por dia;
-- novo acesso no mesmo dia só soma em access_count.
-- last_login apagado ou voltando no tempo (ex.: sp_restore_from_audit) não é login: ignora.
CREATE OR REPLACE FUNCTION fn_register_daily_access()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN

    IF NEW.last_login IS NULL
       OR (OLD.last_login IS NOT NULL AND NEW.last_login <= OLD.last_login) THEN
        RETURN NEW;
    END IF;

    INSERT INTO tb_user_daily_access
    (
        id_user,
        access_date,
        first_access_time,
        last_access_time,
        access_count
    )
    VALUES
    (
        NEW.id_user,
        NEW.last_login::date,
        NEW.last_login::time,
        NEW.last_login::time,
        1
    )
    ON CONFLICT (id_user, access_date) DO UPDATE
    SET first_access_time = LEAST(tb_user_daily_access.first_access_time, EXCLUDED.first_access_time),
        last_access_time = GREATEST(tb_user_daily_access.last_access_time, EXCLUDED.last_access_time),
        access_count = tb_user_daily_access.access_count + 1;

    RETURN NEW;

END;
$$;
