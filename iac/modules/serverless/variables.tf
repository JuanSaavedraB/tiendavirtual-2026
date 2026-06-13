variable "entorno_ejecucion" {
  description = "Entorno de ejecución de la función Lambda"
  default     = "nodejs22.x"
}

variable "rol_lambda_arn" {
  description = "ARN del rol IAM que la función Lambda utilizará"
}

variable "url_base_servicio" {
  description = "URL base del servicio al que la función Lambda se conectará"
  type        = string
}

variable "host_base_datos" {
  description = "Host DNS de RDS para la lambda de sincronizacion"
  type        = string
}

variable "puerto_base_datos" {
  description = "Puerto de RDS para la lambda de sincronizacion"
  type        = number
}

variable "usuario_base_datos" {
  description = "Usuario de RDS para la lambda de sincronizacion"
  type        = string
}

variable "contrasenha_base_datos" {
  description = "Contrasenha de RDS para la lambda de sincronizacion"
  type        = string
}

variable "esquema_tiendavirtual" {
  description = "Esquema sincronizado en RDS"
  type        = string
}

variable "nombre_cola_sync_ventas" {
  description = "Nombre de la cola SQS para eventos de ventas"
  type        = string
}

variable "nombre_cola_sync_logistica" {
  description = "Nombre de la cola SQS para eventos de logistica"
  type        = string
}
