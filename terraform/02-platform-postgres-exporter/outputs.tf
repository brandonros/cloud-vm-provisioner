# Postgres Exporter outputs (for other services to reference)
output "postgres_exporter_deployed" {
  description = "Indicates that postgres-exporter has been successfully deployed"
  value       = true
  depends_on  = [module.postgres_exporter]
}