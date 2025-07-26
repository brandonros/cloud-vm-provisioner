# PgBouncer outputs (for other services to reference)
output "pgbouncer_deployed" {
  description = "Indicates that pgbouncer has been successfully deployed"
  value       = true
  depends_on  = [module.pgbouncer]
}