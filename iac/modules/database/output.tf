output "rds_endpoint" {
  description = "Endpoint DNS de la instancia RDS"
  value       = aws_db_instance.tienda_virtual_mysql.address
}

output "rds_port" {
  description = "Puerto de la instancia RDS"
  value       = aws_db_instance.tienda_virtual_mysql.port
}
