import Link from "next/link";
import { listarPedidos, listarPedidosPorFecha, toIsoDateParam } from "@/lib/api/ordenes";

interface OrdenesPageProps {
  searchParams?: Promise<{ fecha?: string }>;
}

export default async function OrdenesPage({ searchParams }: OrdenesPageProps) {
  const query = (await searchParams) ?? {};
  const fecha = query.fecha;
  const fechaIso = fecha ? toIsoDateParam(fecha) : undefined;
  const ordenes = fechaIso ? await listarPedidosPorFecha(fechaIso) : await listarPedidos();
  const fechaFormatter = new Intl.DateTimeFormat("es-PE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });

  return (
    <section className="space-y-6 rounded-lg bg-white p-6 shadow-md">
      <header>
        <h2 className="text-3xl font-bold text-gray-800">Ordenes</h2>
        <p className="mt-1 text-gray-600">Consulta SSR de ordenes con filtro por fecha.</p>
      </header>

      <form className="flex flex-col gap-3 md:flex-row md:items-end" method="get">
        <div>
          <label className="block text-sm font-medium text-gray-700" htmlFor="fecha">
            Fecha
          </label>
          <input
            id="fecha"
            name="fecha"
            type="date"
            lang="es-PE"
            defaultValue={fechaIso ?? ""}
            className="mt-1 rounded-md border p-2"
          />
        </div>
        <button type="submit" className="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700">
          Filtrar
        </button>
        <Link href="/ordenes" className="rounded-md bg-gray-200 px-4 py-2 text-center text-gray-800 hover:bg-gray-300">
          Limpiar
        </Link>
      </form>

      {ordenes.length === 0 ? (
        <p className="text-gray-600">No hay ordenes para mostrar.</p>
      ) : (
        <div className="space-y-4">
          {ordenes.map((orden) => (
            <article key={orden.id} className="rounded-md border border-gray-200 p-4">
              <header className="mb-2 flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                <h3 className="text-lg font-semibold text-gray-800">
                  {orden.numero} (ID {orden.id})
                </h3>
                <p className="text-sm text-gray-600">Fecha: {fechaFormatter.format(new Date(orden.fecha))}</p>
              </header>
              <p className="mb-3 text-sm text-gray-700">
                Cliente: {orden.carrito.cliente.nombre} {orden.carrito.cliente.apellidos}
              </p>

              <div className="overflow-x-auto">
                <table className="min-w-full overflow-hidden rounded-md">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-semibold uppercase">Producto</th>
                      <th className="px-4 py-2 text-left text-xs font-semibold uppercase">Cantidad</th>
                      <th className="px-4 py-2 text-left text-xs font-semibold uppercase">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody>
                    {orden.items?.map((item) => (
                      <tr key={item.id} className="border-t border-gray-200">
                        <td className="px-4 py-2 text-sm text-gray-900">{item.producto.nombre}</td>
                        <td className="px-4 py-2 text-sm text-gray-900">{item.cantidad}</td>
                        <td className="px-4 py-2 text-sm text-gray-900">S/ {item.subTotal.toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <footer className="mt-3 flex flex-col gap-1 text-right text-sm font-medium text-gray-700">
                <span>Subtotal: S/ {orden.subTotal.toFixed(2)}</span>
                <span>IGV (18%): S/ {orden.igv.toFixed(2)}</span>
                <span className="text-base font-bold text-gray-900">Total: S/ {orden.total.toFixed(2)}</span>
              </footer>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
