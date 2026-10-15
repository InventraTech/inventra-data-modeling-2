package com.inventra.api.core.domain.profile;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tb_profile")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString
public class Profile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_profile")
    @EqualsAndHashCode.Include
    private Integer id;

    @Column(name = "access_type", nullable = false, unique = true, length = 50)
    @EqualsAndHashCode.Include
    private String accessType;

    @Column(name = "description", length = 255)
    private String description;
}
