# Node Exporter outputs (for other services to reference)
output "node_exporter_deployed" {
  description = "Indicates that Node Exporter has been successfully deployed"
  value       = true
  depends_on  = [module.node_exporter]
}