output "rpc_consumer_deployed" {
  description = "Indicates that rpc-consumer has been successfully deployed"
  value       = true
  depends_on  = [module.rpc_consumer]
}