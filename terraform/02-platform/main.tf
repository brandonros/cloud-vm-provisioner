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

module "gateway_api" {
  source = "./modules/gateway-api"
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ip = data.terraform_remote_state.vm.outputs.instance_ipv4
}

module "metrics_server" {
  depends_on = [module.gateway_api]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/metrics-server.yaml"))
}

module "cert_manager" {
  depends_on = [module.metrics_server]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/cert-manager.yaml"))
}

module "traefik" {
  depends_on = [module.cert_manager]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/traefik.yaml"))
}

module "rabbitmq" {
  depends_on = [module.traefik]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/rabbitmq.yaml"))
}
