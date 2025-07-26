# Gateway API outputs (for other services to reference)
output "gateway_api_deployed" {
  description = "Indicates that Gateway API has been successfully deployed"
  value       = true
  depends_on  = [module.gateway_api]
}