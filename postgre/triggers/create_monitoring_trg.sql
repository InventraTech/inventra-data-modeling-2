-- ---------------------------------------------------
-- MONITORING TRIGGER CREATION
-- ---------------------------------------------------

-- só quando last_login muda: editar nome, perfil ou cozinha não conta como acesso
CREATE TRIGGER trg_register_daily_access
AFTER UPDATE OF last_login
ON tb_user
FOR EACH ROW
WHEN (NEW.last_login IS DISTINCT FROM OLD.last_login)
EXECUTE FUNCTION fn_register_daily_access();
