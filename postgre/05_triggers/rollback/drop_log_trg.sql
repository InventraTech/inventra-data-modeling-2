-- ---------------------------------------------------
-- ROLLBACK DE TRIGGERS DE LOG
-- ---------------------------------------------------

DROP TRIGGER IF EXISTS trg_log_usuario 
ON tb_usuario;

DROP TRIGGER IF EXISTS trg_log_produto 
ON tb_produto;

DROP TRIGGER IF EXISTS trg_log_fornecedor 
ON tb_fornecedor;

DROP TRIGGER IF EXISTS trg_log_estoque_lote 
ON tb_log_estoque_lote;

DROP TRIGGER IF EXISTS trg_log_requisicao 
ON tb_requisicao;

DROP TRIGGER IF EXISTS trg_log_inventario 
ON tb_inventario;

DROP TRIGGER IF EXISTS trg_log_alerta 
ON tb_alerta;