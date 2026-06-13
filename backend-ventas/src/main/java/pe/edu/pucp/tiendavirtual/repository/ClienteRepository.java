package pe.edu.pucp.tiendavirtual.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import pe.edu.pucp.tiendavirtual.modelo.Cliente;

import java.util.Optional;

public interface ClienteRepository extends JpaRepository<Cliente, Integer> {
	Optional<Cliente> findByDni(String dni);
}

