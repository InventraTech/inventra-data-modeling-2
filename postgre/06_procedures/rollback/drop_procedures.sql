-- ---------------------------------------------------
-- ROLLBACK DE PROCEDURES
-- ---------------------------------------------------

DROP PROCEDURE IF EXISTS sp_fechar_inventario(INTEGER);

DROP PROCEDURE IF EXISTS sp_baixar_estoque(INTEGER, DECIMAL);

DROP PROCEDURE IF EXISTS sp_registrar_entrada_estoque(INTEGER, DECIMAL);

DROP PROCEDURE IF EXISTS sp_cancelar_requisicao(INTEGER, VARCHAR);

DROP PROCEDURE IF EXISTS sp_reprovar_requisicao(INTEGER, UUID, VARCHAR);

DROP PROCEDURE IF EXISTS sp_aprovar_requisicao(INTEGER, UUID);