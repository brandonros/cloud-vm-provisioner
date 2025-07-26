# Loki outputs (for other services to reference)
output "loki_deployed" {
  description = "Indicates that Loki has been successfully deployed"
  value       = true
  depends_on  = [module.loki]
}