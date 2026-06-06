locals {
  path_base_servicio_normalizado = length(trim(var.path_base_servicio, "/")) > 0 ? "/${trim(var.path_base_servicio, "/")}" : ""
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "tienda-virtual-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "productos_integration_get_all" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/productos"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "productos_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/productos/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "clientes_integration_get_all" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/clientes"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "clientes_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/clientes/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "carritos_integration_get_all" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/carritos"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "carritos_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/carritos/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "ordenes_integration_get_all" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/ordenes"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "ordenes_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${var.load_balancer_url}${local.path_base_servicio_normalizado}/ordenes/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "eventbridge_integration_crear_orden" {
  api_id              = aws_apigatewayv2_api.http_api.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "EventBridge-PutEvents"
  credentials_arn     = var.rol_lab_arn

  request_parameters = {
    Source       = "pe.com.tiendavirtual"
    DetailType   = "crear-orden"
    Detail       = "$request.body"
    EventBusName = var.event_bus_name
  }

  payload_format_version = "1.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_integration" "eventbridge_integration_actualizar_orden" {
  api_id              = aws_apigatewayv2_api.http_api.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "EventBridge-PutEvents"
  credentials_arn     = var.rol_lab_arn

  request_parameters = {
    Source       = "pe.com.tiendavirtual"
    DetailType   = "actualizar-orden"
    Detail       = "$request.body"
    EventBusName = var.event_bus_name
    Resources    = "$request.path.proxy"
  }

  payload_format_version = "1.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

  route_settings {
    route_key     = "$default"
    logging_level = "INFO"
  }
}

#########################################
# Routes - Ordenes (EventBridge for POST)
#########################################
resource "aws_apigatewayv2_route" "ordenes_post" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST ${local.path_base_servicio_normalizado}/ordenes"
  target    = "integrations/${aws_apigatewayv2_integration.eventbridge_integration_crear_orden.id}"
}

resource "aws_apigatewayv2_route" "ordenes_put" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT ${local.path_base_servicio_normalizado}/ordenes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eventbridge_integration_actualizar_orden.id}"
}

#########################################
# Routes - Clientes
#########################################
resource "aws_apigatewayv2_route" "clientes_get_all" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/clientes"
  target    = "integrations/${aws_apigatewayv2_integration.clientes_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "clientes_get_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/clientes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.clientes_integration.id}"
}

resource "aws_apigatewayv2_route" "clientes_post" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST ${local.path_base_servicio_normalizado}/clientes"
  target    = "integrations/${aws_apigatewayv2_integration.clientes_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "clientes_put_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT ${local.path_base_servicio_normalizado}/clientes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.clientes_integration.id}"
}

resource "aws_apigatewayv2_route" "clientes_delete_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE ${local.path_base_servicio_normalizado}/clientes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.clientes_integration.id}"
}

#########################################
# Routes - Productos
#########################################

resource "aws_apigatewayv2_route" "producto_get_all" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "producto_get_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/productos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.productos_integration.id}"
}

resource "aws_apigatewayv2_route" "producto_post" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST ${local.path_base_servicio_normalizado}/productos"
  target    = "integrations/${aws_apigatewayv2_integration.productos_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "producto_put_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT ${local.path_base_servicio_normalizado}/productos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.productos_integration.id}"
}

resource "aws_apigatewayv2_route" "producto_delete_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE ${local.path_base_servicio_normalizado}/productos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.productos_integration.id}"
}

#########################################
# Routes - Carritos
#########################################
resource "aws_apigatewayv2_route" "carritos_get_all" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/carritos"
  target    = "integrations/${aws_apigatewayv2_integration.carritos_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "carritos_get_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/carritos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.carritos_integration.id}"
}

resource "aws_apigatewayv2_route" "carritos_post" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST ${local.path_base_servicio_normalizado}/carritos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.carritos_integration.id}"
}

resource "aws_apigatewayv2_route" "carritos_put_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT ${local.path_base_servicio_normalizado}/carritos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.carritos_integration.id}"
}

resource "aws_apigatewayv2_route" "carritos_delete_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE ${local.path_base_servicio_normalizado}/carritos/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.carritos_integration.id}"
}

#########################################
# Routes - Ordenes
#########################################
resource "aws_apigatewayv2_route" "ordenes_get_all" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/ordenes"
  target    = "integrations/${aws_apigatewayv2_integration.ordenes_integration_get_all.id}"
}

resource "aws_apigatewayv2_route" "ordenes_get_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET ${local.path_base_servicio_normalizado}/ordenes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ordenes_integration.id}"
}

resource "aws_apigatewayv2_route" "ordenes_delete_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE ${local.path_base_servicio_normalizado}/ordenes/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ordenes_integration.id}"
}
