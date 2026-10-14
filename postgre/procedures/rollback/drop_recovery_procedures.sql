-- ---------------------------------------------------
-- RECOVERY PROCEDURES
-- ---------------------------------------------------

DROP PROCEDURE IF EXISTS sp_restore_from_audit(INTEGER);

DROP PROCEDURE IF EXISTS sp_register_backup(VARCHAR, VARCHAR, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ, BIGINT, VARCHAR, VARCHAR, VARCHAR);
