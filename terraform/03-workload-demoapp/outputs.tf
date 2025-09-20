output "deployed" {
  description = "Indicates successful deployment"
  value       = true
  depends_on  = [module.demoapp]
}