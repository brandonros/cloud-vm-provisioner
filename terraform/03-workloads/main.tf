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
} 

locals {
  applications = {
    pdf_generator1 = {
      domain = "pdf-generator5555.duckdns.org"
      app_name = "pdf-generator1"
      manifest = yamldecode(file("${path.module}/manifests/pdf-generator1.yaml"))
      container_port = 3000
    }
    pdf_generator2 = {
      domain = "pdf-generator5556.duckdns.org"
      app_name = "pdf-generator2"
      manifest = yamldecode(file("${path.module}/manifests/pdf-generator2.yaml"))
      container_port = 3000
    }
  }
}

module "dns" {
  for_each = local.applications
  source = "./modules/dns"
  duckdns_token = var.duckdns_token
  duckdns_domain = each.value.domain
  app_name = each.value.app_name
}

module "tls" {
  for_each = local.applications
  source = "./modules/tls"
  depends_on = [module.dns]
  domain = each.value.domain
  app_name = each.value.app_name
}

module "app" {
  for_each = local.applications
  source = "./modules/helm-release"
  depends_on = [module.tls]
  manifest = each.value.manifest
}

module "routing" {
  for_each = local.applications
  source = "./modules/routing"
  depends_on = [module.app]
  domain = each.value.domain
  app_name = each.value.app_name
  container_port = each.value.container_port
}
