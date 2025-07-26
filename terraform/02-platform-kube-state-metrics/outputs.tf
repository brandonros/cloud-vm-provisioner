# Kube State Metrics outputs (for other services to reference)
output "kube_state_metrics_deployed" {
  description = "Indicates that Kube State Metrics has been successfully deployed"
  value       = true
  depends_on  = [module.kube_state_metrics]
}