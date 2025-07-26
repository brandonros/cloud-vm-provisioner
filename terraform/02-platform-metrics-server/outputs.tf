# Metrics Server outputs (for other services to reference)
output "metrics_server_deployed" {
  description = "Indicates that Metrics Server has been successfully deployed"
  value       = true
  depends_on  = [module.metrics_server]
}