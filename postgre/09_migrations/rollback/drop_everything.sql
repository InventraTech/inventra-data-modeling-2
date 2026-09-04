-- =====================================================
-- FULL TEARDOWN — reverses V001 + V002 + V003 + V004
-- =====================================================

-- ---------------------------------------------------
-- DATA MART VIEWS (STAR SCHEMA)
-- ---------------------------------------------------

DROP VIEW IF EXISTS fact_inventory_count;

DROP VIEW IF EXISTS fact_requisition_item;

DROP VIEW IF EXISTS fact_stock_movement;

DROP VIEW IF EXISTS dim_date;

DROP VIEW IF EXISTS dim_supplier;

DROP VIEW IF EXISTS dim_kitchen;

DROP VIEW IF EXISTS dim_product;

-- ---------------------------------------------------
-- VIEWS
-- ---------------------------------------------------

DROP VIEW IF EXISTS vw_monthly_waste_proxy_kpi;

DROP VIEW IF EXISTS vw_supplier_profile;

DROP VIEW IF EXISTS vw_batches_needing_attention;

DROP VIEW IF EXISTS vw_products_below_minimum;

DROP VIEW IF EXISTS vw_requisition_pending;

DROP VIEW IF EXISTS vw_stock_movement_log;

DROP VIEW IF EXISTS vw_requisition_summary;

DROP VIEW IF EXISTS vw_stock_value_by_category;

DROP VIEW IF EXISTS vw_active_alerts;

DROP VIEW IF EXISTS vw_daily_expiration_summary;

DROP VIEW IF EXISTS vw_product_stock_position;

DROP VIEW IF EXISTS vw_stock_batch_detail;

DROP VIEW IF EXISTS vw_kitchen_dashboard_kpi;

DROP VIEW IF EXISTS vw_product_supplier_catalog;

DROP VIEW IF EXISTS vw_product_requisition_ranking;

DROP VIEW IF EXISTS vw_kitchen_daily_stock_movement;

DROP VIEW IF EXISTS vw_inventory_count_divergence;

-- ---------------------------------------------------
-- LOG TRIGGERS
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

-- ---------------------------------------------------
-- BUSINESS TRIGGERS
-- ---------------------------------------------------

DROP TRIGGER IF EXISTS trg_expiration_alert
ON tb_stock_batch;

DROP TRIGGER IF EXISTS trg_stock_alert
ON tb_stock_batch;

DROP TRIGGER IF EXISTS trg_requisition_approval
ON tb_requisition;

DROP TRIGGER IF EXISTS trg_calculate_divergence
ON tb_inventory_count;

DROP TRIGGER IF EXISTS trg_update_batch_status
ON tb_stock_batch;

DROP TRIGGER IF EXISTS trg_validate_stock
ON tb_stock_batch;

-- ---------------------------------------------------
-- LOG FUNCTIONS
-- ---------------------------------------------------

DROP FUNCTION IF EXISTS fn_log_user();

DROP FUNCTION IF EXISTS fn_log_product();

DROP FUNCTION IF EXISTS fn_log_supplier();

DROP FUNCTION IF EXISTS fn_log_stock_batch();

DROP FUNCTION IF EXISTS fn_log_requisition();

DROP FUNCTION IF EXISTS fn_log_inventory();

DROP FUNCTION IF EXISTS fn_log_alert();

-- ---------------------------------------------------
-- BUSINESS FUNCTIONS
-- ---------------------------------------------------

DROP FUNCTION IF EXISTS fn_expiration_alert();

DROP FUNCTION IF EXISTS fn_stock_alert();

DROP FUNCTION IF EXISTS fn_requisition_approval();

DROP FUNCTION IF EXISTS fn_calculate_divergence();

DROP FUNCTION IF EXISTS fn_update_batch_status();

DROP FUNCTION IF EXISTS fn_validate_stock();

-- ---------------------------------------------------
-- PROCEDURES
-- ---------------------------------------------------

DROP PROCEDURE IF EXISTS sp_close_inventory(INTEGER);

DROP PROCEDURE IF EXISTS sp_write_off_stock(INTEGER, DECIMAL);

DROP PROCEDURE IF EXISTS sp_register_stock_entry(INTEGER, DECIMAL);

DROP PROCEDURE IF EXISTS sp_cancel_requisition(INTEGER, VARCHAR);

