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

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

provider "kubernetes" {
  config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
  }
}

module "pdf_generator_duckdns_updater" {
  source = "./modules/00-duckdns-updater"
  duckdns_token = var.duckdns_token
  duckdns_domain = var.duckdns_domain
  app_name = "pdf-generator"
}

module "pdf_generator_certificates" {
  source = "./modules/01-certificates"
  depends_on = [module.pdf_generator_duckdns_updater]
  domain = var.duckdns_domain
  app_name = "pdf-generator"
}

module "pdf_generator_app" {
  source = "./modules/02-application"
  depends_on = [module.pdf_generator_certificates]
  domain = var.duckdns_domain
  app_name = "pdf-generator"
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
