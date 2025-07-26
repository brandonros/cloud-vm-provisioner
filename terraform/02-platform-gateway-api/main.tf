# Get VM and K3s details from terraform state
data "terraform_remote_state" "vm" {
  backend = "local"
  config = {
    path = "../00-vm-${var.cloud_provider}/terraform.tfstate"
  }
}

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

# Deploy Gateway API
module "gateway_api" {
  source = "../modules/gateway-api"
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ip = data.terraform_remote_state.vm.outputs.instance_ipv4
  instance_ssh_port = data.terraform_remote_state.vm.outputs.instance_ssh_port
}