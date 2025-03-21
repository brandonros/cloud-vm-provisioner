module "vultr" {
  source = "./modules/vultr"
}

module "setup" {
  source = "./modules/setup"
  instance_ip = module.vultr.instance_ipv4
  instance_username = module.vultr.instance_username
}
