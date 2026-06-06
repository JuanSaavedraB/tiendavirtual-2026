import { EventBridgeEvent } from 'aws-lambda';

export const handler = async (
  event: EventBridgeEvent<string, any>
): Promise<void> => {
  const baseUrl = process.env.URL_BASE_SERVICIO;

  if (!baseUrl) {
    console.error('SERVICE_BASE_URL no está definida en las variables de entorno.');
    return;
  }

  console.log('Evento Recibido:', JSON.stringify(event, null, 2));

  const detail = event.detail ?? {};
  const detalleTipo = event['detail-type'];
  const metodo = detalleTipo === 'actualizar-orden' ? 'PUT' : 'POST';

  const endpoint = (() => {
    if (metodo !== 'PUT') {
      return `${baseUrl}/ordenes`;
    }

    const idDesdeRuta = event.resources?.[0]?.split('/')[0];
    const idDesdeBody =
      detail.id ??
      detail.idOrden ??
      detail.ordenId;
    const idOrden = idDesdeRuta ?? idDesdeBody;

    if (!idOrden) {
      console.error('No se encontró el id de orden para actualizar.');
      return null;
    }

    return `${baseUrl}/ordenes/${idOrden}`;
  })();

  if (!endpoint) {
    return;
  }

  try {
    const response = await fetch(endpoint, {
      method: metodo,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(detail),
    });

    const responseBodyText = await response.text();
    console.log('Respuesta API:', responseBodyText);
  } catch (error) {
    console.error('No se pudo llamar al servicio ECS:', error);
  }
};
