# nginx outputs (for other services to reference)
output "nginx_deployed" {
  description = "Indicates that nginx has been successfully deployed"
  value       = true
  depends_on  = [module.nginx]
}