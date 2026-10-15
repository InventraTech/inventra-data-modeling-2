package com.inventra.api.core.service.unit.model.response;

import com.inventra.api.core.domain.unit.Unit;

public record UnitResponse(
        Integer id,
        String symbol,
        String description
) {
    public static UnitResponse fromEntity(Unit unit) {
        return new UnitResponse(
                unit.getId(),
                unit.getSymbol(),
                unit.getDescription()
        );
    }
}
