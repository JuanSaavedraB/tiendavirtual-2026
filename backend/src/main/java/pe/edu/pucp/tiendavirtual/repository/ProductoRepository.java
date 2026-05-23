package pe.edu.pucp.tiendavirtual.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.pucp.tiendavirtual.modelo.Producto;

public interface ProductoRepository extends JpaRepository<Producto, Integer> {
}

