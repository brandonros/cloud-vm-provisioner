# Cert Manager outputs (for other services to reference)
output "cert_manager_deployed" {
  description = "Indicates that cert-manager has been successfully deployed"
  value       = true
  depends_on  = [module.cert_manager]
}