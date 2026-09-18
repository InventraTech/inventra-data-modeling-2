-- ---------------------------------------------------
-- LOG TABLE CREATION
-- ---------------------------------------------------

CREATE SEQUENCE seq_log_id;

CREATE TABLE tb_log_base (
    id_log INTEGER NOT NULL DEFAULT nextval('seq_log_id'),
    operation VARCHAR(10) NOT NULL,
    db_user VARCHAR(100) NOT NULL,
    operation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    previous_data JSONB,
    new_data JSONB,
    PRIMARY KEY (id_log)
);

CREATE TABLE tb_log_user (
    id_user UUID
) INHERITS (tb_log_base);

CREATE TABLE tb_log_product (
    id_product INTEGER
) INHERITS (tb_log_base);

CREATE TABLE tb_log_supplier (
    id_supplier INTEGER
) INHERITS (tb_log_base);

CREATE TABLE tb_log_stock_batch (
    id_batch INTEGER
) INHERITS (tb_log_base);

CREATE TABLE tb_log_requisition (
    id_requisition INTEGER
) INHERITS (tb_log_base);

CREATE TABLE tb_log_inventory (
    id_inventory INTEGER
) INHERITS (tb_log_base);

CREATE TABLE tb_log_alert (
    id_alert INTEGER
) INHERITS (tb_log_base);
