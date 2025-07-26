# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Get RPC Consumer deployment details from terraform state
data "terraform_remote_state" "rpc_consumer" {
  backend = "local"
  config = {
    path = "../03-workload-rpc-consumer/terraform.tfstate"
  }
}

# RPC Consumer routing configuration
locals {
  rpc_consumer_config = {
    domain = "rpc-consumer.asusrogstrix.local"
    app_name = "rpc-consumer"
    container_port = 3000
    protocol_type = "https"
  }
}

# DNS management (optional)
module "dns" {
  count = var.enable_dns ? 1 : 0
  source = "../modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = local.rpc_consumer_config.domain
  app_name = local.rpc_consumer_config.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  count = var.enable_tls ? 1 : 0
  source = "../modules/tls"
  
  depends_on = [module.dns]
  domain = local.rpc_consumer_config.domain
  app_name = local.rpc_consumer_config.app_name
  container_port = local.rpc_consumer_config.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/routing"
  depends_on = [data.terraform_remote_state.rpc_consumer]
  domain = local.rpc_consumer_config.domain
  app_name = local.rpc_consumer_config.app_name
  container_port = local.rpc_consumer_config.container_port
  protocol_type = local.rpc_consumer_config.protocol_type
}

module "gateway" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/gateway"
  domain = local.rpc_consumer_config.domain
  app_name = local.rpc_consumer_config.app_name
  container_port = local.rpc_consumer_config.container_port
  protocol_type = local.rpc_consumer_config.protocol_type
}