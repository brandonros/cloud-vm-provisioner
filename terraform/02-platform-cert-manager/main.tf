# Get K3s details from terraform state
data "terraform_remote_state" "k3s" {
  backend = "local"
  config = {
    path = "../01-k3s-install/terraform.tfstate"
  }
}

# Wait for Gateway API to be deployed
data "terraform_remote_state" "gateway_api" {
  backend = "local"
  config = {
    path = "../02-platform-gateway-api/terraform.tfstate"
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

# Deploy cert-manager (depends on Gateway API)
module "cert_manager" {
  source   = "../modules/helm-release"
  manifest = yamldecode(file("../manifests/cert-manager.yaml"))
  
  # Ensure Gateway API is deployed first
  depends_on = [data.terraform_remote_state.gateway_api]
}