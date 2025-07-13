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
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/metrics-server.yaml"))
}

module "gateway_api" {
  source = "./modules/gateway-api"
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ip = data.terraform_remote_state.vm.outputs.instance_ipv4
  instance_ssh_port = data.terraform_remote_state.vm.outputs.instance_ssh_port
}

module "cert_manager" {
  depends_on = [module.gateway_api]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/cert-manager.yaml"))
}

module "traefik" {
  depends_on = [module.cert_manager]
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/traefik.yaml"))
}

# module "rabbitmq" {
#   source   = "./modules/helm-release"
#   manifest = yamldecode(file("${path.module}/manifests/rabbitmq.yaml"))
# }

# logs
module "loki" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/loki.yaml"))
}

# tracing
module "tempo" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/tempo.yaml"))
}

# monitoring
module "grafana" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/grafana.yaml"))
}

# storage
module "mimir" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/mimir.yaml"))
}

# collector
module "alloy" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/alloy.yaml"))
}

# node exporter
module "node-exporter" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/node-exporter.yaml"))
}

# postgresql
module "postgresql" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/postgresql.yaml"))
}

# pgbouncer
module "pgbouncer" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/pgbouncer.yaml"))
}

# postgrest
module "postgrest" {
  source   = "./modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/postgrest.yaml"))
}
