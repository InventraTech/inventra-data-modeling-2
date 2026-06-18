-- ---------------------------------------------------
-- ROLLBACK: DROP CONSTRAINTS
-- ---------------------------------------------------

-- Drop foreign keys
ALTER TABLE tb_alerta DROP CONSTRAINT IF EXISTS fk_alerta_cozinha;
ALTER TABLE tb_alerta DROP CONSTRAINT IF EXISTS fk_alerta_produto;
ALTER TABLE tb_alerta DROP CONSTRAINT IF EXISTS fk_alerta_lote;

ALTER TABLE tb_inventario_contagem DROP CONSTRAINT IF EXISTS fk_contagem_inventario;
ALTER TABLE tb_inventario_contagem DROP CONSTRAINT IF EXISTS fk_contagem_lote;

ALTER TABLE tb_inventario DROP CONSTRAINT IF EXISTS fk_inventario_cozinha;
ALTER TABLE tb_inventario DROP CONSTRAINT IF EXISTS fk_inventario_usuario;

ALTER TABLE tb_requisicao_item DROP CONSTRAINT IF EXISTS fk_requisicaoitem_requisicao;
ALTER TABLE tb_requisicao_item DROP CONSTRAINT IF EXISTS fk_requisicaoitem_produto;
ALTER TABLE tb_requisicao_item DROP CONSTRAINT IF EXISTS fk_requisicaoitem_fornecedor;

ALTER TABLE tb_requisicao DROP CONSTRAINT IF EXISTS fk_requisicao_cozinha;
ALTER TABLE tb_requisicao DROP CONSTRAINT IF EXISTS fk_requisicao_usuario_solicitante;
ALTER TABLE tb_requisicao DROP CONSTRAINT IF EXISTS fk_requisicao_usuario_aprovador;

ALTER TABLE tb_estoque_lote DROP CONSTRAINT IF EXISTS fk_lote_produto;
ALTER TABLE tb_estoque_lote DROP CONSTRAINT IF EXISTS fk_lote_cozinha;
ALTER TABLE tb_estoque_lote DROP CONSTRAINT IF EXISTS fk_lote_fornecedor;

ALTER TABLE tb_produto_parametro_cozinha DROP CONSTRAINT IF EXISTS fk_parametro_produto;
ALTER TABLE tb_produto_parametro_cozinha DROP CONSTRAINT IF EXISTS fk_parametro_cozinha;

ALTER TABLE tb_produto_fornecedor DROP CONSTRAINT IF EXISTS fk_produtofornecedor_produto;
ALTER TABLE tb_produto_fornecedor DROP CONSTRAINT IF EXISTS fk_produtofornecedor_fornecedor;

ALTER TABLE tb_produto DROP CONSTRAINT IF EXISTS fk_produto_categoria;
ALTER TABLE tb_produto DROP CONSTRAINT IF EXISTS fk_produto_unidade;

ALTER TABLE tb_usuario DROP CONSTRAINT IF EXISTS fk_usuario_perfil;
ALTER TABLE tb_usuario DROP CONSTRAINT IF EXISTS fk_usuario_cozinha;

-- Drop check constraints
ALTER TABLE tb_fornecedor DROP CONSTRAINT IF EXISTS ck_fornecedor_nota;
ALTER TABLE tb_estoque_lote DROP CONSTRAINT IF EXISTS ck_lote_status;
ALTER TABLE tb_requisicao DROP CONSTRAINT IF EXISTS ck_requisicao_status;
ALTER TABLE tb_requisicao DROP CONSTRAINT IF EXISTS ck_requisicao_tipo;
ALTER TABLE tb_inventario DROP CONSTRAINT IF EXISTS ck_inventario_status;
ALTER TABLE tb_alerta DROP CONSTRAINT IF EXISTS ck_alerta_severidade;