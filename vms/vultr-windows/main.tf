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
  # vc2 = Cloud Compute (regular, cheapest), vhf = High Frequency (3GHz+ Intel, NVMe),
  # vhp = High Performance (newer AMD/Intel, NVMe), voc = Optimized Cloud (dedicated vCPUs;
  # -c cpu, -g general, -m memory, -s storage). Not every plan is in every region:
  # curl -s https://api.vultr.com/v2/regions/atl/availability
  plan   = "vhp-4c-8gb-amd"     # 4 vCPUs, 8 GB
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
