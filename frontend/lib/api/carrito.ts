import { apiRequest } from "@/lib/api/http";
import { getProductos } from "@/lib/api/productos";
import { Carrito } from "@/lib/modelo/carrito";
import { ItemCarrito } from "@/lib/modelo/itemCarrito";
import { Producto } from "@/lib/modelo/producto";

type CarritoRaw = {
  id: number;
  nombre: string;
  fecha: string;
  cliente: {
    id: number;
    dni: string;
    nombre: string;
    apellidos: string;
  };
  items?: ItemCarritoRaw[];
};

type ItemCarritoRaw = {
  id: number;
  codigoProducto: string;
  cantidad: number;
  subTotal: number;
};

function toDateOnly(value: Date | string): string {
  if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value.trim())) {
    return value.trim();
  }
  const date = typeof value === "string" ? new Date(value) : value;
  return date.toISOString().slice(0, 10);
}

function parseApiLocalDate(value: string): Date {
  const isoDate = value.trim().slice(0, 10);
  const [year, month, day] = isoDate.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function productoFallback(codigo: string): Producto {
  return {
    id: 0,
    codigo,
    nombre: codigo,
    descripcion: "Producto no encontrado",
    precio: 0,
    stock: 0,
  };
}

function toCarritoModel(carritoRaw: CarritoRaw, productos: Producto[]): Carrito {
  const carrito = {
    id: carritoRaw.id,
    nombre: carritoRaw.nombre,
    fecha: parseApiLocalDate(carritoRaw.fecha),
    cliente: {
      id: carritoRaw.cliente.id,
      dni: carritoRaw.cliente.dni,
      nombre: carritoRaw.cliente.nombre,
      apellidos: carritoRaw.cliente.apellidos,
      carritos: [],
    },
    items: [],
  } as Carrito;

  carrito.items =
    carritoRaw.items?.map((item) => {
      const producto = productos.find((row) => row.codigo === item.codigoProducto) ?? productoFallback(item.codigoProducto);
      return {
        id: item.id,
        carrito,
        producto,
        cantidad: item.cantidad,
        subTotal: Number(item.subTotal),
      };
    }) ?? [];

  return carrito;
}

function toItemCarritoRaw(item: ItemCarrito): ItemCarritoRaw {
  return {
    id: item.id,
    codigoProducto: item.producto.codigo,
    cantidad: item.cantidad,
    subTotal: item.subTotal,
  };
}

function toCarritoPayload(carrito: Carrito): Record<string, unknown> {
  return {
    id: carrito.id || null,
    nombre: carrito.nombre,
    fecha: toDateOnly(carrito.fecha),
    cliente: {
      id: carrito.cliente.id,
      dni: carrito.cliente.dni,
      nombre: carrito.cliente.nombre,
      apellidos: carrito.cliente.apellidos,
    },
    items: carrito.items?.map(toItemCarritoRaw) ?? [],
  };
}

async function hydrateCarrito(carritoRaw: CarritoRaw): Promise<Carrito> {
  const productos = await getProductos();
  return toCarritoModel(carritoRaw, productos);
}

export async function getCarritos(): Promise<Carrito[]> {
  const [carritos, productos] = await Promise.all([apiRequest<CarritoRaw[]>("/api/carritos"), getProductos()]);
  return carritos.map((carrito) => toCarritoModel(carrito, productos));
}

export async function getCarritoPorId(id: number): Promise<Carrito> {
  const carrito = await apiRequest<CarritoRaw>(`/api/carritos/${id}`);
  return hydrateCarrito(carrito);
}

export async function getCarritoPorCliente(clienteId: number): Promise<Carrito | undefined> {
  const carritos = await getCarritos();
  return carritos.find((carrito) => carrito.cliente.id === clienteId);
}

export async function crearCarrito(carrito: Carrito): Promise<Carrito> {
  const creado = await apiRequest<CarritoRaw>("/api/carritos", {
    method: "POST",
    body: JSON.stringify(toCarritoPayload(carrito)),
  });
  return hydrateCarrito(creado);
}

export async function actualizarCarrito(id: number, carrito: Carrito): Promise<Carrito> {
  const actualizado = await apiRequest<CarritoRaw>(`/api/carritos/${id}`, {
    method: "PUT",
    body: JSON.stringify(toCarritoPayload(carrito)),
  });
  return hydrateCarrito(actualizado);
}

export async function agregarItemAlCarrito(nuevoItem: Omit<ItemCarrito, "id">): Promise<Carrito> {
  const carritoActual = await getCarritoPorId(nuevoItem.carrito.id);
  const actualizado: Carrito = {
    ...carritoActual,
    items: [
      ...(carritoActual.items ?? []),
      {
        ...nuevoItem,
        id: 0,
      },
    ],
  };
  return actualizarCarrito(carritoActual.id, actualizado);
}

export async function actualizarItemCarrito(item: ItemCarrito): Promise<Carrito> {
  const carritoActual = await getCarritoPorId(item.carrito.id);
  const actualizado: Carrito = {
    ...carritoActual,
    items: (carritoActual.items ?? []).map((row) => (row.id === item.id ? item : row)),
  };
  return actualizarCarrito(carritoActual.id, actualizado);
}

export async function eliminarItemDelCarrito(itemId: number, carritoId: number): Promise<Carrito> {
  const carritoActual = await getCarritoPorId(carritoId);
  const actualizado: Carrito = {
    ...carritoActual,
    items: (carritoActual.items ?? []).filter((item) => item.id !== itemId),
  };
  return actualizarCarrito(carritoActual.id, actualizado);
}

export async function eliminarCarrito(id: number): Promise<void> {
  await apiRequest<void>(`/api/carritos/${id}`, { method: "DELETE" });
}
