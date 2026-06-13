output "crear_orden_funcion_arn" {
  description = "ARN de la función para crear ordenes"
  value       = aws_lambda_function.crear_orden.arn
}
output "crear_orden_funcion_name" {
  description = "Nombre de la función Lambda para crear ordenes"
  value       = aws_lambda_function.crear_orden.function_name
}

output "merger_funcion_arn" {
  description = "ARN de la Lambda merger de sincronizacion"
  value       = aws_lambda_function.merger_sync.arn
}

output "ventas_sync_queue_arn" {
  description = "ARN de la cola de sincronizacion de ventas"
  value       = aws_sqs_queue.ventas_sync_queue.arn
}

output "logistica_sync_queue_arn" {
  description = "ARN de la cola de sincronizacion de logistica"
  value       = aws_sqs_queue.logistica_sync_queue.arn
}

output "ventas_sync_queue_url" {
  description = "URL de la cola de sincronizacion de ventas"
  value       = aws_sqs_queue.ventas_sync_queue.url
}

output "logistica_sync_queue_url" {
  description = "URL de la cola de sincronizacion de logistica"
  value       = aws_sqs_queue.logistica_sync_queue.url
}
