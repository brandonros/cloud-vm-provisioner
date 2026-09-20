terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.19"
    }
  }
}

provider "vultr" {
  # VULTR_API_KEY comes from env var
}

resource "vultr_instance" "server1" {
  #plan   = "vc2-1c-2gb"      # 1 vCPU, 2 GB (Windows minimum)
  #plan   = "vc2-2c-4gb"       # 2 vCPUs, 4 GB
  plan   = "vhf-4c-16gb"     # 4 vCPUs, 16 GB
  region = "atl"
  os_id  = 2514               # Windows Server 2025 Standard
  hostname = "server1"
}

output "server_id" {
  value = vultr_instance.server1.id
}

output "server_ipv4" {
  value = vultr_instance.server1.main_ip
}

# terraform output -raw default_password
output "default_password" {
  value     = vultr_instance.server1.default_password
  sensitive = true
}
