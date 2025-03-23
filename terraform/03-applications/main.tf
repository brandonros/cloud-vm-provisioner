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

data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../00-infrastructure/terraform.tfstate"
  }
}

data "terraform_remote_state" "kubernetes" {
  backend = "local"
  config = {
    path = "../01-kubernetes/terraform.tfstate"
  }
}

variable "duckdns_token" {
  type = string
  description = "DuckDNS token"
}

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

provider "kubernetes" {
  config_path = data.terraform_remote_state.kubernetes.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = data.terraform_remote_state.kubernetes.outputs.kubeconfig_path
  }
}

module "duckdns_updater" {
  source = "./modules/00-duckdns-updater"
  duckdns_token = var.duckdns_token
  duckdns_domain = var.duckdns_domain
}

module "issuer" {
  source = "./modules/01-issuer"
  depends_on = [module.duckdns_updater]
}

module "gateway" {
  source = "./modules/02-gateway"
  depends_on = [module.issuer]
  duckdns_domain = var.duckdns_domain
}

module "pdf_generator" {
  source = "./modules/03-pdf-generator"
  depends_on = [module.gateway]
}

module "traefik_routes" {
  source = "./modules/04-traefik-routes"
  depends_on = [module.pdf_generator]
  duckdns_domain = var.duckdns_domain
}
