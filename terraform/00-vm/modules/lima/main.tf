terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

locals {
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}

resource "null_resource" "lima_vm" {
  provisioner "local-exec" {
    command = <<-EOT
      if ! limactl list | grep -q "debian-k3s"; then
        # TODO: envsubst because we have a variable for an ssh key in the yaml file?
        limactl start ./debian-k3s.yaml
        limactl shell debian-k3s bash -c '
          mkdir -p /home/debian/.ssh
          echo "${local.ssh_public_key}" > /home/debian/.ssh/authorized_keys
          chown -R debian:debian /home/debian/.ssh
          chmod 700 /home/debian/.ssh
          chmod 600 /home/debian/.ssh/authorized_keys
        '
        limactl list debian-k3s --format='{{.SSHAddress}}:{{.SSHLocalPort}}' > /tmp/vm_info.txt
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "limactl stop -f debian-k3s && limactl delete debian-k3s && rm -f /tmp/vm_info.txt"
  }
}

data "local_file" "vm_info" {
  depends_on = [null_resource.lima_vm]
  filename = "/tmp/vm_info.txt"
}

locals {
  split_vm_info = split(":", trimspace(data.local_file.vm_info.content))
}

output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = local.split_vm_info[0]
}

output "ssh_port" {
  value = local.split_vm_info[1]
}