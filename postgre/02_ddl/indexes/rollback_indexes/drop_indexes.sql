-- ---------------------------------------------------
-- ROLLBACK: DROP INDEXES
-- ---------------------------------------------------

DROP INDEX IF EXISTS idx_usuario_perfil;
DROP INDEX IF EXISTS idx_usuario_cozinha;
DROP INDEX IF EXISTS idx_usuario_email;
DROP INDEX IF EXISTS idx_usuario_ativo;

DROP INDEX IF EXISTS idx_produto_categoria;
DROP INDEX IF EXISTS idx_produto_unidade;
DROP INDEX IF EXISTS idx_produto_codigo_barras;
DROP INDEX IF EXISTS idx_produto_ativo;

DROP INDEX IF EXISTS idx_produtofornecedor_produto;
DROP INDEX IF EXISTS idx_produtofornecedor_fornecedor;

DROP INDEX IF EXISTS idx_parametro_produto;
DROP INDEX IF EXISTS idx_parametro_cozinha;

DROP INDEX IF EXISTS idx_lote_produto;
DROP INDEX IF EXISTS idx_lote_cozinha;
DROP INDEX IF EXISTS idx_lote_fornecedor;
DROP INDEX IF EXISTS idx_lote_status;
DROP INDEX IF EXISTS idx_lote_data_validade;

DROP INDEX IF EXISTS idx_requisicao_cozinha;
DROP INDEX IF EXISTS idx_requisicao_usuario_solicitante;
DROP INDEX IF EXISTS idx_requisicao_usuario_aprovador;
DROP INDEX IF EXISTS idx_requisicao_status;
DROP INDEX IF EXISTS idx_requisicao_data_hora;

DROP INDEX IF EXISTS idx_requisicaoitem_requisicao;
DROP INDEX IF EXISTS idx_requisicaoitem_produto;
DROP INDEX IF EXISTS idx_requisicaoitem_fornecedor;

DROP INDEX IF EXISTS idx_inventario_cozinha;
DROP INDEX IF EXISTS idx_inventario_usuario;
DROP INDEX IF EXISTS idx_inventario_status;

DROP INDEX IF EXISTS idx_contagem_inventario;
DROP INDEX IF EXISTS idx_contagem_lote;

DROP INDEX IF EXISTS idx_alerta_cozinha;
DROP INDEX IF EXISTS idx_alerta_produto;
DROP INDEX IF EXISTS idx_alerta_lote;
DROP INDEX IF EXISTS idx_alerta_lido;
DROP INDEX IF EXISTS idx_alerta_severidade;
DROP INDEX IF EXISTS idx_alerta_criado_em;