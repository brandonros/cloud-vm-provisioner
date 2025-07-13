terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
  }
}

data "terraform_remote_state" "vm" {
  backend = "local"
  config = {
    path = "../00-vm/terraform.tfstate"
  }
}

data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s/terraform.tfstate"
  }
}

variable "duckdns_token" {
  type = string
  description = "DuckDNS token"
  default = ""
}

variable "deploy_apps" {
  type = bool
  description = "Whether to deploy applications"
  default = true
}

variable "enable_routing" {
  type = bool
  description = "Whether to enable routing/ingress"
  default = true
}

variable "enable_tls" {
  type = bool
  description = "Whether to enable TLS certificates"
  default = false
}

variable "enable_dns" {
  type = bool
  description = "Whether to manage DNS records"
  default = false
}

# Application definitions - purely for deployment
locals {
  applications = {
    # rpc-dispatcher = {
    #   app_name = "rpc-dispatcher"
    #   manifest = yamldecode(file("${path.module}/manifests/rpc-dispatcher.yaml"))
    # }
    # rpc-consumer = {
    #   app_name = "rpc-consumer"
    #   manifest = yamldecode(file("${path.module}/manifests/rpc-consumer.yaml"))
    # }
  }

  # Routing configuration - separate from deployment
  routing_config = {
    postgresql = {
      domain = "postgresql5555.duckdns.org"
      app_name = "postgresql"
      container_port = 5432
      protocol_type = "tcp"
    }
    pgbouncer = {
      domain = "pgbouncer5555.duckdns.org"
      app_name = "pgbouncer"
      container_port = 5433
      protocol_type = "tcp"
    }
    postgrest = {
      domain = "postgrest.asusrogstrix.local"
      app_name = "postgrest"
      container_port = 3000
      protocol_type = "http"
    }
    grafana = {
      domain = "grafana.asusrogstrix.local"
      app_name = "grafana"
      container_port = 80
      protocol_type = "http"
    }
    # rpc-dispatcher = {
    #   domain = "rpc-dispatcher.asusrogstrix.local"
    #   app_name = "rpc-dispatcher"
    #   container_port = 3000
    #   protocol_type = "https"
    # }
    # rpc-consumer = {
    #   domain = "rpc-consumer.asusrogstrix.local"
    #   app_name = "rpc-consumer"
    #   container_port = 3000
    #   protocol_type = "https"
    # }
  }
}

# Deploy applications (always available, controlled by var.deploy_apps)
module "app" {
  for_each = var.deploy_apps ? local.applications : {}
  source = "./modules/helm-release"
  manifest = each.value.manifest
}

# DNS management (optional)
module "dns" {
  for_each = var.enable_dns ? local.routing_config : {}
  source = "./modules/dns"
  
  duckdns_token = var.duckdns_token
  duckdns_domain = each.value.domain
  app_name = each.value.app_name
}

# TLS certificates (optional, can depend on DNS or work independently)
module "tls" {
  for_each = var.enable_tls ? local.routing_config : {}
  source = "./modules/tls"
  
  #depends_on = [module.dns]
  domain = each.value.domain
  app_name = each.value.app_name
  container_port = each.value.container_port
}

# Routing/Ingress (optional, depends on apps being deployed)
module "routing" {
  for_each = var.enable_routing ? local.routing_config : {}
  source = "./modules/routing"
  #depends_on = [module.app]
  domain = each.value.domain
  app_name = each.value.app_name
  container_port = each.value.container_port
  protocol_type = each.value.protocol_type
}

module "gateway" {
  for_each = var.enable_routing ? local.routing_config : {}
  source = "./modules/gateway"
  domain = each.value.domain
  app_name = each.value.app_name
  container_port = each.value.container_port
  protocol_type = each.value.protocol_type
}