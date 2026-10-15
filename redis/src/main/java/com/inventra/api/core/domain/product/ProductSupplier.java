package com.inventra.api.core.domain.product;

import com.inventra.api.core.domain.supplier.Supplier;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "tb_product_supplier")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString
public class ProductSupplier {

    @EmbeddedId
    @EqualsAndHashCode.Include
    private ProductSupplierId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("productId")
    @JoinColumn(name = "id_product")
    @ToString.Exclude
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("supplierId")
    @JoinColumn(name = "id_supplier")
    @ToString.Exclude
    private Supplier supplier;

    @Column(name = "supplier_code", length = 50)
    private String supplierCode;

    @Column(name = "reference_price", precision = 12, scale = 2)
    private BigDecimal referencePrice;

    @Column(name = "lead_time_days")
    private Integer leadTimeDays;
}
