-- ---------------------------------------------------
-- ROLLBACK DE FUNCTIONS DE LOG
-- ---------------------------------------------------

DROP FUNCTION IF EXISTS fn_log_usuario();

DROP FUNCTION IF EXISTS fn_log_produto();

DROP FUNCTION IF EXISTS fn_log_fornecedor();

DROP FUNCTION IF EXISTS fn_log_estoque_lote();

DROP FUNCTION IF EXISTS fn_log_requisicao();

DROP FUNCTION IF EXISTS fn_log_inventario();

DROP FUNCTION IF EXISTS fn_log_alerta();