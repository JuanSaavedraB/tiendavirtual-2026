import { apiRequest } from "@/lib/api/http";
import { ItemOrden } from "@/lib/modelo/itemOrden";
import { Orden } from "@/lib/modelo/orden";
import { getProductos } from "@/lib/api/productos";
import { Producto } from "@/lib/modelo/producto";

type OrdenRaw = {
  id: number;
  numero: string;
  carrito: {
    id: number;
    nombre: string;
    fecha: string;
    cliente: {
      id: number;
      dni: string;
      nombre: string;
      apellidos: string;
    };
    items?: Array<{
      id: number;
      codigoProducto: string;
      cantidad: number;
      subTotal: number;
    }>;
  };
  fecha: string;
  subTotal: number;
  igv: number;
  total: number;
  items?: Array<{
    id: number;
    codigoProducto: string;
    cantidad: number;
    subTotal: number;
  }>;
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

export function toIsoDateParam(fecha: string): string {
  const raw = fecha.trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    return raw;
  }

  const slash = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (!slash) {
    return raw;
  }

  const first = Number(slash[1]);
  const second = Number(slash[2]);
  const year = slash[3];

  if (second > 12) {
    return `${year}-${String(first).padStart(2, "0")}-${String(second).padStart(2, "0")}`;
  }
  if (first > 12) {
    return `${year}-${String(second).padStart(2, "0")}-${String(first).padStart(2, "0")}`;
  }
  return `${year}-${String(first).padStart(2, "0")}-${String(second).padStart(2, "0")}`;
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

function toOrdenModel(ordenRaw: OrdenRaw, productos: Producto[]): Orden {
  const orden = {
    id: ordenRaw.id,
    numero: ordenRaw.numero,
    carrito: {
      id: ordenRaw.carrito.id,
      nombre: ordenRaw.carrito.nombre,
      fecha: parseApiLocalDate(ordenRaw.carrito.fecha),
      cliente: {
        id: ordenRaw.carrito.cliente.id,
        dni: ordenRaw.carrito.cliente.dni,
        nombre: ordenRaw.carrito.cliente.nombre,
        apellidos: ordenRaw.carrito.cliente.apellidos,
        carritos: [],
      },
      items: [],
    },
    fecha: parseApiLocalDate(ordenRaw.fecha),
    subTotal: Number(ordenRaw.subTotal),
    igv: Number(ordenRaw.igv),
    total: Number(ordenRaw.total),
    items: [],
  } as Orden;

  orden.items =
    ordenRaw.items?.map((itemRaw) => {
      const producto = productos.find((row) => row.codigo === itemRaw.codigoProducto) ?? productoFallback(itemRaw.codigoProducto);
      return {
        id: itemRaw.id,
        orden,
        producto,
        cantidad: itemRaw.cantidad,
        subTotal: Number(itemRaw.subTotal),
      };
    }) ?? [];

  return orden;
}

export async function listarPedidos(): Promise<Orden[]> {
  const [ordenes, productos] = await Promise.all([apiRequest<OrdenRaw[]>("/api/ordenes"), getProductos()]);
  return ordenes.map((orden) => toOrdenModel(orden, productos));
}

export async function listarPedidosPorFecha(fecha: string): Promise<Orden[]> {
  const fechaIso = toIsoDateParam(fecha);
  const [ordenes, productos] = await Promise.all([
    apiRequest<OrdenRaw[]>(`/api/ordenes?fecha=${encodeURIComponent(fechaIso)}`),
    getProductos(),
  ]);
  return ordenes.map((orden) => toOrdenModel(orden, productos));
}

export async function obtenerPedidoPorId(id: number): Promise<Orden> {
  const [orden, productos] = await Promise.all([apiRequest<OrdenRaw>(`/api/ordenes/${id}`), getProductos()]);
  return toOrdenModel(orden, productos);
}

export async function realizarPedido(
  orden: Omit<Orden, "id" | "numero" | "items"> & {
    items: Omit<ItemOrden, "id" | "orden">[];
  },
): Promise<Orden> {
  const creada = await apiRequest<OrdenRaw>("/api/ordenes", {
    method: "POST",
    body: JSON.stringify({
      carrito: { id: orden.carrito.id },
      fecha: toDateOnly(orden.fecha),
    }),
  });
  const productos = await getProductos();
  return toOrdenModel(creada, productos);
}

export async function actualizarPedido(orden: Orden): Promise<Orden> {
  const actualizada = await apiRequest<OrdenRaw>(`/api/ordenes/${orden.id}`, {
    method: "PUT",
    body: JSON.stringify({
      id: orden.id,
      numero: orden.numero,
      carrito: { id: orden.carrito.id },
      fecha: toDateOnly(orden.fecha),
      items: (orden.items ?? []).map((item) => ({
        id: item.id,
        codigoProducto: item.producto.codigo,
        cantidad: item.cantidad,
        subTotal: item.subTotal,
      })),
      subTotal: orden.subTotal,
      igv: orden.igv,
      total: orden.total,
    }),
  });
  const productos = await getProductos();
  return toOrdenModel(actualizada, productos);
}

export async function eliminarPedido(id: number): Promise<void> {
  await apiRequest<void>(`/api/ordenes/${id}`, { method: "DELETE" });
}
