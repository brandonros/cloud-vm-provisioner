output "rpc_dispatcher_deployed" {
  description = "Indicates that rpc-dispatcher has been successfully deployed"
  value       = true
  depends_on  = [module.rpc_dispatcher]
}