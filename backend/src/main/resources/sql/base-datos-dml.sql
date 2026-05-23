USE TiendaVirtual;

SET @OLD_SQL_SAFE_UPDATES = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM ITEMORDEN;
DELETE FROM ITEMCARRITO;
DELETE FROM ORDEN;
DELETE FROM CARRITO;
DELETE FROM PRODUCTO;
DELETE FROM CLIENTE;

INSERT INTO CLIENTE (id, dni, nombre, apellidos) VALUES
	(1, '12345678', 'Juan', 'Perez Lopez'),
	(2, '23456789', 'Maria', 'Gonzalez Rodriguez'),
	(3, '34567890', 'Carlos', 'Martinez Sanchez'),
	(4, '45678901', 'Ana', 'Hernandez Fernandez'),
	(5, '56789012', 'Pedro', 'Diaz Ramirez');

INSERT INTO PRODUCTO (id, codigo, nombre, descripcion, precio, stock) VALUES
	(1, 'PROD000001', 'Laptop ASUS X515', 'Laptop 14 pulg i5 8GB 512GB SSD', 799.99, 15),
	(2, 'PROD000002', 'Samsung Galaxy S23', 'Telefono 128GB 8GB RAM camara 50MP', 699.99, 10),
	(3, 'PROD000003', 'Auriculares Sony XM5', 'Cancelacion de ruido premium', 349.99, 20),
	(4, 'PROD000004', 'Apple iPad Air', 'Tableta 10.9 pulg WiFi 64GB', 599.99, 12),
	(5, 'PROD000005', 'Mouse Logitech MX3', 'Mouse inalambrico ergonomico', 99.99, 25);

INSERT INTO CARRITO (id, idCliente, nombre, fecha) VALUES
	(1, 1, 'Carrito Juan', '2026-05-01'),
	(2, 2, 'Carrito Maria', '2026-05-02'),
	(3, 3, 'Carrito Carlos', '2026-05-03'),
	(4, 4, 'Carrito Ana', '2026-05-04'),
	(5, 5, 'Carrito Pedro', '2026-05-05');

INSERT INTO ITEMCARRITO (id, idCarrito, idProducto, cantidad, subTotal) VALUES
	(1, 1, 1, 1, 799.99),
	(2, 1, 5, 2, 199.98),
	(3, 2, 2, 1, 999.99),
	(4, 3, 4, 1, 599.99),
	(5, 4, 3, 1, 349.99),
	(6, 5, 5, 1, 99.99);

INSERT INTO ORDEN (id, numero, idCarrito, fecha, subTotal, igv, total) VALUES
	(1, 'ORD0000001', 1, '2026-05-01', 799.99, 144.00, 943.99),
	(2, 'ORD0000002', 2, '2026-05-02', 899.97, 99.99, 999.96),
	(3, 'ORD0000003', 3, '2026-05-03', 599.99, 108.00, 707.99),
	(4, 'ORD0000004', 4, '2026-05-04', 349.99, 63.00, 412.99),
	(5, 'ORD0000005', 5, '2026-05-05', 99.99, 18.00, 117.99);

INSERT INTO ITEMORDEN (id, idOrden, idProducto, cantidad, subTotal) VALUES
	(1, 1, 1, 1, 799.99),
	(2, 2, 5, 2, 199.98),
	(3, 2, 2, 1, 699.99),
	(4, 3, 4, 1, 599.99),
	(5, 4, 3, 1, 349.99),
	(6, 5, 5, 1, 99.99);

SET SQL_SAFE_UPDATES = @OLD_SQL_SAFE_UPDATES;
