package pe.edu.pucp.tiendavirtual.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.pucp.tiendavirtual.modelo.Orden;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface OrdenRepository extends JpaRepository<Orden, Integer> {
	List<Orden> findAll();
	List<Orden> findByCarritoClienteDni(String dni);
	List<Orden> findByFechaOrderByIdAsc(LocalDate fecha);
	List<Orden> findByFechaBetweenOrderByFechaAsc(LocalDate fechaInicio, LocalDate fechaFin);
	Optional<Orden> findById(Integer id);
}