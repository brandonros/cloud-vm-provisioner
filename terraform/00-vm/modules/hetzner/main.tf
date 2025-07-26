# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

resource "hcloud_ssh_key" "ssh_key" {
  name       = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a new server running debian
resource "hcloud_server" "server1" {
  name        = "server1"
  image       = "debian-12"
  datacenter  = "ash-dc1" # Ashburn, Virginia, USA
  server_type = "cpx41" # 8 vCPU, 32 GB, $0.051/hr
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  ssh_keys = [hcloud_ssh_key.ssh_key.id]
  user_data = <<EOF
#cloud-config
users:
  - name: debian
    gecos: "Debian"
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$ovSvGqIVXC9lTasZ$T3YJyx/ew41tndVvqPCV3xZ6tpGTQyQJNXfn/mQ7s9xfvjUy.1g2xLccyW9CattET53xi9Z4REzoNY7iO3Bhw1 # echo "hihaters" | openssl passwd -6 -salt ovSvGqIVXC9lTasZ -in -
    ssh_authorized_keys:
      - ${file("~/.ssh/id_rsa.pub")}
EOF
}
