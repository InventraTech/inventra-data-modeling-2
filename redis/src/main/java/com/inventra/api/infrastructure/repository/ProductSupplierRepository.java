package com.inventra.api.infrastructure.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.inventra.api.core.domain.product.ProductSupplier;
import com.inventra.api.core.domain.product.ProductSupplierId;

public interface ProductSupplierRepository extends JpaRepository<ProductSupplier, ProductSupplierId> {

    List<ProductSupplier> findByProduct_Id(Integer productId);

}
