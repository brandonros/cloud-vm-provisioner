# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Get Postgrest deployment details from terraform state
data "terraform_remote_state" "postgrest" {
  backend = "local"
  config = {
    path = "../02-platform-postgrest/terraform.tfstate"
  }
}

# Postgrest routing configuration
locals {
  postgrest_config = {
    domain = "postgrest.asusrogstrix.local"
    app_name = "postgrest"
    container_port = 3000
    protocol_type = "http"
  }
}

# DNS management (optional)
module "dns" {
  count = var.enable_dns ? 1 : 0
  source = "../modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = local.postgrest_config.domain
  app_name = local.postgrest_config.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  count = var.enable_tls ? 1 : 0
  source = "../modules/tls"
  
  depends_on = [module.dns]
  domain = local.postgrest_config.domain
  app_name = local.postgrest_config.app_name
  container_port = local.postgrest_config.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/routing"
  depends_on = [data.terraform_remote_state.postgrest]
  domain = local.postgrest_config.domain
  app_name = local.postgrest_config.app_name
  container_port = local.postgrest_config.container_port
  protocol_type = local.postgrest_config.protocol_type
}

module "gateway" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/gateway"
  domain = local.postgrest_config.domain
  app_name = local.postgrest_config.app_name
  container_port = local.postgrest_config.container_port
  protocol_type = local.postgrest_config.protocol_type
}