# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Get PostgreSQL deployment details from terraform state
data "terraform_remote_state" "postgresql" {
  backend = "local"
  config = {
    path = "../02-platform-postgresql/terraform.tfstate"
  }
}

# PostgreSQL routing configuration
locals {
  postgresql_config = {
    domain = "postgresql5555.duckdns.org"
    app_name = "postgresql"
    container_port = 5432
    protocol_type = "tcp"
  }
}

# DNS management (optional)
module "dns" {
  count = var.enable_dns ? 1 : 0
  source = "../modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = local.postgresql_config.domain
  app_name = local.postgresql_config.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  count = var.enable_tls ? 1 : 0
  source = "../modules/tls"
  
  depends_on = [module.dns]
  domain = local.postgresql_config.domain
  app_name = local.postgresql_config.app_name
  container_port = local.postgresql_config.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/routing"
  depends_on = [data.terraform_remote_state.postgresql]
  domain = local.postgresql_config.domain
  app_name = local.postgresql_config.app_name
  container_port = local.postgresql_config.container_port
  protocol_type = local.postgresql_config.protocol_type
}

module "gateway" {
  count = var.enable_routing ? 1 : 0
  source = "../modules/gateway"
  domain = local.postgresql_config.domain
  app_name = local.postgresql_config.app_name
  container_port = local.postgresql_config.container_port
  protocol_type = local.postgresql_config.protocol_type
}