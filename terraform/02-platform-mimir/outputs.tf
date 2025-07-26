# Mimir outputs (for other services to reference)
output "mimir_deployed" {
  description = "Indicates that Mimir has been successfully deployed"
  value       = true
  depends_on  = [module.mimir]
}