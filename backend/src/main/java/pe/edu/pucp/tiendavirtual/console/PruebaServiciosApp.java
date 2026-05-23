package pe.edu.pucp.tiendavirtual.console;

import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;
import pe.edu.pucp.tiendavirtual.modelo.Cliente;
import pe.edu.pucp.tiendavirtual.modelo.ItemCarrito;
import pe.edu.pucp.tiendavirtual.modelo.ItemOrden;
import pe.edu.pucp.tiendavirtual.modelo.Orden;
import pe.edu.pucp.tiendavirtual.modelo.Producto;
import pe.edu.pucp.tiendavirtual.service.CarritoService;
import pe.edu.pucp.tiendavirtual.service.ClienteService;
import pe.edu.pucp.tiendavirtual.service.OrdenService;
import pe.edu.pucp.tiendavirtual.service.ProductoService;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

public class PruebaServiciosApp {

    public static void main(String[] args) {
        ConfigurableApplicationContext context = new SpringApplicationBuilder(pe.edu.pucp.tiendavirtual.app.App.class)
                .web(WebApplicationType.NONE)
                .run(args);

        ClienteService clienteService = context.getBean(ClienteService.class);
        ProductoService productoService = context.getBean(ProductoService.class);
        CarritoService carritoService = context.getBean(CarritoService.class);
        OrdenService ordenService = context.getBean(OrdenService.class);

        Integer clienteId = null;
        Integer productoId = null;
        Integer carritoId = null;
        Integer ordenId = null;

        try {
            String sufijo = String.valueOf(System.currentTimeMillis() % 10000000);
            String dni = String.format("9%07d", Integer.parseInt(sufijo));

            Cliente cliente = new Cliente();
            cliente.setDni(dni);
            cliente.setNombre("Cliente");
            cliente.setApellidos("Secuencia");
            cliente = clienteService.crear(cliente);
            clienteId = cliente.getId();
            System.out.println("Cliente creado: " + clienteId);

            Producto producto = new Producto();
            producto.setCodigo("TMP" + sufijo);
            producto.setNombre("ProductoSec");
            producto.setDescripcion("Producto temporal");
            producto.setPrecio(new BigDecimal("120.50"));
            producto.setStock(10);
            producto = productoService.crear(producto);
            productoId = producto.getId();
            System.out.println("Producto creado: " + productoId);

            Carrito carrito = new Carrito();
            carrito.setNombre("CarritoSec");
            carrito.setFecha(LocalDate.now());
            carrito.setCliente(cliente);

            ItemCarrito itemCarrito = new ItemCarrito();
            itemCarrito.setCarrito(carrito);
            itemCarrito.setProducto(producto);
            itemCarrito.setCantidad(2);
            itemCarrito.setSubTotal(new BigDecimal("241.00"));
            carrito.getItems().add(itemCarrito);

            carrito = carritoService.crear(carrito);
            carritoId = carrito.getId();
            System.out.println("Carrito creado con items: " + carritoId);

            Orden orden = new Orden();
            orden.setNumero("S" + sufijo.substring(0, Math.min(7, sufijo.length())));
            orden.setCarrito(carrito);
            orden.setFecha(LocalDate.now());
            orden.setSubTotal(new BigDecimal("241.00"));
            orden.setIgv(new BigDecimal("43.38"));
            orden.setTotal(new BigDecimal("284.38"));

            ItemOrden itemOrden = new ItemOrden();
            itemOrden.setOrden(orden);
            itemOrden.setProducto(producto);
            itemOrden.setCantidad(2);
            itemOrden.setSubTotal(new BigDecimal("241.00"));
            orden.getItems().add(itemOrden);

            orden = ordenService.crear(orden);
            ordenId = orden.getId();
            System.out.println("Orden creada con items: " + ordenId);

            Optional<Cliente> clienteBuscado = clienteService.buscarPorDni(dni);
            System.out.println("Cliente por DNI encontrado: " + clienteBuscado.isPresent());
            System.out.println("Carritos por DNI: " + carritoService.buscarPorDniCliente(dni).size());
            System.out.println("Ordenes por DNI: " + ordenService.buscarPorDniCliente(dni).size());
            System.out.println("Ordenes por fecha hoy: "
                    + ordenService.buscarPorFechaEntre(LocalDate.now(), LocalDate.now()).size());

            producto.setNombre("ProductoSecUpd");
            productoService.actualizar(productoId, producto);
            carrito.setNombre("CarritoSecUpd");
            carritoService.actualizar(carritoId, carrito);
            orden.setTotal(new BigDecimal("284.00"));
            ordenService.actualizar(ordenId, orden);

            System.out.println("Actualizaciones ejecutadas.");
        } finally {
            if (ordenId != null) {
                ordenService.eliminar(ordenId);
            }
            if (carritoId != null) {
                carritoService.eliminar(carritoId);
            }
            if (productoId != null) {
                productoService.eliminar(productoId);
            }
            if (clienteId != null) {
                clienteService.eliminar(clienteId);
            }
            System.out.println("Limpieza final ejecutada.");
            context.close();
        }
    }
}

