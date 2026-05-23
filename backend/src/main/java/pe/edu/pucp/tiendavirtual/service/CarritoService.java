package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;
import pe.edu.pucp.tiendavirtual.modelo.ItemCarrito;
import pe.edu.pucp.tiendavirtual.repository.CarritoRepository;

import java.util.List;
import java.util.Optional;

@Service
public class CarritoService {
    private final CarritoRepository carritoRepository;
    private final ItemPricingService itemPricingService;

    public CarritoService(CarritoRepository carritoRepository, ItemPricingService itemPricingService) {
        this.carritoRepository = carritoRepository;
        this.itemPricingService = itemPricingService;
    }

    public List<Carrito> listar() {
        return carritoRepository.findAll();
    }

    public Optional<Carrito> obtenerPorId(Integer id) {
        return carritoRepository.findById(id);
    }

    public List<Carrito> buscarPorDniCliente(String dni) {
        return carritoRepository.findByClienteDni(dni);
    }

    @Transactional
    public Carrito crear(Carrito carrito) {
        carrito.setId(null);
        recalcularSubTotales(carrito);
        return carritoRepository.save(carrito);
    }

    @Transactional
    public Optional<Carrito> actualizar(Integer id, Carrito carrito) {
        if (!carritoRepository.existsById(id)) {
            return Optional.empty();
        }
        carrito.setId(id);
        recalcularSubTotales(carrito);
        return Optional.of(carritoRepository.save(carrito));
    }

    @Transactional
    public boolean eliminar(Integer id) {
        if (!carritoRepository.existsById(id)) {
            return false;
        }
        carritoRepository.deleteById(id);
        return true;
    }

    private void recalcularSubTotales(Carrito carrito) {
        if (carrito.getItems() == null || carrito.getItems().isEmpty()) {
            throw new IllegalArgumentException("El carrito debe tener al menos un item.");
        }

        for (ItemCarrito item : carrito.getItems()) {
            Integer productoId = item.getProducto() != null ? item.getProducto().getId() : null;
            ItemPricingService.ProductSubtotal calculo = itemPricingService.calcularSubtotal(productoId, item.getCantidad());

            item.setProducto(calculo.producto());
            item.setCarrito(carrito);
            item.setSubTotal(calculo.subTotal());
        }
    }
}
