package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import pe.edu.pucp.tiendavirtual.modelo.Producto;
import pe.edu.pucp.tiendavirtual.repository.ProductoRepository;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class ProductoService {
    private final ProductoRepository productoRepository;
    private final LogisticaSyncPublisher syncPublisher;

    public ProductoService(ProductoRepository productoRepository, LogisticaSyncPublisher syncPublisher) {
        this.productoRepository = productoRepository;
        this.syncPublisher = syncPublisher;
    }

    public List<Producto> listar() {
        return productoRepository.findAll();
    }

    public Optional<Producto> obtenerPorId(Integer id) {
        return productoRepository.findById(id);
    }

    public Optional<Producto> obtenerPorCodigo(String codigo) {
        return productoRepository.findByCodigo(codigo);
    }

    public Producto crear(Producto producto) {
        producto.setId(null);
        Producto creado = productoRepository.save(producto);
        publicarUpsert(creado);
        return creado;
    }

    public Optional<Producto> actualizar(Integer id, Producto producto) {
        if (!productoRepository.existsById(id)) {
            return Optional.empty();
        }
        producto.setId(id);
        Producto actualizado = productoRepository.save(producto);
        publicarUpsert(actualizado);
        return Optional.of(actualizado);
    }

    public boolean eliminar(Integer id) {
        if (!productoRepository.existsById(id)) {
            return false;
        }
        productoRepository.deleteById(id);
        syncPublisher.publish("producto", "delete", Map.of("id", id));
        return true;
    }

    private void publicarUpsert(Producto producto) {
        syncPublisher.publish("producto", "upsert", Map.of(
                "id", producto.getId(),
                "codigo", producto.getCodigo(),
                "nombre", producto.getNombre(),
                "descripcion", producto.getDescripcion(),
                "precio", producto.getPrecio(),
                "stock", producto.getStock()
        ));
    }
}
