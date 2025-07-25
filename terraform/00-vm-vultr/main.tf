
resource "vultr_ssh_key" "my_ssh_key" {
  name = "my_ssh_key"
  ssh_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "vultr_instance" "my_instance" {
    #plan = "vc2-1c-1gb" # 1 vCPU, 1 GB
    plan = "vc2-2c-4gb" # 2 vCPUs, 4 GB
    #plan = "vhf-4c-16gb" # 4 vCPUs, 16 GB
    #plan = "voc-c-8c-16gb-150s-amd" # CPU Optimized Cloud, 8 vCPUs, 16 GB
    region = "atl"
    os_id = 2136 # bookworm
    hostname = "debian-k3s"
    ssh_key_ids = [
      resource.vultr_ssh_key.my_ssh_key.id,
    ]
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
