package com.inventra.api.core.domain.product;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode
public class ProductSupplierId implements Serializable {

    @Column(name = "id_product")
    private Integer productId;

    @Column(name = "id_supplier")
    private Integer supplierId;
}
