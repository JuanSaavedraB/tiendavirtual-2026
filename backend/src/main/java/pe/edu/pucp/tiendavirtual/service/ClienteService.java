package pe.edu.pucp.tiendavirtual.service;

import org.springframework.stereotype.Service;
import pe.edu.pucp.tiendavirtual.modelo.Cliente;
import pe.edu.pucp.tiendavirtual.repository.ClienteRepository;

import java.util.List;
import java.util.Optional;

@Service
public class ClienteService {
    private final ClienteRepository clienteRepository;

    public ClienteService(ClienteRepository clienteRepository) {
        this.clienteRepository = clienteRepository;
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
        return clienteRepository.save(cliente);
    }

    public Optional<Cliente> actualizar(Integer id, Cliente cliente) {
        if (!clienteRepository.existsById(id)) {
            return Optional.empty();
        }
        cliente.setId(id);
        return Optional.of(clienteRepository.save(cliente));
    }

    public boolean eliminar(Integer id) {
        if (!clienteRepository.existsById(id)) {
            return false;
        }
        clienteRepository.deleteById(id);
        return true;
    }
}

