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
}

variable "nombre_cluster_ecs" {
  description = "Nombre del clúster ECS donde se desplegará la tarea"
  type        = string
}
variable "familia_tarea_ecs" {
  description = "value de la familia de tareas ECS"
  type        = string
}

variable "nombre_repo_ecr" {
  description = "value del repositorio ECR donde se almacenará la imagen del contenedor"
  type        = string
}

variable "host_base_datos" {
  description = "Host DNS de la base de datos MySQL"
  type        = string
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos MySQL"
  type        = string
}

variable "usuario_base_datos" {
  description = "value del usuario de la base de datos para la aplicación"
  type        = string
}

variable "contrasenha_base_datos" {
  description = "value de la contraseña de la base de datos para la aplicación"
  type        = string
}

variable "nombre_servicio_ecs" {
  description = "Nombre del servicio ECS donde se desplegará la tarea"
  type        = string
}
