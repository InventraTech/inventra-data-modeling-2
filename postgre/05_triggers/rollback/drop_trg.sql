-- ===================================================
-- ROLLBACK: DROP TRIGGERS
-- ===================================================

DROP TRIGGER IF EXISTS trg_alerta_validade
ON tb_estoque_lote;

DROP TRIGGER IF EXISTS trg_alerta_estoque
ON tb_estoque_lote;

DROP TRIGGER IF EXISTS trg_aprovacao_requisicao
ON tb_requisicao;

DROP TRIGGER IF EXISTS trg_calcular_divergencia
ON tb_inventario_contagem;

DROP TRIGGER IF EXISTS trg_atualizar_status_lote
ON tb_estoque_lote;

DROP TRIGGER IF EXISTS trg_validar_estoque
ON tb_estoque_lote;