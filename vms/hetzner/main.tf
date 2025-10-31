terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  # HCLOUD_TOKEN comes from env var
}

locals {
  install_k3s        = false
  install_llvm       = false
  allowed_api_cidrs  = []
  ssh_authorized_key = file("~/.ssh/id_rsa.pub")
  # echo "hihaters" | openssl passwd -6 -salt ovSvGqIVXC9lTasZ -in -
  user_password_hash = "$6$ovSvGqIVXC9lTasZ$T3YJyx/ew41tndVvqPCV3xZ6tpGTQyQJNXfn/mQ7s9xfvjUy.1g2xLccyW9CattET53xi9Z4REzoNY7iO3Bhw1"
}

resource "hcloud_server" "server1" {
  name  = "server1"
  image = "debian-12"
  #datacenter  = "hel1-dc2"
  #server_type = "cax11"
  datacenter  = "ash-dc1" # Ashburn, Virginia, USA
  server_type = "cpx41"   # 8 vCPU, 32 GB, $0.051/hr
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  user_data = templatefile("${path.module}/../cloud-config.yaml.tpl", {
    install_k3s        = local.install_k3s
    install_llvm       = local.install_llvm
    allowed_api_cidrs  = local.allowed_api_cidrs
    ssh_authorized_key = local.ssh_authorized_key
    user_password_hash = local.user_password_hash
  })
}

output "server_id" {
  value = hcloud_server.server1.id
}

output "server_ipv4" {
  value = hcloud_server.server1.ipv4_address
}
