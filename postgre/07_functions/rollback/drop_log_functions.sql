-- ---------------------------------------------------
-- ROLLBACK DE FUNCTIONS DE LOG
-- ---------------------------------------------------

DROP FUNCTION IF EXISTS fn_log_user();

DROP FUNCTION IF EXISTS fn_log_product();

DROP FUNCTION IF EXISTS fn_log_supplier();

DROP FUNCTION IF EXISTS fn_log_stock_batch();

DROP FUNCTION IF EXISTS fn_log_requisition();

DROP FUNCTION IF EXISTS fn_log_inventory();

DROP FUNCTION IF EXISTS fn_log_alert();
