# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Configure providers
provider "kubernetes" {
  config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = data.terraform_remote_state.k3s.outputs.kubeconfig_path
  }
}

# Deploy Kube State Metrics
module "kube_state_metrics" {
  source   = "../modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/kube-state-metrics.yaml"))
}