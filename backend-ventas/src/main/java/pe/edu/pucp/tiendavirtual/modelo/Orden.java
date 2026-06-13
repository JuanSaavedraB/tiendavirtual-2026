package pe.edu.pucp.tiendavirtual.modelo;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "ORDEN")
@Getter
@Setter
public class Orden {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "numero", length = 10, unique = true)
    private String numero;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "idCarrito", nullable = false)
    private Carrito carrito;

    @Column(name = "fecha", nullable = false)
    private LocalDate fecha;

    @Column(name = "subTotal", precision = 10, scale = 2, nullable = false)
    private BigDecimal subTotal;

    @Column(name = "igv", precision = 10, scale = 2, nullable = false)
    private BigDecimal igv;

    @Column(name = "total", precision = 10, scale = 2, nullable = false)
    private BigDecimal total;

    @OneToMany(mappedBy = "orden", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ItemOrden> items = new ArrayList<>();
}
