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

variable "applications" {
  type = map(object({
    domain = string
    app_name = string
    image_repository = string
    image_tag = string
    container_port = number
    environment_variables = map(object({
      value = string
    }))
  }))
  description = "Map of application configurations"
  default = {
    pdf_generator1 = {
      domain = var.duckdns_domain1
      app_name = "pdf-generator1"
      image_repository = "ghcr.io/avdeev99/puppeteer-pdf-generator"
      image_tag = "93420ed874e6937871ce6a40449a960aa8738e86"
      container_port = 3000
      environment_variables = {
        CHROMIUM_PATH = {
          value = "/usr/bin/chromium"
        }
        PUPPETEER_MAX_CONCURRENT_PAGES = {
          value = "15"
        }
        ASPNETCORE_URLS = {
          value = "http://0.0.0.0:3000"
        }
      }
    }
    pdf_generator2 = {
      domain = var.duckdns_domain2
      app_name = "pdf-generator2"
      image_repository = "ghcr.io/avdeev99/puppeteer-pdf-generator"
      image_tag = "93420ed874e6937871ce6a40449a960aa8738e86"
      container_port = 3000
      environment_variables = {
        CHROMIUM_PATH = {
          value = "/usr/bin/chromium"
        }
        PUPPETEER_MAX_CONCURRENT_PAGES = {
          value = "15"
        }
        ASPNETCORE_URLS = {
          value = "http://0.0.0.0:3000"
        }
      }
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
  for_each = var.applications
  source = "./modules/00-duckdns-updater"
  duckdns_token = var.duckdns_token
  duckdns_domain = each.value.domain
  app_name = each.value.app_name
}

module "certificates" {
  for_each = var.applications
  source = "./modules/01-certificates"
  depends_on = [module.duckdns_updater]
  domain = each.value.domain
  app_name = each.value.app_name
}

module "application" {
  for_each = var.applications
  source = "./modules/02-application"
  depends_on = [module.certificates]
  domain = each.value.domain
  app_name = each.value.app_name
  image_repository = each.value.image_repository
  image_tag = each.value.image_tag
  container_port = each.value.container_port
  environment_variables = each.value.environment_variables
}
