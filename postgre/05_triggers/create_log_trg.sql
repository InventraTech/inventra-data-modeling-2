-- ---------------------------------------------------
-- LOG TRIGGER CREATION
-- ---------------------------------------------------

CREATE TRIGGER trg_log_user
AFTER INSERT OR UPDATE OR DELETE
ON tb_user
FOR EACH ROW EXECUTE FUNCTION fn_log_user();

CREATE TRIGGER trg_log_product
AFTER INSERT OR UPDATE OR DELETE
ON tb_product
FOR EACH ROW EXECUTE FUNCTION fn_log_product();

CREATE TRIGGER trg_log_supplier
AFTER INSERT OR UPDATE OR DELETE
ON tb_supplier
FOR EACH ROW EXECUTE FUNCTION fn_log_supplier();

CREATE TRIGGER trg_log_stock_batch
AFTER INSERT OR UPDATE OR DELETE
ON tb_stock_batch
FOR EACH ROW EXECUTE FUNCTION fn_log_stock_batch();

CREATE TRIGGER trg_log_requisition
AFTER INSERT OR UPDATE OR DELETE
ON tb_requisition
FOR EACH ROW EXECUTE FUNCTION fn_log_requisition();

CREATE TRIGGER trg_log_inventory
AFTER INSERT OR UPDATE OR DELETE
ON tb_inventory
FOR EACH ROW EXECUTE FUNCTION fn_log_inventory();

CREATE TRIGGER trg_log_alert
AFTER INSERT OR UPDATE OR DELETE
ON tb_alert
FOR EACH ROW EXECUTE FUNCTION fn_log_alert();