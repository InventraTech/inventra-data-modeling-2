package com.inventra.api.core.service.product.model.response;

import java.math.BigDecimal;
import java.math.RoundingMode;

import com.inventra.api.core.domain.product.ProductKitchenParameter;

public record ProductKitchenParameterResponse(
        KitchenSummary kitchen,
        BigDecimal minStock,
        BigDecimal maxStock,
        BigDecimal averageDailyConsumption,
        BigDecimal currentQuantity,
        BigDecimal estimatedDaysUntilStockout,
        boolean lowStock,
        boolean overStock
) {
    public record KitchenSummary(Integer id, String name) {
    }

    public static ProductKitchenParameterResponse from(ProductKitchenParameter parameter, BigDecimal currentQuantity) {
        BigDecimal avgConsumption = parameter.getAverageDailyConsumption();
        BigDecimal daysUntilStockout = (avgConsumption != null && avgConsumption.compareTo(BigDecimal.ZERO) > 0)
                ? currentQuantity.divide(avgConsumption, 1, RoundingMode.HALF_UP)
                : null;

        return new ProductKitchenParameterResponse(
                new KitchenSummary(parameter.getKitchen().getId(), parameter.getKitchen().getName()),
                parameter.getMinStock(),
                parameter.getMaxStock(),
                avgConsumption,
                currentQuantity,
                daysUntilStockout,
                currentQuantity.compareTo(parameter.getMinStock()) < 0,
                parameter.getMaxStock() != null && currentQuantity.compareTo(parameter.getMaxStock()) > 0
        );
    }
}
