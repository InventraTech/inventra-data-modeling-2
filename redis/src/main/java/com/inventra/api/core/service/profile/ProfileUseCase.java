package com.inventra.api.core.service.profile;

import java.util.List;

import com.inventra.api.core.domain.profile.Profile;
import com.inventra.api.core.service.profile.model.request.CreateProfileRequest;
import com.inventra.api.core.service.profile.model.request.UpdateProfileRequest;

public interface ProfileUseCase {

    Profile create(CreateProfileRequest request);

    Profile findById(Integer id);

    List<Profile> listAll();

    Profile update(Integer id, UpdateProfileRequest request);

    void delete(Integer id);
}
