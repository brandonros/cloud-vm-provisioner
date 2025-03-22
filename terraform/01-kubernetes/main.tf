data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../00-infrastructure/terraform.tfstate"
  }
}

locals {
  instance_ipv4 = data.terraform_remote_state.infrastructure.outputs.instance_ipv4
  instance_username = data.terraform_remote_state.infrastructure.outputs.instance_username
  instance_ssh_port = data.terraform_remote_state.infrastructure.outputs.instance_ssh_port
}

resource "null_resource" "dependencies" {
  provisioner "remote-exec" {
    script = "${path.module}/dependencies.sh"

    connection {
      type        = "ssh"
      user        = local.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = local.instance_ipv4
    }
  }
}

resource "null_resource" "k3s_install" {
  depends_on = [null_resource.dependencies]

  provisioner "remote-exec" {
    script = "${path.module}/k3s.sh"

    connection {
      type        = "ssh"
      user        = local.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = local.instance_ipv4
    }
  }
}

data "external" "kubeconfig" {
  depends_on = [null_resource.k3s_install]
  program = ["bash", "${path.module}/get-kubeconfig.sh"]
  
  query = {
    instance_ipv4 = local.instance_ipv4
    instance_username = local.instance_username
    instance_ssh_port = local.instance_ssh_port
  }
}

locals {
  kubeconfig_content = base64decode(data.external.kubeconfig.result.content)
}

resource "local_file" "kubeconfig_file" {
  depends_on = [data.external.kubeconfig]
  content    = local.kubeconfig_content
  filename   = "${path.module}/kubeconfig" # coming across as ./kubeconfig which isn't great when trying to use it in a different directory
  file_permission = "0600"  # Restrict permissions as kubeconfig contains sensitive data
}
