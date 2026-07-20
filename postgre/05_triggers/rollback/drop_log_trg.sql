-- ===================================================
-- ROLLBACK: DROP LOG TRIGGERS
-- ===================================================

DROP TABLE IF EXISTS trg_log_usuario ON tb_usuario;

DROP TABLE IF EXISTS trg_log_produto ON tb_produto;

DROP TABLE IF EXISTS trg_log_fornecedor ON tb_fornecedor;

DROP TABLE IF EXISTS trg_log_estoque_lote ON tb_log_estoque_lote;

DROP TABLE IF EXISTS trg_log_requisicao ON tb_requisicao;

DROP TABLE IF EXISTS trg_log_inventario ON tb_inventario;

DROP TABLE IF EXISTS trg_log_alerta ON tb_alerta;