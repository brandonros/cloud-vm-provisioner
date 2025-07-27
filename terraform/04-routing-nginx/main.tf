# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Get nginx deployment details from terraform state
data "terraform_remote_state" "nginx" {
  backend = "local"
  config = {
    path = "../02-platform-nginx/terraform.tfstate"
  }
}

# nginx routing configuration
locals {
  nginx_config = {
    domain = "nginxtest123.duckdns.org"
    app_name = "nginx"
    container_port = 80
    protocol_type = "https"
  }
}

# DNS management (optional)
module "dns" {
  count = var.enable_dns ? 1 : 0
  source = "../modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = local.nginx_config.domain
  app_name = local.nginx_config.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  count = var.enable_tls ? 1 : 0
  source = "../modules/tls"
  
  depends_on = [module.dns]
  domain = local.nginx_config.domain
  app_name = local.nginx_config.app_name
  container_port = local.nginx_config.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/routing"
  depends_on = [data.terraform_remote_state.nginx]
  domain = local.nginx_config.domain
  app_name = local.nginx_config.app_name
  container_port = local.nginx_config.container_port
  protocol_type = local.nginx_config.protocol_type
}

# HTTP Gateway is needed for cert-manager ACME HTTP-01 challenges
module "gateway" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/gateway"
  domain = local.nginx_config.domain
  app_name = local.nginx_config.app_name
  container_port = local.nginx_config.container_port
  protocol_type = "http"  # Always HTTP for the gateway (HTTPS is handled by TLS module)
}