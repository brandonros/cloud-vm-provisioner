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

# Deploy PgBouncer
module "pgbouncer" {
  source   = "../modules/helm-release"
  manifest = yamldecode(file("${path.module}/manifests/pgbouncer.yaml"))
}