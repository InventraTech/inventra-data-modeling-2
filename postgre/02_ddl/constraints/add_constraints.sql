-- ---------------------------------------------------
-- CHAVES ESTRANGEIRAS
-- ---------------------------------------------------

ALTER TABLE tb_usuario
ADD CONSTRAINT fk_usuario_perfil
FOREIGN KEY (id_perfil) REFERENCES tb_perfil (id_perfil)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_usuario
ADD CONSTRAINT fk_usuario_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto
ADD CONSTRAINT fk_produto_categoria
FOREIGN KEY (id_categoria) REFERENCES tb_categoria (id_categoria)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto
ADD CONSTRAINT fk_produto_unidade
FOREIGN KEY (id_unidade) REFERENCES tb_unidade_medida (id_unidade)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto_fornecedor
ADD CONSTRAINT fk_produtofornecedor_produto
FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto_fornecedor
ADD CONSTRAINT fk_produtofornecedor_fornecedor
FOREIGN KEY (id_fornecedor) REFERENCES tb_fornecedor (id_fornecedor)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto_parametro_cozinha
ADD CONSTRAINT fk_parametro_produto
FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_produto_parametro_cozinha
ADD CONSTRAINT fk_parametro_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_estoque_lote
ADD CONSTRAINT fk_lote_produto
FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_estoque_lote
ADD CONSTRAINT fk_lote_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_estoque_lote
ADD CONSTRAINT fk_lote_fornecedor
FOREIGN KEY (id_fornecedor) REFERENCES tb_fornecedor (id_fornecedor)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao
ADD CONSTRAINT fk_requisicao_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao
ADD CONSTRAINT fk_requisicao_usuario_solicitante
FOREIGN KEY (id_usuario_requisicao) REFERENCES tb_usuario (id_usuario)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao
ADD CONSTRAINT fk_requisicao_usuario_aprovador
FOREIGN KEY (id_usuario_aprovador) REFERENCES tb_usuario (id_usuario)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao_item
ADD CONSTRAINT fk_requisicaoitem_requisicao
FOREIGN KEY (id_requisicao) REFERENCES tb_requisicao (id_requisicao)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao_item
ADD CONSTRAINT fk_requisicaoitem_produto
FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisicao_item
ADD CONSTRAINT fk_requisicaoitem_fornecedor
FOREIGN KEY (id_fornecedor_sugerido) REFERENCES tb_fornecedor (id_fornecedor)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventario
ADD CONSTRAINT fk_inventario_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventario
ADD CONSTRAINT fk_inventario_usuario
FOREIGN KEY (id_usuario_responsavel) REFERENCES tb_usuario (id_usuario)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventario_contagem
ADD CONSTRAINT fk_contagem_inventario
FOREIGN KEY (id_inventario) REFERENCES tb_inventario (id_inventario)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventario_contagem
ADD CONSTRAINT fk_contagem_lote
FOREIGN KEY (id_lote) REFERENCES tb_estoque_lote (id_lote)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alerta
ADD CONSTRAINT fk_alerta_cozinha
FOREIGN KEY (id_cozinha) REFERENCES tb_cozinha (id_cozinha)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alerta
ADD CONSTRAINT fk_alerta_produto
FOREIGN KEY (id_produto) REFERENCES tb_produto (id_produto)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alerta
ADD CONSTRAINT fk_alerta_lote
FOREIGN KEY (id_lote) REFERENCES tb_estoque_lote (id_lote)
ON UPDATE NO ACTION ON DELETE NO ACTION;

-- ---------------------------------------------------
-- CONSTRAINTS DE CHECK (REGRAS DE NEGÓCIO)
-- ---------------------------------------------------

ALTER TABLE tb_fornecedor
ADD CONSTRAINT ck_fornecedor_nota 
CHECK (nota_avaliacao BETWEEN 1 AND 5);

ALTER TABLE tb_estoque_lote
ADD CONSTRAINT ck_lote_status 
CHECK (status IN ('ATIVO', 'BAIXA', 'VENCIDO', 'CANCELADO'));

ALTER TABLE tb_requisicao
ADD CONSTRAINT ck_requisicao_status 
CHECK (status IN ('EM_ANALISE', 'APROVADO', 'REPROVADO', 'CANCELADO'));

ALTER TABLE tb_requisicao
ADD CONSTRAINT ck_requisicao_tipo 
CHECK (tipo_requisicao IN ('COMPRA', 'TRANSFERENCIA', 'CONSUMO'));

ALTER TABLE tb_inventario
ADD CONSTRAINT ck_inventario_status 
CHECK (status IN ('ABERTO', 'FECHADO', 'CANCELADO'));

ALTER TABLE tb_alerta
ADD CONSTRAINT ck_alerta_severidade 
CHECK (severidade IN ('BAIXA', 'MEDIA', 'ALTA', 'CRITICA'));