package com.inventra.api.core.domain.category;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tb_category")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_category")
    @EqualsAndHashCode.Include
    private Integer id;

    @Column(name = "name", nullable = false, unique = true, length = 80)
    @EqualsAndHashCode.Include
    private String name;

    @Column(name = "description", length = 255)
    private String description;
}
