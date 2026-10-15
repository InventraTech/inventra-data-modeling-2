package com.inventra.api.infrastructure.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.inventra.api.core.domain.supplier.Supplier;

public interface SupplierRepository extends JpaRepository<Supplier, Integer> {

    boolean existsByCnpj(String cnpj);

    List<Supplier> findByActiveTrue();

}
