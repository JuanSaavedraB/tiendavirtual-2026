package pe.edu.pucp.tiendavirtual.console;

import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import pe.edu.pucp.tiendavirtual.modelo.Producto;
import pe.edu.pucp.tiendavirtual.modelo.Carrito;
import pe.edu.pucp.tiendavirtual.modelo.Cliente;
import pe.edu.pucp.tiendavirtual.modelo.Orden;
import pe.edu.pucp.tiendavirtual.service.CarritoService;
import pe.edu.pucp.tiendavirtual.service.ClienteService;
import pe.edu.pucp.tiendavirtual.service.OrdenService;
import pe.edu.pucp.tiendavirtual.service.ProductoService;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Optional;
import java.util.Scanner;

public class App {
    public static void main(String[] args) {
        ConfigurableApplicationContext context = new SpringApplicationBuilder(pe.edu.pucp.tiendavirtual.app.App.class)
                .web(WebApplicationType.NONE)
                .run(args);

        ClienteService clienteService = context.getBean(ClienteService.class);
        ProductoService productoService = context.getBean(ProductoService.class);
        CarritoService carritoService = context.getBean(CarritoService.class);
        OrdenService ordenService = context.getBean(OrdenService.class);

        ejecutarMenu(
                clienteService,
                productoService,
                carritoService,
                ordenService
        );
        context.close();
    }

    private static void ejecutarMenu(
            ClienteService clienteService,
            ProductoService productoService,
            CarritoService carritoService,
            OrdenService ordenService
    ) {
        Scanner scanner = new Scanner(System.in);

        while (true) {
            System.out.println("\n=== Consola de Servicios Tienda Virtual ===");
            System.out.println("1) ClienteService");
            System.out.println("2) ProductoService");
            System.out.println("3) CarritoService");
            System.out.println("4) OrdenService");
            System.out.println("0) Salir");
            System.out.print("Opcion: ");

            String opcion = scanner.nextLine().trim();
            switch (opcion) {
                case "1" -> menuCliente(scanner, clienteService);
                case "2" -> menuProducto(scanner, productoService);
                case "3" -> menuCarrito(scanner, carritoService, clienteService);
                case "4" -> menuOrden(scanner, ordenService, carritoService);
                case "0" -> {
                    System.out.println("Saliendo de la consola.");
                    return;
                }
                default -> System.out.println("Opcion invalida.");
            }
        }
    }

    private static void menuCliente(Scanner scanner, ClienteService service) {
        while (true) {
            System.out.println("\n--- ClienteService ---");
            System.out.println("1) Listar");
            System.out.println("2) Obtener por id");
            System.out.println("3) Crear");
            System.out.println("4) Actualizar");
            System.out.println("5) Eliminar");
            System.out.println("6) Buscar por DNI");
            System.out.println("0) Volver");
            String op = scanner.nextLine().trim();

            switch (op) {
                case "1" -> service.listar().forEach(c ->
                        System.out.printf("id=%d, dni=%s, nombre=%s %s%n", c.getId(), c.getDni(), c.getNombre(), c.getApellidos()));
                case "2" -> {
                    Integer id = leerEntero(scanner, "Id: ");
                    service.obtenerPorId(id).ifPresentOrElse(
                            c -> System.out.printf("id=%d, dni=%s, nombre=%s %s%n", c.getId(), c.getDni(), c.getNombre(), c.getApellidos()),
                            () -> System.out.println("Cliente no encontrado."));
                }
                case "3" -> {
                    Cliente c = new Cliente();
                    c.setDni(leerTexto(scanner, "DNI: "));
                    c.setNombre(leerTexto(scanner, "Nombre: "));
                    c.setApellidos(leerTexto(scanner, "Apellidos: "));
                    Cliente creado = service.crear(c);
                    System.out.println("Creado con id=" + creado.getId());
                }
                case "4" -> {
                    Integer id = leerEntero(scanner, "Id a actualizar: ");
                    Cliente c = new Cliente();
                    c.setDni(leerTexto(scanner, "DNI: "));
                    c.setNombre(leerTexto(scanner, "Nombre: "));
                    c.setApellidos(leerTexto(scanner, "Apellidos: "));
                    boolean actualizado = service.actualizar(id, c).isPresent();
                    System.out.println(actualizado ? "Actualizado." : "Cliente no encontrado.");
                }
                case "5" -> {
                    Integer id = leerEntero(scanner, "Id a eliminar: ");
                    System.out.println(service.eliminar(id) ? "Eliminado." : "Cliente no encontrado.");
                }
                case "6" -> {
                    String dni = leerTexto(scanner, "DNI: ");
                    service.buscarPorDni(dni).ifPresentOrElse(
                            c -> System.out.printf("id=%d, dni=%s, nombre=%s %s%n", c.getId(), c.getDni(), c.getNombre(), c.getApellidos()),
                            () -> System.out.println("Cliente no encontrado."));
                }
                case "0" -> {
                    return;
                }
                default -> System.out.println("Opcion invalida.");
            }
        }
    }

