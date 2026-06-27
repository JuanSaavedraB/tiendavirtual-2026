data "aws_vpc" "vpc_por_defecto" {
  default = true
}

data "aws_subnets" "sub_redes_por_defecto" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_por_defecto.id]
  }
}

data "aws_security_group" "grupo_seguridad_por_defecto" {
  name   = "default"
  vpc_id = data.aws_vpc.vpc_por_defecto.id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.nombre_instancia_rds}-subnet-group"
  subnet_ids = data.aws_subnets.sub_redes_por_defecto.ids
}

resource "aws_db_instance" "tienda_virtual_mysql" {
  identifier              = var.nombre_instancia_rds
  engine                  = "mysql"
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  db_name                 = var.nombre_base_datos_inicial
  username                = var.usuario_base_datos
  password                = var.contrasenha_base_datos
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [data.aws_security_group.grupo_seguridad_por_defecto.id]
  publicly_accessible     = var.rds_publicly_accessible
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true
}

resource "null_resource" "inicializar_base_datos" {
  triggers = {
    rds_endpoint = aws_db_instance.tienda_virtual_mysql.address
    ddl_hash     = filesha1(var.ddl_script_path)
    dml_hash     = filesha1(var.dml_script_path)
  }

  provisioner "local-exec" {
    environment = {
      DB_HOST                        = aws_db_instance.tienda_virtual_mysql.address
      DB_PORT                        = tostring(aws_db_instance.tienda_virtual_mysql.port)
      DB_USER                        = var.usuario_base_datos
      DB_PASSWORD                    = var.contrasenha_base_datos
      DDL_SCRIPT                     = var.ddl_script_path
      DML_SCRIPT                     = var.dml_script_path
      DB_INIT_TIMEOUT_SECONDS        = tostring(var.db_init_timeout_seconds)
      DB_INIT_RETRY_INTERVAL_SECONDS = tostring(var.db_init_retry_interval_seconds)
    }
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      start_ts=$(date +%s)
      timeout_seconds="$DB_INIT_TIMEOUT_SECONDS"
      retry_interval_seconds="$DB_INIT_RETRY_INTERVAL_SECONDS"
      deadline=$((start_ts + timeout_seconds))
      intento=0

      while true; do
        intento=$((intento + 1))
        now=$(date +%s)
        elapsed=$((now - start_ts))

        if mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --connect-timeout=5 --silent >/dev/null 2>&1 \
          && mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --protocol=TCP --connect-timeout=5 -e "SELECT 1" >/dev/null 2>&1; then
          echo "RDS disponible y conexión SQL validada."
          break
        fi

        if [ "$now" -ge "$deadline" ]; then
          echo "ERROR: RDS no estuvo disponible tras $${timeout_seconds}s (intentos: $${intento})."
          exit 1
        fi

        restante=$((deadline - now))
        echo "Esperando disponibilidad de RDS... intento $${intento}, transcurrido $${elapsed}s, restante $${restante}s."
        sleep "$retry_interval_seconds"
      done

      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --protocol=TCP --connect-timeout=10 < "$DDL_SCRIPT"
      mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --protocol=TCP --connect-timeout=10 < "$DML_SCRIPT"
    EOT
  }

  depends_on = [aws_db_instance.tienda_virtual_mysql]
}
