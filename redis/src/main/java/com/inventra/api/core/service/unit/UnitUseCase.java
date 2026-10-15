package com.inventra.api.core.service.unit;

import java.util.List;

import com.inventra.api.core.domain.unit.Unit;
import com.inventra.api.core.service.unit.model.request.CreateUnitRequest;
import com.inventra.api.core.service.unit.model.request.UpdateUnitRequest;

public interface UnitUseCase {

    Unit create(CreateUnitRequest request);

    Unit findById(Integer id);

    List<Unit> listAll();

    Unit update(Integer id, UpdateUnitRequest request);

    void delete(Integer id);
}
