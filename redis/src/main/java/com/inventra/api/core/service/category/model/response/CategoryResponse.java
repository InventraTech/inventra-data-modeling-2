package com.inventra.api.core.service.category.model.response;

import com.inventra.api.core.domain.category.Category;

public record CategoryResponse(
        Integer id,
        String name,
        String description
) {
    public static CategoryResponse fromEntity(Category category) {
        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getDescription()
        );
    }
}