    private static void menuProducto(Scanner scanner, ProductoService service) {
        while (true) {
            System.out.println("\n--- ProductoService ---");
            System.out.println("1) Listar");
            System.out.println("2) Obtener por id");
            System.out.println("3) Crear");
            System.out.println("4) Actualizar");
            System.out.println("5) Eliminar");
            System.out.println("0) Volver");
            String op = scanner.nextLine().trim();

            switch (op) {
                case "1" -> service.listar().forEach(p ->
                        System.out.printf("id=%d, codigo=%s, nombre=%s, precio=%s, stock=%d%n",
                                p.getId(), p.getCodigo(), p.getNombre(), p.getPrecio(), p.getStock()));
                case "2" -> {
                    Integer id = leerEntero(scanner, "Id: ");
                    service.obtenerPorId(id).ifPresentOrElse(
                            p -> System.out.printf("id=%d, codigo=%s, nombre=%s, descripcion=%s, precio=%s, stock=%d%n",
                                    p.getId(), p.getCodigo(), p.getNombre(), p.getDescripcion(), p.getPrecio(), p.getStock()),
                            () -> System.out.println("Producto no encontrado."));
                }
                case "3" -> {
                    Producto p = new Producto();
                    p.setCodigo(leerTexto(scanner, "Codigo: "));
                    p.setNombre(leerTexto(scanner, "Nombre: "));
                    p.setDescripcion(leerTexto(scanner, "Descripcion: "));
                    p.setPrecio(leerDecimal(scanner, "Precio: "));
                    p.setStock(leerEntero(scanner, "Stock: "));
                    Producto creado = service.crear(p);
                    System.out.println("Creado con id=" + creado.getId());
                }
                case "4" -> {
                    Integer id = leerEntero(scanner, "Id a actualizar: ");
                    Producto p = new Producto();
                    p.setCodigo(leerTexto(scanner, "Codigo: "));
                    p.setNombre(leerTexto(scanner, "Nombre: "));
                    p.setDescripcion(leerTexto(scanner, "Descripcion: "));
                    p.setPrecio(leerDecimal(scanner, "Precio: "));
                    p.setStock(leerEntero(scanner, "Stock: "));
                    boolean actualizado = service.actualizar(id, p).isPresent();
                    System.out.println(actualizado ? "Actualizado." : "Producto no encontrado.");
                }
                case "5" -> {
                    Integer id = leerEntero(scanner, "Id a eliminar: ");
                    System.out.println(service.eliminar(id) ? "Eliminado." : "Producto no encontrado.");
                }
                case "0" -> {
                    return;
                }
                default -> System.out.println("Opcion invalida.");
            }
        }
    }

