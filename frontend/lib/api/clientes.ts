import { Cliente } from "@/lib/modelo/cliente";
import { apiRequest } from "@/lib/api/http";

type ClienteRaw = Omit<Cliente, "carritos">;

function toClienteModel(cliente: ClienteRaw): Cliente {
  return {
    ...cliente,
    carritos: [],
  };
}

export async function getClientes(): Promise<Cliente[]> {
  const clientes = await apiRequest<ClienteRaw[]>("/api/clientes");
  return clientes.map(toClienteModel);
}

export async function getClientePorId(id: number): Promise<Cliente> {
  const cliente = await apiRequest<ClienteRaw>(`/api/clientes/${id}`);
  return toClienteModel(cliente);
}

export async function registrarCliente(cliente: Omit<Cliente, 'id'>): Promise<Cliente> {
  const creado = await apiRequest<ClienteRaw>("/api/clientes", {
    method: "POST",
    body: JSON.stringify({
      dni: cliente.dni,
      nombre: cliente.nombre,
      apellidos: cliente.apellidos,
    }),
  });
  return toClienteModel(creado);
}

export async function actualizarCliente(clienteActualizado: Cliente): Promise<Cliente> {
  const actualizado = await apiRequest<ClienteRaw>(`/api/clientes/${clienteActualizado.id}`, {
    method: "PUT",
    body: JSON.stringify({
      id: clienteActualizado.id,
      dni: clienteActualizado.dni,
      nombre: clienteActualizado.nombre,
      apellidos: clienteActualizado.apellidos,
    }),
  });
  return toClienteModel(actualizado);
}

export async function eliminarCliente(id: number): Promise<void> {
  await apiRequest<void>(`/api/clientes/${id}`, { method: "DELETE" });
}
