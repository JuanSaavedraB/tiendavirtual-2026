output "vpc_id" {
  description = "ID de la VPC default usada por el laboratorio."
  value       = data.aws_vpc.vpc_por_defecto.id
}

output "vpc_cidr_block" {
  description = "CIDR de la VPC default usada por el laboratorio."
  value       = data.aws_vpc.vpc_por_defecto.cidr_block
}

output "default_security_group_id" {
  description = "Security group default de la VPC."
  value       = data.aws_security_group.grupo_seguridad_por_defecto.id
}

output "public_subnet_ids" {
  description = "Subnets publicas finales compartidas por ALB, ECS y RDS."
  value       = local.public_subnet_ids
}

output "public_subnet_availability_zones" {
  description = "AZs finales cubiertas por las subnets publicas."
  value       = local.public_subnet_availability_zones
}

output "created_additional_public_subnet_for_lab" {
  description = "Indica si Terraform administra una subnet publica adicional para el Learner Lab."
  value       = length(aws_subnet.additional_public_subnet_for_lab) > 0
}

output "additional_public_subnet_id" {
  description = "ID de la subnet adicional creada o reutilizada en la AZ configurada."
  value       = length(local.additional_public_subnet_ids) > 0 ? local.additional_public_subnet_ids[0] : null
}
