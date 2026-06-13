package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;
import pe.edu.pucp.tiendavirtual.modelo.ItemCarrito;
import pe.edu.pucp.tiendavirtual.repository.CarritoRepository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class CarritoService {
    private final CarritoRepository carritoRepository;
    private final ItemPricingService itemPricingService;
    private final VentasSyncPublisher syncPublisher;

    public CarritoService(
            CarritoRepository carritoRepository,
            ItemPricingService itemPricingService,
            VentasSyncPublisher syncPublisher
    ) {
        this.carritoRepository = carritoRepository;
        this.itemPricingService = itemPricingService;
        this.syncPublisher = syncPublisher;
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
        Carrito creado = carritoRepository.save(carrito);
        publicarSnapshotCarrito(creado, false);
        return creado;
    }

    @Transactional
    public Optional<Carrito> actualizar(Integer id, Carrito carrito) {
        if (!carritoRepository.existsById(id)) {
            return Optional.empty();
        }
        carrito.setId(id);
        recalcularSubTotales(carrito);
        Carrito actualizado = carritoRepository.save(carrito);
        publicarSnapshotCarrito(actualizado, true);
        return Optional.of(actualizado);
    }

    @Transactional
    public boolean eliminar(Integer id) {
        if (!carritoRepository.existsById(id)) {
            return false;
        }
        syncPublisher.publish("itemcarrito", "delete_by_carrito", Map.of("idCarrito", id));
        syncPublisher.publish("carrito", "delete", Map.of("id", id));
        carritoRepository.deleteById(id);
        return true;
    }

    private void recalcularSubTotales(Carrito carrito) {
        if (carrito.getItems() == null || carrito.getItems().isEmpty()) {
            throw new IllegalArgumentException("El carrito debe tener al menos un item.");
        }

        for (ItemCarrito item : carrito.getItems()) {
            ItemPricingService.ProductSubtotal calculo =
                    itemPricingService.calcularSubtotal(item.getCodigoProducto(), item.getCantidad());

            item.setCodigoProducto(calculo.codigoProducto());
            item.setCarrito(carrito);
            item.setSubTotal(calculo.subTotal());
        }
    }

    private void publicarSnapshotCarrito(Carrito carrito, boolean reemplazarItems) {
        syncPublisher.publish("carrito", "upsert", Map.of(
                "id", carrito.getId(),
                "idCliente", carrito.getCliente().getId(),
                "nombre", carrito.getNombre(),
                "fecha", carrito.getFecha()
        ));

        if (reemplazarItems) {
            syncPublisher.publish("itemcarrito", "delete_by_carrito", Map.of("idCarrito", carrito.getId()));
        }

        for (ItemCarrito item : carrito.getItems()) {
            Map<String, Object> payload = new HashMap<>();
            payload.put("id", item.getId());
            payload.put("idCarrito", carrito.getId());
            payload.put("codigoProducto", item.getCodigoProducto());
            payload.put("cantidad", item.getCantidad());
            payload.put("subTotal", item.getSubTotal());
            syncPublisher.publish("itemcarrito", "upsert", payload);
        }
    }
}
