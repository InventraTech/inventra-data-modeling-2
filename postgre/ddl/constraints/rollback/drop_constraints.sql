-- ---------------------------------------------------
-- ROLLBACK FOREIGN KEYS
-- ---------------------------------------------------

ALTER TABLE tb_user
DROP CONSTRAINT IF EXISTS fk_user_profile;

ALTER TABLE tb_user
DROP CONSTRAINT IF EXISTS fk_user_kitchen;

ALTER TABLE tb_product
DROP CONSTRAINT IF EXISTS fk_product_category;

ALTER TABLE tb_product
DROP CONSTRAINT IF EXISTS fk_product_unit;

ALTER TABLE tb_product_supplier
DROP CONSTRAINT IF EXISTS fk_productsupplier_product;

ALTER TABLE tb_product_supplier
DROP CONSTRAINT IF EXISTS fk_productsupplier_supplier;

ALTER TABLE tb_product_kitchen_parameter
DROP CONSTRAINT IF EXISTS fk_parameter_product;

ALTER TABLE tb_product_kitchen_parameter
DROP CONSTRAINT IF EXISTS fk_parameter_kitchen;

ALTER TABLE tb_stock_batch
DROP CONSTRAINT IF EXISTS fk_batch_product;

ALTER TABLE tb_stock_batch
DROP CONSTRAINT IF EXISTS fk_batch_kitchen;

ALTER TABLE tb_stock_batch
DROP CONSTRAINT IF EXISTS fk_batch_supplier;

ALTER TABLE tb_requisition
DROP CONSTRAINT IF EXISTS fk_requisition_kitchen;

ALTER TABLE tb_requisition
DROP CONSTRAINT IF EXISTS fk_requisition_requester_user;

ALTER TABLE tb_requisition
DROP CONSTRAINT IF EXISTS fk_requisition_approver_user;

ALTER TABLE tb_requisition_item
DROP CONSTRAINT IF EXISTS fk_requisitionitem_requisition;

ALTER TABLE tb_requisition_item
DROP CONSTRAINT IF EXISTS fk_requisitionitem_product;

ALTER TABLE tb_requisition_item
DROP CONSTRAINT IF EXISTS fk_requisitionitem_supplier;

ALTER TABLE tb_inventory
DROP CONSTRAINT IF EXISTS fk_inventory_kitchen;

ALTER TABLE tb_inventory
DROP CONSTRAINT IF EXISTS fk_inventory_user;

ALTER TABLE tb_inventory_count
DROP CONSTRAINT IF EXISTS fk_count_inventory;

ALTER TABLE tb_inventory_count
DROP CONSTRAINT IF EXISTS fk_count_batch;

ALTER TABLE tb_alert
DROP CONSTRAINT IF EXISTS fk_alert_kitchen;

ALTER TABLE tb_alert
DROP CONSTRAINT IF EXISTS fk_alert_product;

ALTER TABLE tb_alert
DROP CONSTRAINT IF EXISTS fk_alert_batch;

-- ---------------------------------------------------
-- ROLLBACK DE CONSTRAINTS DE CHECK 
-- ---------------------------------------------------

ALTER TABLE tb_supplier
DROP CONSTRAINT IF EXISTS ck_supplier_rating;

ALTER TABLE tb_stock_batch
DROP CONSTRAINT IF EXISTS ck_batch_status;

ALTER TABLE tb_requisition
DROP CONSTRAINT IF EXISTS ck_requisition_status;

ALTER TABLE tb_requisition
DROP CONSTRAINT IF EXISTS ck_requisition_type;

ALTER TABLE tb_inventory
DROP CONSTRAINT IF EXISTS ck_inventory_status;

ALTER TABLE tb_alert
DROP CONSTRAINT IF EXISTS ck_alert_severity;