DROP PROCEDURE IF EXISTS sp_reject_requisition(INTEGER, UUID, VARCHAR);

DROP PROCEDURE IF EXISTS sp_approve_requisition(INTEGER, UUID);

-- ---------------------------------------------------
-- FOREIGN KEYS
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
-- CHECK CONSTRAINTS
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

-- ---------------------------------------------------
-- INDEXES
-- ---------------------------------------------------

DROP INDEX IF EXISTS idx_user_profile;
DROP INDEX IF EXISTS idx_user_kitchen;
DROP INDEX IF EXISTS idx_user_email;
DROP INDEX IF EXISTS idx_user_active;
DROP INDEX IF EXISTS idx_product_category;
DROP INDEX IF EXISTS idx_product_unit;
DROP INDEX IF EXISTS idx_product_barcode;
DROP INDEX IF EXISTS idx_product_active;
DROP INDEX IF EXISTS idx_productsupplier_product;
DROP INDEX IF EXISTS idx_productsupplier_supplier;
DROP INDEX IF EXISTS idx_parameter_product;
DROP INDEX IF EXISTS idx_parameter_kitchen;
DROP INDEX IF EXISTS idx_batch_product;
DROP INDEX IF EXISTS idx_batch_kitchen;
DROP INDEX IF EXISTS idx_batch_supplier;
DROP INDEX IF EXISTS idx_batch_status;
DROP INDEX IF EXISTS idx_batch_expiration_date;
DROP INDEX IF EXISTS idx_requisition_kitchen;
DROP INDEX IF EXISTS idx_requisition_requester_user;
DROP INDEX IF EXISTS idx_requisition_approver_user;
DROP INDEX IF EXISTS idx_requisition_status;
DROP INDEX IF EXISTS idx_requisition_created_at;
DROP INDEX IF EXISTS idx_requisitionitem_requisition;
DROP INDEX IF EXISTS idx_requisitionitem_product;
DROP INDEX IF EXISTS idx_requisitionitem_supplier;
DROP INDEX IF EXISTS idx_inventory_kitchen;
DROP INDEX IF EXISTS idx_inventory_user;
DROP INDEX IF EXISTS idx_inventory_status;
DROP INDEX IF EXISTS idx_count_inventory;
DROP INDEX IF EXISTS idx_count_batch;
DROP INDEX IF EXISTS idx_alert_kitchen;
DROP INDEX IF EXISTS idx_alert_product;
DROP INDEX IF EXISTS idx_alert_batch;
DROP INDEX IF EXISTS idx_alert_is_read;
DROP INDEX IF EXISTS idx_alert_severity;
DROP INDEX IF EXISTS idx_alert_created_at;

-- ---------------------------------------------------
-- LOG TABLES
-- ---------------------------------------------------

DROP TABLE IF EXISTS tb_log_alert;
DROP TABLE IF EXISTS tb_log_inventory;
DROP TABLE IF EXISTS tb_log_requisition;
DROP TABLE IF EXISTS tb_log_stock_batch;
DROP TABLE IF EXISTS tb_log_supplier;
DROP TABLE IF EXISTS tb_log_product;
DROP TABLE IF EXISTS tb_log_user;

-- ---------------------------------------------------
-- TABLES
-- ---------------------------------------------------

DROP TABLE IF EXISTS tb_user CASCADE;
DROP TABLE IF EXISTS tb_profile CASCADE;
DROP TABLE IF EXISTS tb_kitchen CASCADE;
DROP TABLE IF EXISTS tb_product CASCADE;
DROP TABLE IF EXISTS tb_category CASCADE;
DROP TABLE IF EXISTS tb_measurement_unit CASCADE;
DROP TABLE IF EXISTS tb_product_supplier CASCADE;
DROP TABLE IF EXISTS tb_supplier CASCADE;
DROP TABLE IF EXISTS tb_product_kitchen_parameter CASCADE;
DROP TABLE IF EXISTS tb_stock_batch CASCADE;
DROP TABLE IF EXISTS tb_requisition CASCADE;
DROP TABLE IF EXISTS tb_requisition_item CASCADE;
DROP TABLE IF EXISTS tb_inventory CASCADE;
DROP TABLE IF EXISTS tb_inventory_count CASCADE;
DROP TABLE IF EXISTS tb_alert CASCADE;
