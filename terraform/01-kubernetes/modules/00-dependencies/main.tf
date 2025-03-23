data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "${path.module}/../../../00-infrastructure/terraform.tfstate"
  }
}

locals {
  instance_ipv4 = data.terraform_remote_state.infrastructure.outputs.instance_ipv4
  instance_username = data.terraform_remote_state.infrastructure.outputs.instance_username
  instance_ssh_port = data.terraform_remote_state.infrastructure.outputs.instance_ssh_port
}

resource "null_resource" "dependencies" {
  provisioner "remote-exec" {
    inline = [<<EOT
      #!/bin/bash
      # Update package list
      sudo apt-get update

      # Upgrade all installed packages to their latest versions
      sudo apt-get -y upgrade

      # Dist-upgrade all installed packages to their latest versions
      sudo apt-get -y dist-upgrade
      # TODO: i think this is bad practice because we don't reboot into the new kernel after

      # Install required packages
      sudo apt-get -y install acl htop psmisc netcat-traditional

      # Remove unused packages
      sudo apt-get -y autoremove

      # Install k9s
      if ! command -v k9s &> /dev/null; then
          wget https://github.com/derailed/k9s/releases/download/v0.40.5/k9s_linux_amd64.deb
          sudo apt install -y ./k9s_linux_*.deb
          rm k9s_linux_*.deb
      else
          echo "k9s is already installed"
      fi
    EOT
    ]

    connection {
      type        = "ssh"
      user        = local.instance_username
      private_key = file("~/.ssh/id_rsa")
      host        = local.instance_ipv4
    }
  }
}
