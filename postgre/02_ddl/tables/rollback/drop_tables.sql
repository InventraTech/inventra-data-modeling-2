-- ---------------------------------------------------
-- ROLLBACK DAS TABELAS
-- ---------------------------------------------------

DROP TABLE IF EXISTS tb_usuario CASCADE;

DROP TABLE IF EXISTS tb_perfil CASCADE;

DROP TABLE IF EXISTS tb_cozinha CASCADE;

DROP TABLE IF EXISTS tb_produto CASCADE;

DROP TABLE IF EXISTS tb_categoria CASCADE;

DROP TABLE IF EXISTS tb_unidade_medida CASCADE;

DROP TABLE IF EXISTS tb_produto_fornecedor CASCADE;

DROP TABLE IF EXISTS tb_fornecedor CASCADE;

DROP TABLE IF EXISTS tb_produto_parametro_cozinha CASCADE;

DROP TABLE IF EXISTS tb_estoque_lote CASCADE;

DROP TABLE IF EXISTS tb_requisicao CASCADE;

DROP TABLE IF EXISTS tb_requisicao_item CASCADE;

DROP TABLE IF EXISTS tb_inventario CASCADE;

DROP TABLE IF EXISTS tb_inventario_contagem CASCADE;

DROP TABLE IF EXISTS tb_alerta CASCADE;