package com.inventra.api.core.service.inventory.model.response;

import java.math.BigDecimal;

import com.inventra.api.core.domain.inventory.InventoryCount;

public record InventoryCountResponse(
        Integer id,
        Integer inventoryId,
        BatchSummary batch,
        BigDecimal registeredQuantity,
        BigDecimal physicalQuantity,
        BigDecimal divergence,
        String note
) {
    public record BatchSummary(Integer id, String batchNumber) {
    }

    public static InventoryCountResponse fromEntity(InventoryCount count) {
        return new InventoryCountResponse(
                count.getId(),
                count.getInventory().getId(),
                new BatchSummary(count.getBatch().getId(), count.getBatch().getBatchNumber()),
                count.getRegisteredQuantity(),
                count.getPhysicalQuantity(),
                count.getDivergence(),
                count.getNote()
        );
    }
}
