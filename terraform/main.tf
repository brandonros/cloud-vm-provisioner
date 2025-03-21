module "vultr" {
  source = "./modules/vultr"
}

module "setup" {
  source = "./modules/setup"
  instance_ip = module.vultr.instance_ipv4
  instance_username = module.vultr.instance_username
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
