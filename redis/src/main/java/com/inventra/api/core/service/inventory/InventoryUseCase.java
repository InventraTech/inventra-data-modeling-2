package com.inventra.api.core.service.inventory;

import java.util.List;

import com.inventra.api.core.domain.inventory.Inventory;
import com.inventra.api.core.domain.inventory.InventoryCount;
import com.inventra.api.core.service.inventory.model.request.OpenInventoryRequest;
import com.inventra.api.core.service.inventory.model.request.RegisterInventoryCountRequest;

public interface InventoryUseCase {

    Inventory open(OpenInventoryRequest request);

    Inventory findById(Integer id);

    List<Inventory> listByKitchen(Integer kitchenId);

    InventoryCount registerCount(Integer inventoryId, RegisterInventoryCountRequest request);

    Inventory removeCount(Integer inventoryId, Integer countId);

    List<InventoryCount> listCounts(Integer inventoryId);

    // fecha o inventário e reconcilia a contagem física em cada lote via StockBatchUseCase
    Inventory close(Integer inventoryId);

    Inventory cancel(Integer inventoryId);
}
