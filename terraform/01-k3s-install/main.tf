# Get VM details from terraform state
data "terraform_remote_state" "vm" {
  backend = "local"
  config = {
    path = "../00-vm-${var.cloud_provider}/terraform.tfstate"
  }
}

locals {
  instance_ipv4     = data.terraform_remote_state.vm.outputs.instance_ipv4
  instance_username = data.terraform_remote_state.vm.outputs.instance_username
  instance_ssh_port = data.terraform_remote_state.vm.outputs.instance_ssh_port
}

# Install k3s (dependencies + k3s installation + configuration)
resource "null_resource" "k3s_install" {
  provisioner "remote-exec" {
    inline = [file("${path.module}/install-k3s.sh")]

    connection {
      type        = "ssh"
      user        = local.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = local.instance_ipv4
      port        = local.instance_ssh_port
    }
  }
}

# Retrieve kubeconfig
data "external" "kubeconfig" {
  depends_on = [null_resource.k3s_install]
  program = ["bash", "${path.module}/get-kubeconfig.sh"]
  
  query = {
    instance_ipv4     = local.instance_ipv4
    instance_username = local.instance_username
    instance_ssh_port = local.instance_ssh_port
  }
}

resource "local_file" "kubeconfig_file" {
  depends_on      = [data.external.kubeconfig]
  content         = base64decode(data.external.kubeconfig.result.content)
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"  # Restrict permissions as kubeconfig contains sensitive data
}