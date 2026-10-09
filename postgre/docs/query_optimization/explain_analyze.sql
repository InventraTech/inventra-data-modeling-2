-- ---------------------------------------------------
-- EXPLAIN ANALYZE CREATION
-- ---------------------------------------------------


DROP INDEX IF EXISTS idx_log_stock_batch_id_batch;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_log, operation, operation_date, previous_data, new_data
FROM tb_log_stock_batch
WHERE id_batch = (SELECT id_batch FROM tb_log_stock_batch GROUP BY id_batch ORDER BY count(*) DESC LIMIT 1);

CREATE INDEX idx_log_stock_batch_id_batch
ON tb_log_stock_batch (id_batch);

ANALYZE tb_log_stock_batch;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_log, operation, operation_date, previous_data, new_data
FROM tb_log_stock_batch
WHERE id_batch = (SELECT id_batch FROM tb_log_stock_batch GROUP BY id_batch ORDER BY count(*) DESC LIMIT 1);



EXPLAIN (ANALYZE, BUFFERS)
SELECT id_requisition, requisition_type, id_kitchen, reason, created_at
FROM tb_requisition
WHERE status = 'UNDER_REVIEW'
ORDER BY created_at DESC
LIMIT 20;

CREATE INDEX idx_requisition_status_created_at
ON tb_requisition (status, created_at DESC);

ANALYZE tb_requisition;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_requisition, requisition_type, id_kitchen, reason, created_at
FROM tb_requisition
WHERE status = 'UNDER_REVIEW'
ORDER BY created_at DESC
LIMIT 20;



EXPLAIN (ANALYZE, BUFFERS)
SELECT id_supplier, reference_price
FROM tb_product_supplier
WHERE id_product = (SELECT id_product FROM tb_product_supplier GROUP BY id_product ORDER BY count(*) DESC LIMIT 1)
ORDER BY reference_price ASC;

CREATE INDEX idx_productsupplier_product_price
ON tb_product_supplier (id_product, reference_price);

ANALYZE tb_product_supplier;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_supplier, reference_price
FROM tb_product_supplier
WHERE id_product = (SELECT id_product FROM tb_product_supplier GROUP BY id_product ORDER BY count(*) DESC LIMIT 1)
ORDER BY reference_price ASC;



DROP INDEX IF EXISTS idx_batch_kitchen_status_expiration;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_batch, batch_number, current_quantity, expiration_date
FROM tb_stock_batch
WHERE id_kitchen = (SELECT id_kitchen FROM tb_stock_batch WHERE status = 'ACTIVE' GROUP BY id_kitchen ORDER BY count(*) DESC LIMIT 1)
  AND status = 'ACTIVE'
  AND expiration_date <= CURRENT_DATE + 30;

CREATE INDEX idx_batch_kitchen_status_expiration
ON tb_stock_batch (id_kitchen, status, expiration_date);

ANALYZE tb_stock_batch;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_batch, batch_number, current_quantity, expiration_date
FROM tb_stock_batch
WHERE id_kitchen = (SELECT id_kitchen FROM tb_stock_batch WHERE status = 'ACTIVE' GROUP BY id_kitchen ORDER BY count(*) DESC LIMIT 1)
  AND status = 'ACTIVE'
  AND expiration_date <= CURRENT_DATE + 30;
