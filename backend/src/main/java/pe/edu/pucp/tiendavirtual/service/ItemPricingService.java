package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import pe.edu.pucp.tiendavirtual.modelo.Producto;
import pe.edu.pucp.tiendavirtual.repository.ProductoRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class ItemPricingService {
    private final ProductoRepository productoRepository;

    public ItemPricingService(ProductoRepository productoRepository) {
        this.productoRepository = productoRepository;
    }

    public ProductSubtotal calcularSubtotal(Integer productoId, Integer cantidad) {
        if (productoId == null) {
            throw new IllegalArgumentException("Cada item debe incluir un producto valido.");
        }
        if (cantidad == null || cantidad <= 0) {
            throw new IllegalArgumentException("La cantidad de cada item debe ser mayor a cero.");
        }

        Producto producto = productoRepository.findById(productoId)
                .orElseThrow(() -> new IllegalArgumentException("Producto no encontrado: " + productoId));

        BigDecimal subTotal = producto.getPrecio()
                .multiply(BigDecimal.valueOf(cantidad))
                .setScale(2, RoundingMode.HALF_UP);

        return new ProductSubtotal(producto, subTotal);
    }

    public record ProductSubtotal(Producto producto, BigDecimal subTotal) {}
}
