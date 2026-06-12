output "nombre_cluster" {
  value = aws_ecs_cluster.cluster_tienda_virtual_servicios.name
}

output "task_definition_arn" {
  value = aws_ecs_cluster.cluster_tienda_virtual_servicios.arn
}

output "load_balancer_url" {
  description = "URL pública del Load Balancer"
  value       = aws_lb.tienda_virtual_load_balancer.dns_name
}

output "vpc_id" {
  description = "VPC usada por ECS, ALB y Target Group"
  value       = local.vpc_id_seleccionada
}

output "alb_subnet_ids" {
  description = "Subnets usadas por el ALB"
  value       = local.subnet_ids_alb
}

output "alb_availability_zones" {
  description = "Availability Zones de las subnets usadas por el ALB"
  value       = local.alb_availability_zones
}

output "created_additional_public_subnet_for_alb" {
  description = "Indica si Terraform creó una subnet pública adicional para el ALB"
  value       = local.create_additional_public_subnet_for_alb
}

output "additional_public_subnet_id" {
  description = "ID de la subnet pública adicional creada para el ALB, si aplica"
  value       = local.create_additional_public_subnet_for_alb ? aws_subnet.subnet_publica_adicional_alb[0].id : null
}
