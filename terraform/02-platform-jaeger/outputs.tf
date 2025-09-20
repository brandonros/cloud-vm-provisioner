# outputs (for other services to reference)
output "deployed" {
  description = "Indicates successful deployment"
  value       = true
  depends_on  = [module.jaeger]
}