output "vpc_id" {
  description = "ID de la VPC default seleccionada"
  value       = data.aws_vpc.vpc_por_defecto.id
}

output "vpc_cidr_block" {
  description = "CIDR de la VPC default seleccionada"
  value       = data.aws_vpc.vpc_por_defecto.cidr_block
}

output "public_subnet_ids" {
  description = "Subnets publicas compartidas por ALB, ECS y RDS, con cobertura de al menos 2 AZs"
  value       = local.shared_public_subnet_ids
  depends_on  = [terraform_data.validar_cobertura_subnets]
}

output "public_subnet_availability_zones" {
  description = "AZs cubiertas por las subnets compartidas"
  value       = local.shared_public_subnet_availability_zones
}

output "created_additional_subnet_for_lab" {
  description = "Indica si Terraform creara una subnet publica adicional para laboratorio"
  value       = local.create_additional_public_subnet
}

output "additional_subnet_id" {
  description = "ID de la subnet adicional creada para laboratorio, si aplica"
  value       = try(aws_subnet.publica_adicional_lab[0].id, null)
}
