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

variable "create_missing_public_subnet_for_alb" {
  type        = bool
  description = "Crea una subnet pública adicional para el ALB cuando public_subnet_ids está vacío y la VPC seleccionada tiene menos de dos subnets."
  default     = false
}

variable "additional_public_subnet_cidr_block" {
  type        = string
  description = "CIDR de la subnet pública adicional para el ALB. Debe estar dentro del CIDR de la VPC y no solaparse con subnets existentes."
  default     = ""

  validation {
    condition     = var.additional_public_subnet_cidr_block == "" || can(cidrhost(var.additional_public_subnet_cidr_block, 0))
    error_message = "additional_public_subnet_cidr_block debe estar vacío o ser un CIDR válido, por ejemplo 172.31.32.0/20."
  }
}

variable "additional_public_subnet_availability_zone" {
  type        = string
  description = "Availability Zone para la subnet pública adicional del ALB, por ejemplo us-east-1b."
  default     = ""
}
