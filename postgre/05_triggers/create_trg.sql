-- ===================================================
-- TRIGGERS
-- ===================================================

CREATE TRIGGER trg_validar_estoque
BEFORE INSERT OR UPDATE OF qtd_atual
ON tb_estoque_lote
FOR EACH ROW
EXECUTE FUNCTION fn_validar_estoque();

CREATE TRIGGER trg_atualizar_status_lote
BEFORE INSERT OR UPDATE OF qtd_atual, status
ON tb_estoque_lote
FOR EACH ROW
EXECUTE FUNCTION fn_atualizar_status_lote();

CREATE TRIGGER trg_calcular_divergencia
BEFORE INSERT OR UPDATE OF qtd_registrada, qtd_fisica
ON tb_inventario_contagem
FOR EACH ROW
EXECUTE FUNCTION fn_calcular_divergencia();

CREATE TRIGGER trg_aprovacao_requisicao
BEFORE UPDATE OF status
ON tb_requisicao
FOR EACH ROW
EXECUTE FUNCTION fn_aprovacao_requisicao();

CREATE TRIGGER trg_alerta_estoque
AFTER INSERT OR UPDATE OF qtd_atual
ON tb_estoque_lote
FOR EACH ROW
EXECUTE FUNCTION fn_alerta_estoque();

CREATE TRIGGER trg_alerta_validade
AFTER INSERT OR UPDATE OF data_validade
ON tb_estoque_lote
FOR EACH ROW
EXECUTE FUNCTION fn_alerta_validade();