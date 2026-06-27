variable "create_missing_public_subnet_for_lab" {
  description = "Crea una subnet publica adicional cuando el Learner Lab solo expone subnets en una AZ."
  type        = bool
  default     = false
}

variable "create_missing_public_subnet_for_alb" {
  description = "Variable antigua conservada por compatibilidad. No anula create_missing_public_subnet_for_lab=true."
  type        = bool
  default     = false
}

variable "additional_public_subnet_cidr_block" {
  description = "CIDR de la subnet publica adicional para cubrir una segunda AZ en Learner Lab."
  type        = string
  default     = "172.31.32.0/20"
}

variable "additional_public_subnet_availability_zone" {
  description = "Availability Zone de la subnet publica adicional para Learner Lab."
  type        = string
  default     = "us-east-1b"
}
