output "event_bus_name" {
  description = "Nombre del bus de eventos donde se publicarán los eventos"
  value       = aws_cloudwatch_event_bus.ordenes_bus.name
}
