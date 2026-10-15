package com.inventra.api.core.service.category;

import java.util.List;

import com.inventra.api.core.domain.category.Category;
import com.inventra.api.core.service.category.model.request.CreateCategoryRequest;
import com.inventra.api.core.service.category.model.request.UpdateCategoryRequest;

public interface CategoryUseCase {

    Category create(CreateCategoryRequest request);

    Category findById(Integer id);

    List<Category> listAll();

    Category update(Integer id, UpdateCategoryRequest request);

    void delete(Integer id);
}
