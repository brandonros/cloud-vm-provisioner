terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "2.21.0"
    }
  }
}

provider "vultr" {
    # uses VULTR_API_KEY env var
}

resource "vultr_ssh_key" "my_ssh_key" {
  name = "my_ssh_key"
  ssh_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "vultr_instance" "my_instance" {
    plan = "vc2-4c-8gb" # 4 vCPUs, 8 GB, $0.056/hr
    region = "atl"
    os_id = 2136 # bookworm
    hostname = "instance1"
    ssh_key_ids = [resource.vultr_ssh_key.my_ssh_key.id]
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

output "instance_username" {
  value = "debian"
}

output "instance_ipv4" {
  value = vultr_instance.my_instance.main_ip
}