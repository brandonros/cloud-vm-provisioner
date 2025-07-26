variable "cloud_provider" {
  description = "The cloud provider used for VM provisioning"
  type        = string
}

data "terraform_remote_state" "vm" {
  backend = "local"
  config = {
    path = "${path.module}/../../../00-vm-${var.cloud_provider}/terraform.tfstate"
  }
}

locals {
  instance_ipv4 = data.terraform_remote_state.vm.outputs.instance_ipv4
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ssh_port = data.terraform_remote_state.vm.outputs.instance_ssh_port
}

data "external" "kubeconfig" {
  program = ["bash", "${path.module}/get-kubeconfig.sh"]
  
  query = {
    instance_ipv4 = local.instance_ipv4
    instance_username = local.instance_username
    instance_ssh_port = local.instance_ssh_port
  }
}

resource "local_file" "kubeconfig_file" {
  depends_on = [data.external.kubeconfig]
  content    = base64decode(data.external.kubeconfig.result.content)
  filename   = "${path.module}/kubeconfig"
  file_permission = "0600"  # Restrict permissions as kubeconfig contains sensitive data
}

output "kubeconfig_path" {
  value = abspath(local_file.kubeconfig_file.filename)
}
