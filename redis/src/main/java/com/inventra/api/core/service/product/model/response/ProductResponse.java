package com.inventra.api.core.service.product.model.response;

import java.time.LocalDateTime;

import com.inventra.api.core.domain.product.Product;

public record ProductResponse(
        Integer id,
        String name,
        String brand,
        CategorySummary category,
        UnitSummary unit,
        String barcode,
        String photoUrl,
        Boolean active,
        LocalDateTime createdAt
) {
    public record CategorySummary(Integer id, String name) {
    }

    public record UnitSummary(Integer id, String symbol) {
    }

    public static ProductResponse fromEntity(Product product) {
        var category = product.getCategory() != null
                ? new CategorySummary(product.getCategory().getId(), product.getCategory().getName())
                : null;
        var unit = new UnitSummary(product.getUnit().getId(), product.getUnit().getSymbol());

        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getBrand(),
                category,
                unit,
                product.getBarcode(),
                product.getPhotoUrl(),
                product.getActive(),
                product.getCreatedAt()
        );
    }
}
