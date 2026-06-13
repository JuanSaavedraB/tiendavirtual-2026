package pe.edu.pucp.tiendavirtual.modelo;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "ITEMCARRITO")
@Getter
@Setter
public class ItemCarrito {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "idCarrito", nullable = false)
    @JsonIgnore
    private Carrito carrito;

    @Column(name = "codigoProducto", length = 10, nullable = false)
    private String codigoProducto;

    @Column(name = "cantidad", nullable = false)
    private Integer cantidad;

    @Column(name = "subTotal", precision = 10, scale = 2, nullable = false)
    private BigDecimal subTotal;
}
