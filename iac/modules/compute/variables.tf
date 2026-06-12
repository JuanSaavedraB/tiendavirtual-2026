variable "project_name" {
  type        = string
  description = "Nombre base del proyecto para etiquetas"
}

variable "environment" {
  type        = string
  description = "Ambiente del despliegue para etiquetas"
}

variable "nombre_cluster" {
  type        = string
  description = "Nombre del clúster ECS donde se desplegará la tarea"
}

variable "familia_tarea" {
  type        = string
  description = "Nombre de la familia de tareas ECS"
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
  description = "Nombre del repositorio ECR donde se almacenará la imagen del contenedor"
}

variable "host_base_datos" {
  type        = string
  description = "Host DNS de la base de datos para la aplicación"
}

variable "nombre_base_datos" {
  type        = string
  description = "Nombre de la base de datos para la aplicación"
}

variable "usuario_base_datos" {
  type        = string
  description = "Usuario de la base de datos para la aplicación"
}

variable "contrasenha_base_datos" {
  type        = string
  description = "Contraseña de la base de datos para la aplicación"

}

variable "nombre_servicio_ecs" {
  type        = string
  description = "Nombre del servicio ECS donde se desplegará la tarea"
}

variable "nombre_load_balancer" {
  type        = string
  description = "Nombre del Application Load Balancer"
}

variable "nombre_target_group" {
  type        = string
  description = "Nombre del Target Group"
}

variable "vpc_id" {
  type        = string
  description = "ID de VPC existente. Si está vacío, se usa la VPC por defecto."
  default     = ""
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Subnets públicas para ALB/ECS. Si está vacío, se usan las subnets de la VPC seleccionada."
  default     = []

  validation {
    condition     = length(var.public_subnet_ids) == 0 || length(var.public_subnet_ids) >= 2
    error_message = "public_subnet_ids debe estar vacío o contener al menos dos subnets públicas."
  }
}
