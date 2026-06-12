variable "region" {
  description = "Region en la que se desplegarán los recursos de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto para etiquetar y nombrar recursos"
  type        = string
  default     = "tienda-virtual"
}

variable "environment" {
  description = "Ambiente del despliegue. Úsalo para separar state y nombres entre dev, test, prod, etc."
  type        = string
  default     = "main"
}

variable "vpc_id" {
  description = "ID de la VPC existente donde se desplegarán ECS y el ALB. Si se deja vacío, se usa la VPC por defecto."
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Subnets públicas existentes para el ALB y ECS. Deben ser al menos dos y estar en distintas AZs. Si se deja vacío, se usan las subnets de la VPC por defecto."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.public_subnet_ids) == 0 || length(var.public_subnet_ids) >= 2
    error_message = "public_subnet_ids debe estar vacío o contener al menos dos subnets públicas."
  }
}

variable "create_missing_public_subnet_for_alb" {
  description = "Crea una subnet pública adicional para el ALB cuando public_subnet_ids está vacío y la VPC seleccionada tiene menos de dos subnets."
  type        = bool
  default     = false
}

variable "additional_public_subnet_cidr_block" {
  description = "CIDR de la subnet pública adicional para el ALB. Debe estar dentro del CIDR de la VPC y no solaparse con subnets existentes."
  type        = string
  default     = ""

  validation {
    condition     = var.additional_public_subnet_cidr_block == "" || can(cidrhost(var.additional_public_subnet_cidr_block, 0))
    error_message = "additional_public_subnet_cidr_block debe estar vacío o ser un CIDR válido, por ejemplo 172.31.32.0/20."
  }
}

variable "additional_public_subnet_availability_zone" {
  description = "Availability Zone para la subnet pública adicional del ALB, por ejemplo us-east-1b."
  type        = string
  default     = ""
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

variable "nombre_load_balancer" {
  description = "Nombre del Application Load Balancer. Debe ser único en la región por cuenta AWS."
  type        = string
  default     = "tienda-virtual-alb"
}

variable "nombre_target_group" {
  description = "Nombre del Target Group. Debe ser único en la región por cuenta AWS."
  type        = string
  default     = "tg-tienda-virtual"
}

variable "nombre_event_bus" {
  description = "Nombre del EventBridge Event Bus. Debe ser único en la región por cuenta AWS."
  type        = string
  default     = "ordenes-bus"
}
