import { Producto } from "@/lib/modelo/producto";
import { apiRequest } from "@/lib/api/http";

export async function getProductos(): Promise<Producto[]> {
  return apiRequest<Producto[]>("/api/productos");
}

export async function agregarProducto(producto: Omit<Producto, 'id'>): Promise<Producto> {
  return apiRequest<Producto>("/api/productos", {
    method: "POST",
    body: JSON.stringify(producto),
  });
}

export async function actualizarProducto(productoActualizado: Producto): Promise<Producto> {
  return apiRequest<Producto>(`/api/productos/${productoActualizado.id}`, {
    method: "PUT",
    body: JSON.stringify(productoActualizado),
  });
}

export async function eliminarProducto(id: number): Promise<void> {
  await apiRequest<void>(`/api/productos/${id}`, { method: "DELETE" });
}
