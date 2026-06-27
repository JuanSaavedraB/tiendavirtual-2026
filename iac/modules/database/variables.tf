variable "nombre_instancia_rds" {
  description = "Identificador de la instancia RDS"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC compartida desde el modulo networking"
  type        = string
}

variable "default_security_group_id" {
  description = "ID del security group default de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets publicas compartidas para el subnet group RDS en el laboratorio"
  type        = list(string)
}

variable "public_subnet_availability_zones" {
  description = "AZs de las subnets publicas compartidas para RDS"
  type        = list(string)
}

variable "usuario_base_datos" {
  description = "Usuario administrador de RDS"
  type        = string
}

variable "contrasenha_base_datos" {
  description = "Contraseña del usuario administrador de RDS"
  type        = string
}

variable "nombre_base_datos_inicial" {
  description = "Base de datos inicial a crear en RDS"
  type        = string
}

variable "ddl_script_path" {
  description = "Ruta absoluta al script DDL que inicializa esquemas/tablas"
  type        = string
}

variable "dml_script_path" {
  description = "Ruta absoluta al script DML que inicializa datos"
  type        = string
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Almacenamiento inicial en GB"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "Almacenamiento maximo en GB"
  type        = number
}

variable "rds_engine_version" {
  description = "Version del motor MySQL"
  type        = string
}

variable "rds_publicly_accessible" {
  description = "Define si la instancia RDS sera publica"
  type        = bool
}

variable "db_init_timeout_seconds" {
  description = "Tiempo maximo total para esperar disponibilidad de RDS antes de fallar"
  type        = number

  validation {
    condition     = var.db_init_timeout_seconds > 0
    error_message = "db_init_timeout_seconds debe ser mayor a 0."
  }
}

variable "db_init_retry_interval_seconds" {
  description = "Intervalo entre reintentos de disponibilidad de RDS"
  type        = number

  validation {
    condition     = var.db_init_retry_interval_seconds > 0
    error_message = "db_init_retry_interval_seconds debe ser mayor a 0."
  }
}
