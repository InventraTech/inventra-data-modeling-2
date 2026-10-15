package com.inventra.api.infrastructure.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.inventra.api.core.domain.category.Category;

public interface CategoryRepository extends JpaRepository<Category, Integer> {

    boolean existsByName(String name);

}
