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

provider "kubernetes" {
  config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
  }
}

module "metrics_server" {
  source = "./modules/00-metrics-server"
}

module "gateway_api" {
  depends_on = [module.metrics_server]
  source = "./modules/01-gateway-api"
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ip = data.terraform_remote_state.vm.outputs.instance_ipv4
}

module "cert_manager" {
  source = "./modules/02-cert-manager"
  depends_on = [module.gateway_api]
}

module "traefik" {
  source = "./modules/03-traefik"
  depends_on = [module.cert_manager]
}
