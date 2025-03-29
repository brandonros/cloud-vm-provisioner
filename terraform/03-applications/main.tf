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

variable "duckdns_domain1" {
  type = string
  description = "DuckDNS domain #1"
}

variable "duckdns_domain2" {
  type = string
  description = "DuckDNS domain #2"
}

# Define a locals block to compute the values that depend on variables
locals {
  applications = {
    pdf_generator1 = {
      domain = var.duckdns_domain1
      app_name = "pdf-generator1"
      manifest = yamldecode(file("${path.module}/manifests/pdf-generator1.yaml"))
    }
    pdf_generator2 = {
      domain = var.duckdns_domain2
      app_name = "pdf-generator2"
      manifest = yamldecode(file("${path.module}/manifests/pdf-generator2.yaml"))
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

module "duckdns_updater" {
  for_each = local.applications
  source = "./modules/00-duckdns-updater"
  duckdns_token = var.duckdns_token
  duckdns_domain = each.value.domain
  app_name = each.value.app_name
}

module "certificate" {
  for_each = local.applications
  source = "./modules/01-certificate"
  depends_on = [module.duckdns_updater]
  domain = each.value.domain
  app_name = each.value.app_name
}

module "application" {
  for_each = local.applications
  source = "./modules/02-application"
  depends_on = [module.certificate]
  domain = each.value.domain
  app_name = each.value.app_name
  helm_values = each.value.helm_values
}
