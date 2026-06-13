output "vpc_id" {
  description = "ID de la VPC seleccionada"
  value       = module.networking.vpc_id
}

output "alb_subnet_ids" {
  description = "Subnets usadas por el ALB"
  value       = module.compute.alb_subnet_ids
}

output "alb_availability_zones" {
  description = "AZs usadas por el ALB"
  value       = module.compute.alb_availability_zones
}

output "rds_subnet_group_subnet_ids" {
  description = "Subnets usadas por el DB subnet group de RDS"
  value       = module.database.rds_subnet_group_subnet_ids
}

output "rds_availability_zones" {
  description = "AZs usadas por el DB subnet group de RDS"
  value       = module.database.rds_availability_zones
}

output "created_additional_subnet_for_lab" {
  description = "Indica si Terraform creo una subnet adicional para laboratorio"
  value       = module.networking.created_additional_subnet_for_lab
}

output "additional_subnet_id" {
  description = "ID de la subnet adicional creada para laboratorio"
  value       = module.networking.additional_subnet_id
}
