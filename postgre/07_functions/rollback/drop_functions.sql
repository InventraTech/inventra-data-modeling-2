-- ---------------------------------------------------
-- ROLLBACK FUNCTIONS
-- ---------------------------------------------------
DROP FUNCTION IF EXISTS fn_expiration_alert();

DROP FUNCTION IF EXISTS fn_stock_alert();

DROP FUNCTION IF EXISTS fn_requisition_approval();

DROP FUNCTION IF EXISTS fn_calculate_divergence();

DROP FUNCTION IF EXISTS fn_update_batch_status();

DROP FUNCTION IF EXISTS fn_validate_stock();