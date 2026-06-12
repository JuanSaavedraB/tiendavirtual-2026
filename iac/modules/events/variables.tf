variable "nombre_event_bus" {
  description = "Nombre del bus de eventos donde se publicarán los eventos"
  type        = string
}

variable "crear_orden_funcion_arn" {
  description = "ARN de la función Lambda para crear ordenes"
  type        = string
}

variable "crear_orden_funcion_name" {
  description = "Nombre de la función Lambda para crear ordenes"
  type        = string
}
