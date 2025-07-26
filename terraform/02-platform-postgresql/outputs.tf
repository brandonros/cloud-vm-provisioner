# PostgreSQL outputs (for other services to reference)
output "postgresql_deployed" {
  description = "Indicates that postgresql has been successfully deployed"
  value       = true
  depends_on  = [module.postgresql]
}