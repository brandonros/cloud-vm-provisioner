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

resource "null_resource" "k3s_install" {
  provisioner "remote-exec" {
    inline = [file("${path.module}/install.sh")]

    connection {
      type        = "ssh"
      user        = local.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = local.instance_ipv4
      port        = local.instance_ssh_port
    }
  }
}
