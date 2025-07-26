# Alloy outputs (for other services to reference)
output "alloy_deployed" {
  description = "Indicates that Alloy has been successfully deployed"
  value       = true
  depends_on  = [module.alloy]
}