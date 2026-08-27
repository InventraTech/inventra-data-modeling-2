-- ---------------------------------------------------
-- CRIAÇÃO DE TRIGGERS DE LOG
-- ---------------------------------------------------

CREATE TRIGGER trg_log_usuario
AFTER INSERT OR UPDATE OR DELETE
ON tb_usuario
FOR EACH ROW EXECUTE FUNCTION fn_log_usuario();

CREATE TRIGGER trg_log_produto
AFTER INSERT OR UPDATE OR DELETE
ON tb_produto
FOR EACH ROW EXECUTE FUNCTION fn_log_produto();

CREATE TRIGGER trg_log_fornecedor
AFTER INSERT OR UPDATE OR DELETE
ON tb_fornecedor
FOR EACH ROW EXECUTE FUNCTION fn_log_fornecedor();

CREATE TRIGGER trg_log_estoque_lote
AFTER INSERT OR UPDATE OR DELETE
ON tb_estoque_lote
FOR EACH ROW EXECUTE FUNCTION fn_log_estoque_lote();

CREATE TRIGGER trg_log_requisicao
AFTER INSERT OR UPDATE OR DELETE
ON tb_requisicao
FOR EACH ROW EXECUTE FUNCTION fn_log_requisicao();

CREATE TRIGGER trg_log_inventario
AFTER INSERT OR UPDATE OR DELETE
ON tb_inventario
FOR EACH ROW EXECUTE FUNCTION fn_log_inventario();

CREATE TRIGGER trg_log_alerta
AFTER INSERT OR UPDATE OR DELETE
ON tb_alerta
FOR EACH ROW EXECUTE FUNCTION fn_log_alerta();