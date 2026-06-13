SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

USE logistica;

TRUNCATE TABLE PRODUCTO;

INSERT INTO PRODUCTO (id, codigo, nombre, descripcion, precio, stock) VALUES
	(1, 'PROD000001', 'Laptop ASUS X515', 'Laptop 14 pulg i5 8GB 512GB SSD', 799.99, 15),
	(2, 'PROD000002', 'Samsung Galaxy S23', 'Telefono 128GB 8GB RAM camara 50MP', 699.99, 10),
	(3, 'PROD000003', 'Auriculares Sony XM5', 'Cancelacion de ruido premium', 349.99, 20),
	(4, 'PROD000004', 'Apple iPad Air', 'Tableta 10.9 pulg WiFi 64GB', 599.99, 12),
	(5, 'PROD000005', 'Mouse Logitech MX3', 'Mouse inalambrico ergonomico', 99.99, 25);

USE ventas;

TRUNCATE TABLE ITEMORDEN;
TRUNCATE TABLE ITEMCARRITO;
TRUNCATE TABLE ORDEN;
TRUNCATE TABLE CARRITO;
TRUNCATE TABLE CLIENTE;

INSERT INTO CLIENTE (id, dni, nombre, apellidos) VALUES
	(1, '12345678', 'Juan', 'Perez Lopez'),
	(2, '23456789', 'Maria', 'Gonzalez Rodriguez'),
	(3, '34567890', 'Carlos', 'Martinez Sanchez'),
	(4, '45678901', 'Ana', 'Hernandez Fernandez'),
	(5, '56789012', 'Pedro', 'Diaz Ramirez');

INSERT INTO CARRITO (id, idCliente, nombre, fecha) VALUES
	(1, 1, 'Carrito Juan', '2026-05-01'),
	(2, 2, 'Carrito Maria', '2026-05-02'),
	(3, 3, 'Carrito Carlos', '2026-05-03'),
	(4, 4, 'Carrito Ana', '2026-05-04'),
	(5, 5, 'Carrito Pedro', '2026-05-05');

INSERT INTO ITEMCARRITO (id, idCarrito, codigoProducto, cantidad, subTotal) VALUES
	(1, 1, 'PROD000001', 1, 799.99),
	(2, 1, 'PROD000005', 2, 199.98),
	(3, 2, 'PROD000002', 1, 699.99),
	(4, 3, 'PROD000004', 1, 599.99),
	(5, 4, 'PROD000003', 1, 349.99),
	(6, 5, 'PROD000005', 1, 99.99);

INSERT INTO ORDEN (id, numero, idCarrito, fecha, subTotal, igv, total) VALUES
	(1, 'ORD0000001', 1, '2026-05-01', 999.97, 180.00, 1179.97),
	(2, 'ORD0000002', 2, '2026-05-02', 699.99, 126.00, 825.99),
	(3, 'ORD0000003', 3, '2026-05-03', 599.99, 108.00, 707.99),
	(4, 'ORD0000004', 4, '2026-05-04', 349.99, 63.00, 412.99),
	(5, 'ORD0000005', 5, '2026-05-05', 99.99, 18.00, 117.99);

INSERT INTO ITEMORDEN (id, idOrden, codigoProducto, cantidad, subTotal) VALUES
	(1, 1, 'PROD000001', 1, 799.99),
	(2, 1, 'PROD000005', 2, 199.98),
	(3, 2, 'PROD000002', 1, 699.99),
	(4, 3, 'PROD000004', 1, 599.99),
	(5, 4, 'PROD000003', 1, 349.99),
	(6, 5, 'PROD000005', 1, 99.99);

USE tiendavirtual;

TRUNCATE TABLE ITEMORDEN;
TRUNCATE TABLE ITEMCARRITO;
TRUNCATE TABLE ORDEN;
TRUNCATE TABLE CARRITO;
TRUNCATE TABLE PRODUCTO;
TRUNCATE TABLE CLIENTE;

INSERT INTO CLIENTE (id, dni, nombre, apellidos)
SELECT id, dni, nombre, apellidos FROM ventas.CLIENTE;

INSERT INTO PRODUCTO (id, codigo, nombre, descripcion, precio, stock)
SELECT id, codigo, nombre, descripcion, precio, stock FROM logistica.PRODUCTO;

INSERT INTO CARRITO (id, idCliente, nombre, fecha)
SELECT id, idCliente, nombre, fecha FROM ventas.CARRITO;

INSERT INTO ITEMCARRITO (id, idCarrito, codigoProducto, cantidad, subTotal)
SELECT id, idCarrito, codigoProducto, cantidad, subTotal FROM ventas.ITEMCARRITO;

INSERT INTO ORDEN (id, numero, idCarrito, fecha, subTotal, igv, total)
SELECT id, numero, idCarrito, fecha, subTotal, igv, total FROM ventas.ORDEN;

INSERT INTO ITEMORDEN (id, idOrden, codigoProducto, cantidad, subTotal)
SELECT id, idOrden, codigoProducto, cantidad, subTotal FROM ventas.ITEMORDEN;

SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;
