# mssql outputs (for other services to reference)
output "mssql_deployed" {
  description = "Indicates that mssql has been successfully deployed"
  value       = true
  depends_on  = [module.mssql]
}