import { SQSEvent, SQSRecord } from 'aws-lambda';
import mysql from 'mysql2/promise';

type SyncMessage = {
  entity: string;
  operation: 'upsert' | 'delete' | 'delete_by_carrito' | 'delete_by_orden';
  payload: Record<string, unknown>;
};

const requiredEnv = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_SCHEMA'] as const;

for (const envName of requiredEnv) {
  if (!process.env[envName]) {
    throw new Error(`Falta variable de entorno requerida: ${envName}`);
  }
}

const pool = mysql.createPool({
  host: process.env.DB_HOST!,
  port: Number(process.env.DB_PORT!),
  user: process.env.DB_USER!,
  password: process.env.DB_PASSWORD!,
  database: process.env.DB_SCHEMA!,
  waitForConnections: true,
  connectionLimit: 4,
});

const toNumber = (value: unknown): number => {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.trim() !== '' && !Number.isNaN(Number(value))) {
    return Number(value);
  }
  throw new Error('El valor no es numerico');
};

const processProductoMessage = async (message: SyncMessage): Promise<void> => {
  const id = toNumber(message.payload.id);
  if (message.operation === 'delete') {
    await pool.query('DELETE FROM PRODUCTO WHERE id = ?', [id]);
    return;
  }

  const codigo = String(message.payload.codigo ?? '');
  const nombre = String(message.payload.nombre ?? '');
  const descripcion = String(message.payload.descripcion ?? '');
  const precio = Number(message.payload.precio ?? 0);
  const stock = toNumber(message.payload.stock ?? 0);

  if (!codigo || !nombre || !descripcion) {
    throw new Error('Mensaje de producto invalido: faltan datos obligatorios');
  }

  await pool.query(
    `INSERT INTO PRODUCTO (id, codigo, nombre, descripcion, precio, stock)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       codigo = VALUES(codigo),
       nombre = VALUES(nombre),
       descripcion = VALUES(descripcion),
       precio = VALUES(precio),
       stock = VALUES(stock)`,
    [id, codigo, nombre, descripcion, precio, stock]
  );
};

const toStringValue = (value: unknown): string => {
  if (typeof value === 'string' && value.trim() !== '') {
    return value;
  }
  throw new Error('El valor no es texto valido');
};

const processClienteMessage = async (message: SyncMessage): Promise<void> => {
  const id = toNumber(message.payload.id);
  if (message.operation === 'delete') {
    await pool.query('DELETE FROM CLIENTE WHERE id = ?', [id]);
    return;
  }

  const dni = toStringValue(message.payload.dni);
  const nombre = toStringValue(message.payload.nombre);
  const apellidos = toStringValue(message.payload.apellidos);

  await pool.query(
    `INSERT INTO CLIENTE (id, dni, nombre, apellidos)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       dni = VALUES(dni),
       nombre = VALUES(nombre),
       apellidos = VALUES(apellidos)`,
    [id, dni, nombre, apellidos]
  );
};

const processCarritoMessage = async (message: SyncMessage): Promise<void> => {
  if (message.operation === 'delete') {
    const id = toNumber(message.payload.id);
    await pool.query('DELETE FROM ITEMCARRITO WHERE idCarrito = ?', [id]);
    await pool.query('DELETE FROM CARRITO WHERE id = ?', [id]);
    return;
  }

  if (message.operation !== 'upsert') {
    throw new Error(`Operacion no soportada para carrito: ${message.operation}`);
  }

  const id = toNumber(message.payload.id);
  const idCliente = toNumber(message.payload.idCliente);
  const nombre = toStringValue(message.payload.nombre);
  const fecha = toStringValue(message.payload.fecha);

  await pool.query(
    `INSERT INTO CARRITO (id, idCliente, nombre, fecha)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       idCliente = VALUES(idCliente),
       nombre = VALUES(nombre),
       fecha = VALUES(fecha)`,
    [id, idCliente, nombre, fecha]
  );
};

