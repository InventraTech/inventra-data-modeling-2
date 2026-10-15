package com.inventra.api.core.domain.unit;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tb_measurement_unit")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString
public class Unit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_unit")
    @EqualsAndHashCode.Include
    private Integer id;

    @Column(name = "symbol", nullable = false, unique = true, length = 10)
    @EqualsAndHashCode.Include
    private String symbol;

    @Column(name = "description", nullable = false, length = 60)
    private String description;
}
