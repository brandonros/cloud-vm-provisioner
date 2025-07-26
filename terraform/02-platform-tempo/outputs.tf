# Tempo outputs (for other services to reference)
output "tempo_deployed" {
  description = "Indicates that Tempo has been successfully deployed"
  value       = true
  depends_on  = [module.tempo]
}