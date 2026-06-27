output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "public_subnet_availability_zones" {
  value = module.networking.public_subnet_availability_zones
}

output "created_additional_public_subnet_for_lab" {
  value = module.networking.created_additional_public_subnet_for_lab
}

output "additional_public_subnet_id" {
  value = module.networking.additional_public_subnet_id
}

output "alb_subnet_ids" {
  value = module.compute.alb_subnet_ids
}

output "alb_availability_zones" {
  value = module.compute.alb_availability_zones
}

output "rds_subnet_group_subnet_ids" {
  value = module.database.rds_subnet_group_subnet_ids
}

output "rds_availability_zones" {
  value = module.database.rds_availability_zones
}

output "api_gateway_url" {
  value = module.api.api_gateway_url
}

output "alb_dns_name" {
  value = module.compute.load_balancer_url
}

output "frontend_url" {
  value = var.frontend_url
}
