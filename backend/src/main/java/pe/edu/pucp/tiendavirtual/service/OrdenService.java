package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;
import pe.edu.pucp.tiendavirtual.modelo.ItemCarrito;
import pe.edu.pucp.tiendavirtual.modelo.ItemOrden;
import pe.edu.pucp.tiendavirtual.modelo.Orden;
import pe.edu.pucp.tiendavirtual.repository.CarritoRepository;
import pe.edu.pucp.tiendavirtual.repository.OrdenRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class OrdenService {
    private static final BigDecimal IGV_RATE = new BigDecimal("0.18");

    private final OrdenRepository ordenRepository;
    private final CarritoRepository carritoRepository;
    private final ItemPricingService itemPricingService;

    public OrdenService(
            OrdenRepository ordenRepository,
            CarritoRepository carritoRepository,
            ItemPricingService itemPricingService
    ) {
        this.ordenRepository = ordenRepository;
        this.carritoRepository = carritoRepository;
        this.itemPricingService = itemPricingService;
    }

    public List<Orden> listar() {
        return ordenRepository.findAll();
    }

    public Optional<Orden> obtenerPorId(Integer id) {
        return ordenRepository.findById(id);
    }

    public List<Orden> buscarPorDniCliente(String dni) {
        return ordenRepository.findByCarritoClienteDni(dni);
    }

    public List<Orden> buscarPorFecha(LocalDate fecha) {
        return ordenRepository.findByFechaOrderByIdAsc(fecha);
    }

    public List<Orden> buscarPorFechaEntre(LocalDate fechaInicio, LocalDate fechaFin) {
        return ordenRepository.findByFechaBetweenOrderByFechaAsc(fechaInicio, fechaFin);
    }

    @Transactional
    public Orden crear(Orden orden) {
        orden.setId(null);
        orden.setNumero(null);

        Integer carritoId = orden.getCarrito() != null ? orden.getCarrito().getId() : null;
        if (carritoId == null) {
            throw new IllegalArgumentException("La orden debe incluir un carrito valido.");
        }

        Carrito carrito = carritoRepository.findById(carritoId)
                .orElseThrow(() -> new IllegalArgumentException("Carrito no encontrado: " + carritoId));

        orden.setCarrito(carrito);
        if (orden.getFecha() == null) {
            orden.setFecha(LocalDate.now());
        }

        poblarItemsYTotalesDesdeCarrito(orden, carrito);

        Orden creada = ordenRepository.saveAndFlush(orden);
        creada.setNumero(formatearNumeroOrden(creada.getId()));
        return ordenRepository.save(creada);
    }

    @Transactional
    public Optional<Orden> actualizar(Integer id, Orden orden) {
        Optional<Orden> existenteOpt = ordenRepository.findById(id);
        if (existenteOpt.isEmpty()) {
            return Optional.empty();
        }

        Orden existente = existenteOpt.get();
        Carrito carritoExistente = existente.getCarrito();

        orden.setId(id);
        orden.setNumero(formatearNumeroOrden(id));
        orden.setCarrito(carritoExistente);
        if (orden.getFecha() == null) {
            throw new IllegalArgumentException("Para PUT debes enviar la fecha de la orden.");
        }

        if (orden.getItems() == null || orden.getItems().isEmpty()) {
            throw new IllegalArgumentException("Para PUT debes enviar todos los items de la orden.");
        }

        poblarItemsYTotalesDesdePayload(orden, orden.getItems());

        Orden actualizada = ordenRepository.saveAndFlush(orden);
        return Optional.of(actualizada);
    }

    @Transactional
    public boolean eliminar(Integer id) {
        if (!ordenRepository.existsById(id)) {
            return false;
        }
        ordenRepository.deleteById(id);
        return true;
    }

    private void poblarItemsYTotalesDesdeCarrito(Orden orden, Carrito carrito) {
        if (carrito.getItems() == null || carrito.getItems().isEmpty()) {
            throw new IllegalArgumentException("El carrito debe tener al menos un item para generar una orden.");
        }

        List<ItemOrden> itemsOrden = new ArrayList<>();
        BigDecimal subTotalOrden = BigDecimal.ZERO;

        for (ItemCarrito itemCarrito : carrito.getItems()) {
            Integer productoId = itemCarrito.getProducto() != null ? itemCarrito.getProducto().getId() : null;
            ItemPricingService.ProductSubtotal calculo =
                    itemPricingService.calcularSubtotal(productoId, itemCarrito.getCantidad());

            ItemOrden itemOrden = new ItemOrden();
            itemOrden.setOrden(orden);
            itemOrden.setProducto(calculo.producto());
            itemOrden.setCantidad(itemCarrito.getCantidad());
            itemOrden.setSubTotal(calculo.subTotal());

            itemsOrden.add(itemOrden);
            subTotalOrden = subTotalOrden.add(calculo.subTotal());
        }

        subTotalOrden = subTotalOrden.setScale(2, RoundingMode.HALF_UP);
        BigDecimal igv = subTotalOrden.multiply(IGV_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = subTotalOrden.add(igv).setScale(2, RoundingMode.HALF_UP);

        orden.setItems(itemsOrden);
        orden.setSubTotal(subTotalOrden);
        orden.setIgv(igv);
        orden.setTotal(total);
    }

    private void poblarItemsYTotalesDesdePayload(Orden orden, List<ItemOrden> itemsPayload) {
        List<ItemOrden> itemsOrden = new ArrayList<>();
        BigDecimal subTotalOrden = BigDecimal.ZERO;

        for (ItemOrden itemPayload : itemsPayload) {
            Integer productoId = itemPayload.getProducto() != null ? itemPayload.getProducto().getId() : null;
            ItemPricingService.ProductSubtotal calculo =
                    itemPricingService.calcularSubtotal(productoId, itemPayload.getCantidad());

            ItemOrden itemOrden = new ItemOrden();
            itemOrden.setId(null);
            itemOrden.setOrden(orden);
            itemOrden.setProducto(calculo.producto());
            itemOrden.setCantidad(itemPayload.getCantidad());
            itemOrden.setSubTotal(calculo.subTotal());

            itemsOrden.add(itemOrden);
            subTotalOrden = subTotalOrden.add(calculo.subTotal());
        }

        subTotalOrden = subTotalOrden.setScale(2, RoundingMode.HALF_UP);
        BigDecimal igv = subTotalOrden.multiply(IGV_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = subTotalOrden.add(igv).setScale(2, RoundingMode.HALF_UP);

        orden.setItems(itemsOrden);
        orden.setSubTotal(subTotalOrden);
        orden.setIgv(igv);
        orden.setTotal(total);
    }

    private String formatearNumeroOrden(Integer id) {
        return String.format("ORD%07d", id);
    }
}
