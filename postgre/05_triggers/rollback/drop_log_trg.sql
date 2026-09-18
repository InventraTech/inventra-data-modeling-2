-- ---------------------------------------------------
-- ROLLBACK LOG TRIGGERS
-- ---------------------------------------------------

DROP TRIGGER IF EXISTS trg_log_user 
ON tb_user;

DROP TRIGGER IF EXISTS trg_log_product 
ON tb_product;

DROP TRIGGER IF EXISTS trg_log_supplier 
ON tb_supplier;

DROP TRIGGER IF EXISTS trg_log_stock_batch
ON tb_stock_batch;

DROP TRIGGER IF EXISTS trg_log_requisition 
ON tb_requisition;

DROP TRIGGER IF EXISTS trg_log_inventory 
ON tb_inventory;

DROP TRIGGER IF EXISTS trg_log_alert 
ON tb_alert;