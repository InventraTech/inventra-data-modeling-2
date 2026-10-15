package com.inventra.api.core.domain.inventory;

import com.inventra.api.core.domain.stock.StockBatch;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "tb_inventory_count")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString
public class InventoryCount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_count")
    @EqualsAndHashCode.Include
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_inventory", nullable = false)
    @ToString.Exclude
    private Inventory inventory;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_batch", nullable = false)
    @ToString.Exclude
    private StockBatch batch;

    @Column(name = "registered_quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal registeredQuantity;

    @Column(name = "physical_quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal physicalQuantity;

    @Column(name = "divergence", precision = 12, scale = 3)
    private BigDecimal divergence;

    @Column(name = "note", length = 255)
    private String note;
}
