package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import pe.edu.pucp.tiendavirtual.modelo.Cliente;
import pe.edu.pucp.tiendavirtual.repository.ClienteRepository;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class ClienteService {
    private final ClienteRepository clienteRepository;
    private final VentasSyncPublisher syncPublisher;

    public ClienteService(ClienteRepository clienteRepository, VentasSyncPublisher syncPublisher) {
        this.clienteRepository = clienteRepository;
        this.syncPublisher = syncPublisher;
    }

    public List<Cliente> listar() {
        return clienteRepository.findAll();
    }

    public Optional<Cliente> obtenerPorId(Integer id) {
        return clienteRepository.findById(id);
    }

    public Optional<Cliente> buscarPorDni(String dni) {
        return clienteRepository.findByDni(dni);
    }

    public Cliente crear(Cliente cliente) {
        cliente.setId(null);
        Cliente creado = clienteRepository.save(cliente);
        syncPublisher.publish("cliente", "upsert", Map.of(
                "id", creado.getId(),
                "dni", creado.getDni(),
                "nombre", creado.getNombre(),
                "apellidos", creado.getApellidos()
        ));
        return creado;
    }

    public Optional<Cliente> actualizar(Integer id, Cliente cliente) {
        if (!clienteRepository.existsById(id)) {
            return Optional.empty();
        }
        cliente.setId(id);
        Cliente actualizado = clienteRepository.save(cliente);
        syncPublisher.publish("cliente", "upsert", Map.of(
                "id", actualizado.getId(),
                "dni", actualizado.getDni(),
                "nombre", actualizado.getNombre(),
                "apellidos", actualizado.getApellidos()
        ));
        return Optional.of(actualizado);
    }

    public boolean eliminar(Integer id) {
        if (!clienteRepository.existsById(id)) {
            return false;
        }
        clienteRepository.deleteById(id);
        syncPublisher.publish("cliente", "delete", Map.of("id", id));
        return true;
    }
}
