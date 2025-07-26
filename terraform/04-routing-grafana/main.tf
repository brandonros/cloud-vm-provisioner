# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Get Grafana deployment details from terraform state
data "terraform_remote_state" "grafana" {
  backend = "local"
  config = {
    path = "../02-platform-grafana/terraform.tfstate"
  }
}

# Grafana routing configuration
locals {
  grafana_config = {
    domain = "grafana.asusrogstrix.local"
    app_name = "grafana"
    container_port = 80
    protocol_type = "http"
  }
}

# DNS management (optional)
module "dns" {
  count = var.enable_dns ? 1 : 0
  source = "../modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = local.grafana_config.domain
  app_name = local.grafana_config.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  count = var.enable_tls ? 1 : 0
  source = "../modules/tls"
  
  depends_on = [module.dns]
  domain = local.grafana_config.domain
  app_name = local.grafana_config.app_name
  container_port = local.grafana_config.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/routing"
  depends_on = [data.terraform_remote_state.grafana]
  domain = local.grafana_config.domain
  app_name = local.grafana_config.app_name
  container_port = local.grafana_config.container_port
  protocol_type = local.grafana_config.protocol_type
}

module "gateway" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/gateway"
  domain = local.grafana_config.domain
  app_name = local.grafana_config.app_name
  container_port = local.grafana_config.container_port
  protocol_type = local.grafana_config.protocol_type
}