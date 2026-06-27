output "rds_endpoint" {
  description = "Endpoint DNS de la instancia RDS"
  value       = aws_db_instance.tienda_virtual_mysql.address
}

output "rds_port" {
  description = "Puerto de la instancia RDS"
  value       = aws_db_instance.tienda_virtual_mysql.port
}

output "rds_subnet_group_subnet_ids" {
  description = "Subnets configuradas en el DB subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.subnet_ids
}

output "rds_availability_zones" {
  description = "AZs configuradas para el DB subnet group"
  value       = var.public_subnet_availability_zones
}