    private static void menuCarrito(Scanner scanner, CarritoService service, ClienteService clienteService) {
        while (true) {
            System.out.println("\n--- CarritoService ---");
            System.out.println("1) Listar");
            System.out.println("2) Obtener por id");
            System.out.println("3) Crear");
            System.out.println("4) Actualizar");
            System.out.println("5) Eliminar");
            System.out.println("6) Buscar por DNI de cliente");
            System.out.println("0) Volver");
            String op = scanner.nextLine().trim();

            switch (op) {
                case "1" -> service.listar().forEach(c ->
                        System.out.printf("id=%d, nombre=%s, fecha=%s%n", c.getId(), c.getNombre(), c.getFecha()));
                case "2" -> {
                    Integer id = leerEntero(scanner, "Id: ");
                    service.obtenerPorId(id).ifPresentOrElse(
                            c -> System.out.printf("id=%d, nombre=%s, fecha=%s%n", c.getId(), c.getNombre(), c.getFecha()),
                            () -> System.out.println("Carrito no encontrado."));
                }
                case "3" -> {
                    Integer idCliente = leerEntero(scanner, "Id cliente: ");
                    Optional<Cliente> cliente = clienteService.obtenerPorId(idCliente);
                    if (cliente.isEmpty()) {
                        System.out.println("Cliente no encontrado.");
                        break;
                    }
                    Carrito carrito = new Carrito();
                    carrito.setNombre(leerTexto(scanner, "Nombre: "));
                    carrito.setFecha(leerFecha(scanner, "Fecha (YYYY-MM-DD): "));
                    carrito.setCliente(cliente.get());
                    Carrito creado = service.crear(carrito);
                    System.out.println("Creado con id=" + creado.getId());
                }
                case "4" -> {
                    Integer id = leerEntero(scanner, "Id carrito: ");
                    Integer idCliente = leerEntero(scanner, "Id cliente: ");
                    Optional<Cliente> cliente = clienteService.obtenerPorId(idCliente);
                    if (cliente.isEmpty()) {
                        System.out.println("Cliente no encontrado.");
                        break;
                    }
                    Carrito carrito = new Carrito();
                    carrito.setNombre(leerTexto(scanner, "Nombre: "));
                    carrito.setFecha(leerFecha(scanner, "Fecha (YYYY-MM-DD): "));
                    carrito.setCliente(cliente.get());
                    boolean actualizado = service.actualizar(id, carrito).isPresent();
                    System.out.println(actualizado ? "Actualizado." : "Carrito no encontrado.");
                }
                case "5" -> {
                    Integer id = leerEntero(scanner, "Id a eliminar: ");
                    System.out.println(service.eliminar(id) ? "Eliminado." : "Carrito no encontrado.");
                }
                case "6" -> {
                    String dni = leerTexto(scanner, "DNI: ");
                    List<Carrito> carritos = service.buscarPorDniCliente(dni);
                    if (carritos.isEmpty()) {
                        System.out.println("No se encontraron carritos.");
                    } else {
                        carritos.forEach(c -> System.out.printf("id=%d, nombre=%s, fecha=%s%n", c.getId(), c.getNombre(), c.getFecha()));
                    }
                }
                case "0" -> {
                    return;
                }
                default -> System.out.println("Opcion invalida.");
            }
        }
    }

