variable "create_missing_public_subnet_for_lab" {
  description = "Crea una subnet publica adicional cuando la VPC default del Learner Lab no cubre 2 AZs"
  type        = bool
  default     = false
}

variable "additional_public_subnet_cidr_block" {
  description = "CIDR de la subnet publica adicional para laboratorio"
  type        = string
  default     = "172.31.32.0/20"

  validation {
    condition     = can(cidrhost(var.additional_public_subnet_cidr_block, 0))
    error_message = "additional_public_subnet_cidr_block debe ser un CIDR valido."
  }
}

variable "additional_public_subnet_availability_zone" {
  description = "Availability Zone de la subnet publica adicional para laboratorio"
  type        = string
  default     = "us-east-1b"
}
