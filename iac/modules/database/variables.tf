variable "nombre_instancia_rds" {
  description = "Identificador de la instancia RDS"
  type        = string
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
