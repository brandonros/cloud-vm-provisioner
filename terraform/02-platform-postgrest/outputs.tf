# PostgREST outputs (for other services to reference)
output "postgrest_deployed" {
  description = "Indicates that postgrest has been successfully deployed"
  value       = true
  depends_on  = [module.postgrest]
}