package pe.edu.pucp.tiendavirtual.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;

import java.util.List;
import java.util.Optional;

public interface CarritoRepository extends JpaRepository<Carrito, Integer> {
	List<Carrito> findAll();
	List<Carrito> findByClienteDni(String dni);
	Optional<Carrito> findById(Integer id);
}

