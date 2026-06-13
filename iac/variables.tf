variable "region" {
  description = "Region en la que se desplegarán los recursos de AWS"
  default     = "us-east-1"
}

variable "id_cuenta_aws" {
  description = "ID de la cuenta de AWS donde se desplegarán los recursos"
  type        = string
}

variable "nombre_rol_iam" {
  description = "Nombre del rol IAM a usar para ECS, Lambda y API Gateway"
  type        = string
}

variable "path_base_servicio" {
  description = "Path base para el servicio backend usado por la Lambda (acepta api o /api)"
  type        = string
  default     = "api"
}

variable "nombre_cluster_ecs" {
  description = "Nombre del clúster ECS donde se desplegará la tarea"
  type        = string
  default     = "tienda-virtual-cluster"
}

variable "familia_tarea_ecs_ventas" {
  description = "Familia de tarea ECS para el microservicio de ventas"
  type        = string
  default     = "tienda-virtual-ventas"
}

variable "familia_tarea_ecs_logistica" {
  description = "Familia de tarea ECS para el microservicio de logistica"
  type        = string
  default     = "tienda-virtual-logistica"
}

variable "nombre_repo_ecr" {
  description = "Repositorio ECR compartido para imagenes de ventas y logistica"
  type        = string
  default     = "tiendavirtual"
}

variable "tag_imagen_ventas" {
  description = "Tag de imagen para el microservicio de ventas"
  type        = string
  default     = "ventas-latest"
}

variable "tag_imagen_logistica" {
  description = "Tag de imagen para el microservicio de logistica"
  type        = string
  default     = "logistica-latest"
}

variable "usuario_base_datos" {
  description = "Usuario administrador de la instancia RDS"
  type        = string
  default     = "admin"
}

variable "contrasenha_base_datos" {
  description = "Contraseña del usuario administrador de la instancia RDS"
  type        = string
}

variable "nombre_servicio_ecs_ventas" {
  description = "Nombre del servicio ECS de ventas"
  type        = string
  default     = "servicio-ventas"
}

variable "nombre_servicio_ecs_logistica" {
  description = "Nombre del servicio ECS de logistica"
  type        = string
  default     = "servicio-logistica"
}

variable "nombre_instancia_rds" {
  description = "Identificador de la instancia RDS MySQL"
  type        = string
  default     = "tiendavirtual"
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Almacenamiento inicial en GB para RDS"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Almacenamiento maximo en GB para autoescalado de RDS"
  type        = number
  default     = 100
}

variable "rds_engine_version" {
  description = "Version del motor MySQL en RDS"
  type        = string
  default     = "8.0"
}

variable "rds_publicly_accessible" {
  description = "Define si la instancia RDS sera publica"
  type        = bool
  default     = true
}

variable "esquema_ventas" {
  description = "Nombre del esquema MySQL para ventas"
  type        = string
  default     = "ventas"
}

variable "esquema_logistica" {
  description = "Nombre del esquema MySQL para logistica"
  type        = string
  default     = "logistica"
}

variable "esquema_tiendavirtual" {
  description = "Nombre del esquema MySQL sincronizado"
  type        = string
  default     = "tiendavirtual"
}

variable "nombre_base_datos_inicial_rds" {
  description = "Nombre de la base inicial creada por RDS"
  type        = string
  default     = "tiendavirtual"
}
