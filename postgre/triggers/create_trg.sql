-- ---------------------------------------------------
-- TRIGGER CREATION
-- ---------------------------------------------------

CREATE TRIGGER trg_validate_stock
BEFORE INSERT OR UPDATE OF current_quantity
ON tb_stock_batch
FOR EACH ROW
EXECUTE FUNCTION fn_validate_stock();

CREATE TRIGGER trg_update_batch_status
BEFORE INSERT OR UPDATE OF current_quantity, status
ON tb_stock_batch
FOR EACH ROW
EXECUTE FUNCTION fn_update_batch_status();

CREATE TRIGGER trg_calculate_divergence
BEFORE INSERT OR UPDATE OF registered_quantity, physical_quantity
ON tb_inventory_count
FOR EACH ROW
EXECUTE FUNCTION fn_calculate_divergence();

CREATE TRIGGER trg_requisition_approval
BEFORE UPDATE OF status
ON tb_requisition
FOR EACH ROW
EXECUTE FUNCTION fn_requisition_approval();

CREATE TRIGGER trg_stock_alert
AFTER INSERT OR UPDATE OF current_quantity
ON tb_stock_batch
FOR EACH ROW
EXECUTE FUNCTION fn_stock_alert();

CREATE TRIGGER trg_expiration_alert
AFTER INSERT OR UPDATE OF expiration_date
ON tb_stock_batch
FOR EACH ROW
EXECUTE FUNCTION fn_expiration_alert();