const processItemCarritoMessage = async (message: SyncMessage): Promise<void> => {
  if (message.operation === 'delete') {
    const id = toNumber(message.payload.id);
    await pool.query('DELETE FROM ITEMCARRITO WHERE id = ?', [id]);
    return;
  }

  if (message.operation === 'delete_by_carrito') {
    const idCarrito = toNumber(message.payload.idCarrito);
    await pool.query('DELETE FROM ITEMCARRITO WHERE idCarrito = ?', [idCarrito]);
    return;
  }

  const id = toNumber(message.payload.id);
  const idCarrito = toNumber(message.payload.idCarrito);
  const codigoProducto = toStringValue(message.payload.codigoProducto);
  const cantidad = toNumber(message.payload.cantidad);
  const subTotal = Number(message.payload.subTotal ?? 0);

  await pool.query(
    `INSERT INTO ITEMCARRITO (id, idCarrito, codigoProducto, cantidad, subTotal)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       idCarrito = VALUES(idCarrito),
       codigoProducto = VALUES(codigoProducto),
       cantidad = VALUES(cantidad),
       subTotal = VALUES(subTotal)`,
    [id, idCarrito, codigoProducto, cantidad, subTotal]
  );
};

const processOrdenMessage = async (message: SyncMessage): Promise<void> => {
  if (message.operation === 'delete') {
    const id = toNumber(message.payload.id);
    await pool.query('DELETE FROM ITEMORDEN WHERE idOrden = ?', [id]);
    await pool.query('DELETE FROM ORDEN WHERE id = ?', [id]);
    return;
  }

  if (message.operation !== 'upsert') {
    throw new Error(`Operacion no soportada para orden: ${message.operation}`);
  }

  const id = toNumber(message.payload.id);
  const numero = toStringValue(message.payload.numero);
  const idCarrito = toNumber(message.payload.idCarrito);
  const fecha = toStringValue(message.payload.fecha);
  const subTotal = Number(message.payload.subTotal ?? 0);
  const igv = Number(message.payload.igv ?? 0);
  const total = Number(message.payload.total ?? 0);

  await pool.query(
    `INSERT INTO ORDEN (id, numero, idCarrito, fecha, subTotal, igv, total)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       numero = VALUES(numero),
       idCarrito = VALUES(idCarrito),
       fecha = VALUES(fecha),
       subTotal = VALUES(subTotal),
       igv = VALUES(igv),
       total = VALUES(total)`,
    [id, numero, idCarrito, fecha, subTotal, igv, total]
  );
};

const processItemOrdenMessage = async (message: SyncMessage): Promise<void> => {
  if (message.operation === 'delete') {
    const id = toNumber(message.payload.id);
    await pool.query('DELETE FROM ITEMORDEN WHERE id = ?', [id]);
    return;
  }

  if (message.operation === 'delete_by_orden') {
    const idOrden = toNumber(message.payload.idOrden);
    await pool.query('DELETE FROM ITEMORDEN WHERE idOrden = ?', [idOrden]);
    return;
  }

  const id = toNumber(message.payload.id);
  const idOrden = toNumber(message.payload.idOrden);
  const codigoProducto = toStringValue(message.payload.codigoProducto);
  const cantidad = toNumber(message.payload.cantidad);
  const subTotal = Number(message.payload.subTotal ?? 0);

  await pool.query(
    `INSERT INTO ITEMORDEN (id, idOrden, codigoProducto, cantidad, subTotal)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       idOrden = VALUES(idOrden),
       codigoProducto = VALUES(codigoProducto),
       cantidad = VALUES(cantidad),
       subTotal = VALUES(subTotal)`,
    [id, idOrden, codigoProducto, cantidad, subTotal]
  );
};

const parseMessage = (record: SQSRecord): SyncMessage => {
  try {
    return JSON.parse(record.body) as SyncMessage;
  } catch (error) {
    throw new Error(`No se pudo parsear mensaje SQS: ${String(error)}`);
  }
};

export const handler = async (event: SQSEvent): Promise<void> => {
  for (const record of event.Records) {
    const message = parseMessage(record);
    const entity = message.entity.toLowerCase();

    switch (entity) {
      case 'producto':
        await processProductoMessage(message);
        break;
      case 'cliente':
        await processClienteMessage(message);
        break;
      case 'carrito':
        await processCarritoMessage(message);
        break;
      case 'itemcarrito':
        await processItemCarritoMessage(message);
        break;
      case 'orden':
        await processOrdenMessage(message);
        break;
      case 'itemorden':
        await processItemOrdenMessage(message);
        break;
      default:
        console.warn(`Entidad no soportada por merger: ${message.entity}`);
    }
  }
};
