data "archive_file" "archivo_crear_orden_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../serverless/tiendavirtual/packages/funciones/crear-orden/build"
  output_path = "${path.root}/data/crear_orden_lambda.zip"
}

data "archive_file" "archivo_merger_lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../serverless/tiendavirtual/packages/funciones/merger/build"
  output_path = "${path.root}/data/merger_lambda.zip"
}

locals {
  ventas_sync_queue_name    = endswith(var.nombre_cola_sync_ventas, ".fifo") ? var.nombre_cola_sync_ventas : "${var.nombre_cola_sync_ventas}.fifo"
  ventas_sync_dlq_name      = endswith(var.nombre_cola_sync_ventas, ".fifo") ? "${trimsuffix(var.nombre_cola_sync_ventas, ".fifo")}-dlq.fifo" : "${var.nombre_cola_sync_ventas}-dlq.fifo"
  logistica_sync_queue_name = endswith(var.nombre_cola_sync_logistica, ".fifo") ? var.nombre_cola_sync_logistica : "${var.nombre_cola_sync_logistica}.fifo"
  logistica_sync_dlq_name   = endswith(var.nombre_cola_sync_logistica, ".fifo") ? "${trimsuffix(var.nombre_cola_sync_logistica, ".fifo")}-dlq.fifo" : "${var.nombre_cola_sync_logistica}-dlq.fifo"
}

resource "aws_sqs_queue" "ventas_sync_dlq" {
  name       = local.ventas_sync_dlq_name
  fifo_queue = true
}

resource "aws_sqs_queue" "logistica_sync_dlq" {
  name       = local.logistica_sync_dlq_name
  fifo_queue = true
}

resource "aws_sqs_queue" "ventas_sync_queue" {
  name                       = local.ventas_sync_queue_name
  fifo_queue                 = true
  deduplication_scope        = "messageGroup"
  fifo_throughput_limit      = "perMessageGroupId"
  visibility_timeout_seconds = 120
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ventas_sync_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "logistica_sync_queue" {
  name                       = local.logistica_sync_queue_name
  fifo_queue                 = true
  deduplication_scope        = "messageGroup"
  fifo_throughput_limit      = "perMessageGroupId"
  visibility_timeout_seconds = 120
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.logistica_sync_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "ventas_sync_queue_policy" {
  queue_url = aws_sqs_queue.ventas_sync_queue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PermitirLabRoleVentas",
        Effect    = "Allow",
        Principal = { AWS = var.rol_lambda_arn },
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = aws_sqs_queue.ventas_sync_queue.arn
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "logistica_sync_queue_policy" {
  queue_url = aws_sqs_queue.logistica_sync_queue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PermitirLabRoleLogistica",
        Effect    = "Allow",
        Principal = { AWS = var.rol_lambda_arn },
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = aws_sqs_queue.logistica_sync_queue.arn
      }
    ]
  })
}

resource "aws_lambda_function" "crear_orden" {
  function_name    = "crear-orden"
  handler          = "index.handler"
  runtime          = var.entorno_ejecucion
  role             = var.rol_lambda_arn
  filename         = data.archive_file.archivo_crear_orden_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.archivo_crear_orden_lambda.output_path)
  timeout          = 60
  memory_size      = 512
  environment {
    variables = {
      URL_BASE_SERVICIO = var.url_base_servicio
    }
  }
}

resource "aws_lambda_function" "merger_sync" {
  function_name    = "merger-sync-tiendavirtual"
  handler          = "index.handler"
  runtime          = var.entorno_ejecucion
  role             = var.rol_lambda_arn
  filename         = data.archive_file.archivo_merger_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.archivo_merger_lambda.output_path)
  timeout          = 60
  memory_size      = 512
  environment {
    variables = {
      DB_HOST     = var.host_base_datos
      DB_PORT     = tostring(var.puerto_base_datos)
      DB_USER     = var.usuario_base_datos
      DB_PASSWORD = var.contrasenha_base_datos
      DB_SCHEMA   = var.esquema_tiendavirtual
    }
  }
}

resource "aws_lambda_event_source_mapping" "merger_desde_ventas" {
  event_source_arn = aws_sqs_queue.ventas_sync_queue.arn
  function_name    = aws_lambda_function.merger_sync.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "merger_desde_logistica" {
  event_source_arn = aws_sqs_queue.logistica_sync_queue.arn
  function_name    = aws_lambda_function.merger_sync.arn
  batch_size       = 10
}
