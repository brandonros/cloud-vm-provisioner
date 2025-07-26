# Traefik outputs (for other services to reference)
output "traefik_deployed" {
  description = "Indicates that Traefik has been successfully deployed"
  value       = true
  depends_on  = [module.traefik]
}