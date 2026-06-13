output "nombre_cluster" {
  value = aws_ecs_cluster.cluster_tienda_virtual_servicios.name
}

output "task_definition_ventas_arn" {
  value = aws_ecs_task_definition.definicion_tarea_ventas.arn
}

output "task_definition_logistica_arn" {
  value = aws_ecs_task_definition.definicion_tarea_logistica.arn
}

output "load_balancer_url" {
  description = "URL pública del Load Balancer"
  value       = aws_lb.tienda_virtual_load_balancer.dns_name
}
