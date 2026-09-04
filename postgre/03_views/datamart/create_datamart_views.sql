-- ---------------------------------------------------
-- DATA MART VIEWS — STAR SCHEMA
-- ---------------------------------------------------

CREATE VIEW dim_product AS
SELECT
    p.id_product,
    p.name AS product_name,
    p.brand AS product_brand,
    COALESCE(c.name, 'UNCATEGORIZED') AS category_name,
    mu.symbol AS unit_symbol,
    mu.description AS unit_description,
    p.barcode,
    p.active AS product_active
FROM tb_product p
LEFT JOIN tb_category c ON c.id_category = p.id_category
JOIN tb_measurement_unit mu ON mu.id_unit = p.id_unit;

CREATE VIEW dim_kitchen AS
SELECT
    k.id_kitchen,
    k.name AS kitchen_name,
    k.code AS kitchen_code,
    k.address AS kitchen_address,
    k.active AS kitchen_active
FROM tb_kitchen k;

CREATE VIEW dim_supplier AS
SELECT
    s.id_supplier,
    s.legal_name AS supplier_name,
    s.cnpj,
    s.rating,
    s.active AS supplier_active
FROM tb_supplier s;

CREATE VIEW dim_date AS
WITH calendar AS (
    SELECT generate_series(
        DATE '2023-01-01',
        DATE '2030-12-31',
        INTERVAL '1 day'
    )::DATE AS date_key
)
SELECT
    date_key,
    EXTRACT(YEAR FROM date_key)::INT AS year_number,
    EXTRACT(MONTH FROM date_key)::INT AS month_number,
    TRIM(TO_CHAR(date_key, 'Month')) AS month_name,
    EXTRACT(DAY FROM date_key)::INT AS day_number,
    EXTRACT(QUARTER FROM date_key)::INT AS quarter_number,
    EXTRACT(ISODOW FROM date_key)::INT AS day_of_week_number,
    TRIM(TO_CHAR(date_key, 'Day')) AS day_of_week_name,
    (EXTRACT(ISODOW FROM date_key) IN (6, 7)) AS is_weekend
FROM calendar;

CREATE VIEW fact_stock_movement AS
SELECT
    l.id_log,
    sb.id_product,
    sb.id_kitchen,
    sb.id_supplier,
    (l.operation_date)::DATE AS date_key,
    l.operation_date,
    CASE
        WHEN l.operation = 'INSERT' THEN 'ENTRY'
        WHEN l.operation = 'UPDATE'
             AND (l.new_data ->> 'current_quantity')::DECIMAL(12,3)
                 > (l.previous_data ->> 'current_quantity')::DECIMAL(12,3) THEN 'ENTRY'
        WHEN l.operation = 'UPDATE'
             AND (l.new_data ->> 'current_quantity')::DECIMAL(12,3)
                 < (l.previous_data ->> 'current_quantity')::DECIMAL(12,3) THEN 'WITHDRAWAL'
        ELSE 'NO_CHANGE'
    END AS movement_type,
    ABS(
        COALESCE((l.new_data ->> 'current_quantity')::DECIMAL(12,3), 0)
        - COALESCE((l.previous_data ->> 'current_quantity')::DECIMAL(12,3), 0)
    ) AS quantity_change,
    ABS(
        COALESCE((l.new_data ->> 'current_quantity')::DECIMAL(12,3), 0)
        - COALESCE((l.previous_data ->> 'current_quantity')::DECIMAL(12,3), 0)
    ) * COALESCE(sb.unit_price, 0) AS movement_value
FROM tb_log_stock_batch l
JOIN tb_stock_batch sb ON sb.id_batch = l.id_batch
WHERE l.operation IN ('INSERT', 'UPDATE');

CREATE VIEW fact_requisition_item AS
SELECT
    ri.id_requisition_item,
    ri.id_requisition,
    ri.id_product,
    r.id_kitchen,
    ri.id_suggested_supplier AS id_supplier,
    (r.created_at)::DATE AS date_key,
    r.created_at,
    r.status AS requisition_status,
    r.requisition_type,
    ri.quantity,
    ri.estimated_price,
    (ri.quantity * COALESCE(ri.estimated_price, 0)) AS estimated_value
FROM tb_requisition_item ri
JOIN tb_requisition r ON r.id_requisition = ri.id_requisition;

CREATE VIEW fact_inventory_count AS
SELECT
    ic.id_count,
    ic.id_inventory,
    inv.id_kitchen,
    sb.id_product,
    (inv.started_at)::DATE AS date_key,
    inv.started_at,
    inv.closed_at,
    ic.registered_quantity,
    ic.physical_quantity,
    ic.divergence
FROM tb_inventory_count ic
JOIN tb_inventory inv ON inv.id_inventory = ic.id_inventory
JOIN tb_stock_batch sb ON sb.id_batch = ic.id_batch;
