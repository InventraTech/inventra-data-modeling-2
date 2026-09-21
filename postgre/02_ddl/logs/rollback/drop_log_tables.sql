-- ---------------------------------------------------
-- ROLLBACK LOG TABLES
-- ---------------------------------------------------

DROP TABLE IF EXISTS tb_log_alert CASCADE;

DROP TABLE IF EXISTS tb_log_inventory CASCADE;

DROP TABLE IF EXISTS tb_log_requisition CASCADE;

DROP TABLE IF EXISTS tb_log_stock_batch CASCADE;

DROP TABLE IF EXISTS tb_log_supplier CASCADE;

DROP TABLE IF EXISTS tb_log_product CASCADE;

DROP TABLE IF EXISTS tb_log_user CASCADE;

DROP TABLE IF EXISTS tb_log_base CASCADE;

DROP SEQUENCE IF EXISTS seq_log_id;