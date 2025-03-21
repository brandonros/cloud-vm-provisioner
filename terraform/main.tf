variable "duckdns_token" {
  type = string
  description = "DuckDNS token"
}

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

module "vultr" {
  source = "./modules/vultr"
}

module "setup" {
  source = "./modules/setup"
  instance_ip = module.vultr.instance_ipv4
  instance_username = module.vultr.instance_username
  duckdns_token = var.duckdns_token
  duckdns_domain = var.duckdns_domain
}

output "instance_ipv4" {
  value = module.vultr.instance_ipv4
}

output "instance_username" {
  value = module.vultr.instance_username
}

output "ssh_port" {
  value = module.vultr.ssh_port
}
