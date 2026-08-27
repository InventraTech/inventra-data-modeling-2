-- ---------------------------------------------------
-- FOREIGN KEYS
-- ---------------------------------------------------

ALTER TABLE tb_user
ADD CONSTRAINT fk_user_profile
FOREIGN KEY (id_profile) REFERENCES tb_profile (id_profile)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_user
ADD CONSTRAINT fk_user_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product
ADD CONSTRAINT fk_product_category
FOREIGN KEY (id_category) REFERENCES tb_category (id_category)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product
ADD CONSTRAINT fk_product_unit
FOREIGN KEY (id_unit) REFERENCES tb_measurement_unit (id_unit)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product_supplier
ADD CONSTRAINT fk_productsupplier_product
FOREIGN KEY (id_product) REFERENCES tb_product (id_product)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product_supplier
ADD CONSTRAINT fk_productsupplier_supplier
FOREIGN KEY (id_supplier) REFERENCES tb_supplier (id_supplier)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product_kitchen_parameter
ADD CONSTRAINT fk_parameter_product
FOREIGN KEY (id_product) REFERENCES tb_product (id_product)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_product_kitchen_parameter
ADD CONSTRAINT fk_parameter_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_stock_batch
ADD CONSTRAINT fk_batch_product
FOREIGN KEY (id_product) REFERENCES tb_product (id_product)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_stock_batch
ADD CONSTRAINT fk_batch_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_stock_batch
ADD CONSTRAINT fk_batch_supplier
FOREIGN KEY (id_supplier) REFERENCES tb_supplier (id_supplier)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition
ADD CONSTRAINT fk_requisition_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition
ADD CONSTRAINT fk_requisition_requester_user
FOREIGN KEY (id_requester_user) REFERENCES tb_user (id_user)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition
ADD CONSTRAINT fk_requisition_approver_user
FOREIGN KEY (id_approver_user) REFERENCES tb_user (id_user)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition_item
ADD CONSTRAINT fk_requisitionitem_requisition
FOREIGN KEY (id_requisition) REFERENCES tb_requisition (id_requisition)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition_item
ADD CONSTRAINT fk_requisitionitem_product
FOREIGN KEY (id_product) REFERENCES tb_product (id_product)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_requisition_item
ADD CONSTRAINT fk_requisitionitem_supplier
FOREIGN KEY (id_suggested_supplier) REFERENCES tb_supplier (id_supplier)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventory
ADD CONSTRAINT fk_inventory_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventory
ADD CONSTRAINT fk_inventory_user
FOREIGN KEY (id_responsible_user) REFERENCES tb_user (id_user)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventory_count
ADD CONSTRAINT fk_count_inventory
FOREIGN KEY (id_inventory) REFERENCES tb_inventory (id_inventory)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_inventory_count
ADD CONSTRAINT fk_count_batch
FOREIGN KEY (id_batch) REFERENCES tb_stock_batch (id_batch)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alert
ADD CONSTRAINT fk_alert_kitchen
FOREIGN KEY (id_kitchen) REFERENCES tb_kitchen (id_kitchen)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alert
ADD CONSTRAINT fk_alert_product
FOREIGN KEY (id_product) REFERENCES tb_product (id_product)
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE tb_alert
ADD CONSTRAINT fk_alert_batch
FOREIGN KEY (id_batch) REFERENCES tb_stock_batch (id_batch)
ON UPDATE NO ACTION ON DELETE NO ACTION;

-- ---------------------------------------------------
-- CHECK CONSTRAINTS
-- ---------------------------------------------------

ALTER TABLE tb_supplier
ADD CONSTRAINT ck_supplier_rating 
CHECK (rating BETWEEN 1 AND 5);

ALTER TABLE tb_stock_batch
ADD CONSTRAINT ck_batch_status 
CHECK (status IN ('ACTIVE', 'WRITTEN_OFF', 'EXPIRED', 'CANCELLED'));

ALTER TABLE tb_requisition
ADD CONSTRAINT ck_requisition_status 
CHECK (status IN ('UNDER_REVIEW', 'APPROVED', 'REJECTED', 'CANCELLED'));

ALTER TABLE tb_requisition
ADD CONSTRAINT ck_requisition_type 
CHECK (requisition_type IN ('PURCHASE', 'TRANSFER', 'CONSUMPTION'));

ALTER TABLE tb_inventory
ADD CONSTRAINT ck_inventory_status 
CHECK (status IN ('OPEN', 'CLOSED', 'CANCELLED'));

ALTER TABLE tb_alert
ADD CONSTRAINT ck_alert_severity 
CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'));