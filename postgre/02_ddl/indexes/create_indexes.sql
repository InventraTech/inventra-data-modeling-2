-- ---------------------------------------------------
-- CRIAÇÃO DE ÍNDICES
-- ---------------------------------------------------

CREATE INDEX idx_usuario_perfil 
ON tb_usuario (id_perfil);

CREATE INDEX idx_usuario_cozinha 
ON tb_usuario (id_cozinha);

CREATE INDEX idx_usuario_email 
ON tb_usuario (email);

CREATE INDEX idx_usuario_ativo 
ON tb_usuario (ativo);

CREATE INDEX idx_produto_categoria 
ON tb_produto (id_categoria);

CREATE INDEX idx_produto_unidade 
ON tb_produto (id_unidade);

CREATE INDEX idx_produto_codigo_barras
ON tb_produto (codigo_barras);

CREATE INDEX idx_produto_ativo 
ON tb_produto (ativo);

CREATE INDEX idx_produtofornecedor_produto 
ON tb_produto_fornecedor (id_produto);

CREATE INDEX idx_produtofornecedor_fornecedor 
ON tb_produto_fornecedor (id_fornecedor);

CREATE INDEX idx_parametro_produto 
ON tb_produto_parametro_cozinha (id_produto);

CREATE INDEX idx_parametro_cozinha 
ON tb_produto_parametro_cozinha (id_cozinha);

CREATE INDEX idx_lote_produto 
ON tb_estoque_lote (id_produto);

CREATE INDEX idx_lote_cozinha 
ON tb_estoque_lote (id_cozinha);

CREATE INDEX idx_lote_fornecedor 
ON tb_estoque_lote (id_fornecedor);

CREATE INDEX idx_lote_status 
ON tb_estoque_lote (status);

CREATE INDEX idx_lote_data_validade 
ON tb_estoque_lote (data_validade);

CREATE INDEX idx_requisicao_cozinha 
ON tb_requisicao (id_cozinha);

CREATE INDEX idx_requisicao_usuario_solicitante 
ON tb_requisicao (id_usuario_requisicao);

CREATE INDEX idx_requisicao_usuario_aprovador 
ON tb_requisicao (id_usuario_aprovador);

CREATE INDEX idx_requisicao_status 
ON tb_requisicao (status);

CREATE INDEX idx_requisicao_data_hora 
ON tb_requisicao (data_hora);

CREATE INDEX idx_requisicaoitem_requisicao 
ON tb_requisicao_item (id_requisicao);

CREATE INDEX idx_requisicaoitem_produto 
ON tb_requisicao_item (id_produto);

CREATE INDEX idx_requisicaoitem_fornecedor 
ON tb_requisicao_item (id_fornecedor_sugerido);

CREATE INDEX idx_inventario_cozinha 
ON tb_inventario (id_cozinha);

CREATE INDEX idx_inventario_usuario 
ON tb_inventario (id_usuario_responsavel);

CREATE INDEX idx_inventario_status 
ON tb_inventario (status);

CREATE INDEX idx_contagem_inventario 
ON tb_inventario_contagem (id_inventario);

CREATE INDEX idx_contagem_lote 
ON tb_inventario_contagem (id_lote);

CREATE INDEX idx_alerta_cozinha 
ON tb_alerta (id_cozinha);

CREATE INDEX idx_alerta_produto 
ON tb_alerta (id_produto);

CREATE INDEX idx_alerta_lote 
ON tb_alerta (id_lote);

CREATE INDEX idx_alerta_lido 
ON tb_alerta (lido);

CREATE INDEX idx_alerta_severidade 
ON tb_alerta (severidade);

CREATE INDEX idx_alerta_criado_em 
ON tb_alerta (criado_em);