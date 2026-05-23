package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import pe.edu.pucp.tiendavirtual.modelo.Producto;
import pe.edu.pucp.tiendavirtual.repository.ProductoRepository;

import java.util.List;
import java.util.Optional;

@Service
public class ProductoService {
    private final ProductoRepository productoRepository;

    public ProductoService(ProductoRepository productoRepository) {
        this.productoRepository = productoRepository;
    }

    public List<Producto> listar() {
        return productoRepository.findAll();
    }

    public Optional<Producto> obtenerPorId(Integer id) {
        return productoRepository.findById(id);
    }

    public Producto crear(Producto producto) {
        producto.setId(null);
        return productoRepository.save(producto);
    }

    public Optional<Producto> actualizar(Integer id, Producto producto) {
        if (!productoRepository.existsById(id)) {
            return Optional.empty();
        }
        producto.setId(id);
        return Optional.of(productoRepository.save(producto));
    }

    public boolean eliminar(Integer id) {
        if (!productoRepository.existsById(id)) {
            return false;
        }
        productoRepository.deleteById(id);
        return true;
    }
}

