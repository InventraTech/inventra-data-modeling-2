package com.inventra.api.infrastructure.client.openfoodfacts.model;

public record OpenFoodFactsProduct(
        String name,
        String brand,
        String imageUrl,
        String quantity
) {
}
