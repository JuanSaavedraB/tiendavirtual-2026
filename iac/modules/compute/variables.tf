variable "nombre_cluster" {
  type        = string
  description = "Nombre del clúster ECS donde se desplegará la tarea"
}

variable "familia_tarea_ventas" {
  type        = string
  description = "Nombre de la familia de tareas ECS de ventas"
}

variable "familia_tarea_logistica" {
  type        = string
  description = "Nombre de la familia de tareas ECS de logistica"
}

variable "rol_lab_arn" {
  type        = string
  description = "ARN del rol IAM que la tarea ECS utilizará"
}

variable "id_cuenta_aws" {
  type = string
}

variable "region_aws" {
  type = string
}

variable "nombre_repo_ecr" {
  type        = string
  description = "Nombre del repositorio ECR compartido"
}

variable "tag_imagen_ventas" {
  type        = string
  description = "Tag de imagen para el microservicio de ventas"
}

variable "tag_imagen_logistica" {
  type        = string
  description = "Tag de imagen para el microservicio de logistica"
}

variable "host_base_datos" {
  type        = string
  description = "Host DNS de la base de datos para la aplicación"
}

variable "nombre_base_datos_ventas" {
  type        = string
  description = "Nombre de esquema/base de datos para ventas"
}

variable "nombre_base_datos_logistica" {
  type        = string
  description = "Nombre de esquema/base de datos para logistica"
}

variable "usuario_base_datos" {
  type        = string
  description = "Usuario de la base de datos para la aplicación"
}

variable "contrasenha_base_datos" {
  type        = string
  description = "Contraseña de la base de datos para la aplicación"

}

variable "nombre_servicio_ecs_ventas" {
  type        = string
  description = "Nombre del servicio ECS para ventas"
}

variable "nombre_servicio_ecs_logistica" {
  type        = string
  description = "Nombre del servicio ECS para logistica"
}

variable "path_base_servicio" {
  type        = string
  description = "Path base del API (ej. /api)"
}

variable "queue_url_sync_ventas" {
  type        = string
  description = "URL de la cola SQS para eventos de ventas"
}

variable "queue_url_sync_logistica" {
  type        = string
  description = "URL de la cola SQS para eventos de logistica"
}