    private static void menuOrden(Scanner scanner, OrdenService service, CarritoService carritoService) {
        while (true) {
            System.out.println("\n--- OrdenService ---");
            System.out.println("1) Listar");
            System.out.println("2) Obtener por id");
            System.out.println("3) Crear");
            System.out.println("4) Actualizar");
            System.out.println("5) Eliminar");
            System.out.println("6) Buscar por DNI de cliente");
            System.out.println("7) Buscar por fecha entre fechas");
            System.out.println("0) Volver");
            String op = scanner.nextLine().trim();

            switch (op) {
                case "1" -> service.listar().forEach(o ->
                        System.out.printf("id=%d, numero=%s, fecha=%s, total=%s%n", o.getId(), o.getNumero(), o.getFecha(), o.getTotal()));
                case "2" -> {
                    Integer id = leerEntero(scanner, "Id: ");
                    service.obtenerPorId(id).ifPresentOrElse(
                            o -> System.out.printf("id=%d, numero=%s, fecha=%s, subTotal=%s, igv=%s, total=%s%n",
                                    o.getId(), o.getNumero(), o.getFecha(), o.getSubTotal(), o.getIgv(), o.getTotal()),
                            () -> System.out.println("Orden no encontrada."));
                }
                case "3" -> {
                    Optional<Orden> orden = construirOrden(scanner, carritoService);
                    orden.ifPresentOrElse(
                            o -> System.out.println("Creada con id=" + service.crear(o).getId()),
                            () -> System.out.println("No se pudo crear por referencias invalidas."));
                }
                case "4" -> {
                    Integer id = leerEntero(scanner, "Id orden: ");
                    Optional<Orden> orden = construirOrden(scanner, carritoService);
                    if (orden.isEmpty()) {
                        System.out.println("No se pudo actualizar por referencias invalidas.");
                        break;
                    }
                    boolean actualizado = service.actualizar(id, orden.get()).isPresent();
                    System.out.println(actualizado ? "Actualizada." : "Orden no encontrada.");
                }
                case "5" -> {
                    Integer id = leerEntero(scanner, "Id a eliminar: ");
                    System.out.println(service.eliminar(id) ? "Eliminada." : "Orden no encontrada.");
                }
                case "6" -> {
                    String dni = leerTexto(scanner, "DNI: ");
                    List<Orden> ordenes = service.buscarPorDniCliente(dni);
                    if (ordenes.isEmpty()) {
                        System.out.println("No se encontraron ordenes.");
                    } else {
                        ordenes.forEach(o -> System.out.printf("id=%d, numero=%s, fecha=%s, total=%s%n",
                                o.getId(), o.getNumero(), o.getFecha(), o.getTotal()));
                    }
                }
                case "7" -> {
                    LocalDate inicio = leerFecha(scanner, "Fecha inicio (YYYY-MM-DD): ");
                    LocalDate fin = leerFecha(scanner, "Fecha fin (YYYY-MM-DD): ");
                    List<Orden> ordenes = service.buscarPorFechaEntre(inicio, fin);
                    if (ordenes.isEmpty()) {
                        System.out.println("No se encontraron ordenes en ese rango.");
                    } else {
                        ordenes.forEach(o -> System.out.printf("id=%d, numero=%s, fecha=%s, total=%s%n",
                                o.getId(), o.getNumero(), o.getFecha(), o.getTotal()));
                    }
                }
                case "0" -> {
                    return;
                }
                default -> System.out.println("Opcion invalida.");
            }
        }
    }

    private static Optional<Orden> construirOrden(Scanner scanner, CarritoService carritoService) {
        Integer idCarrito = leerEntero(scanner, "Id carrito: ");
        Optional<Carrito> carrito = carritoService.obtenerPorId(idCarrito);
        if (carrito.isEmpty()) {
            return Optional.empty();
        }

        Orden orden = new Orden();
        orden.setNumero(leerTexto(scanner, "Numero: "));
        orden.setCarrito(carrito.get());
        orden.setFecha(leerFecha(scanner, "Fecha (YYYY-MM-DD): "));
        orden.setSubTotal(leerDecimal(scanner, "SubTotal: "));
        orden.setIgv(leerDecimal(scanner, "IGV: "));
        orden.setTotal(leerDecimal(scanner, "Total: "));
        return Optional.of(orden);
    }


    private static String leerTexto(Scanner scanner, String mensaje) {
        System.out.print(mensaje);
        return scanner.nextLine().trim();
    }

    private static Integer leerEntero(Scanner scanner, String mensaje) {
        while (true) {
            try {
                System.out.print(mensaje);
                return Integer.parseInt(scanner.nextLine().trim());
            } catch (NumberFormatException ex) {
                System.out.println("Ingresa un numero entero valido.");
            }
        }
    }

    private static BigDecimal leerDecimal(Scanner scanner, String mensaje) {
        while (true) {
            try {
                System.out.print(mensaje);
                return new BigDecimal(scanner.nextLine().trim());
            } catch (NumberFormatException ex) {
                System.out.println("Ingresa un decimal valido.");
            }
        }
    }

    private static LocalDate leerFecha(Scanner scanner, String mensaje) {
        while (true) {
            try {
                System.out.print(mensaje);
                return LocalDate.parse(scanner.nextLine().trim());
            } catch (DateTimeParseException ex) {
                System.out.println("Formato de fecha invalido. Usa YYYY-MM-DD.");
            }
        }
    }
}

