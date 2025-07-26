# RabbitMQ outputs (for other services to reference)
output "rabbitmq_deployed" {
  description = "Indicates that RabbitMQ has been successfully deployed"
  value       = true
  depends_on  = [module.rabbitmq]
}