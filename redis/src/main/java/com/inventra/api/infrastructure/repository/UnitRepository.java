package com.inventra.api.infrastructure.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.inventra.api.core.domain.unit.Unit;

public interface UnitRepository extends JpaRepository<Unit, Integer> {

    boolean existsBySymbol(String symbol);

}
