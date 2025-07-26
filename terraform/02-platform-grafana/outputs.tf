# Grafana outputs (for other services to reference)
output "grafana_deployed" {
  description = "Indicates that Grafana has been successfully deployed"
  value       = true
  depends_on  = [module.grafana]
}