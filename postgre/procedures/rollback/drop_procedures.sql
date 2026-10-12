-- ---------------------------------------------------
-- ROLLBACK PROCEDURES
-- ---------------------------------------------------

DROP PROCEDURE IF EXISTS sp_alert_expiring_batches(INTEGER);

DROP PROCEDURE IF EXISTS sp_expire_batches();

DROP PROCEDURE IF EXISTS sp_close_inventory(INTEGER);

DROP PROCEDURE IF EXISTS sp_write_off_stock(INTEGER, DECIMAL, UUID, VARCHAR, INTEGER);

DROP PROCEDURE IF EXISTS sp_register_stock_entry(INTEGER, DECIMAL, UUID);

DROP PROCEDURE IF EXISTS sp_cancel_requisition(INTEGER, VARCHAR, UUID);

DROP PROCEDURE IF EXISTS sp_reject_requisition(INTEGER, UUID, VARCHAR);

DROP PROCEDURE IF EXISTS sp_approve_requisition(INTEGER, UUID);
