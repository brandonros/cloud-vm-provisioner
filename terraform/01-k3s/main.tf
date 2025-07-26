module "dependencies" {
  source = "./modules/00-dependencies"
  cloud_provider = var.cloud_provider
}

module "k3s" {
  source = "./modules/01-k3s"
  cloud_provider = var.cloud_provider
  depends_on = [module.dependencies]
}

module "kubeconfig" {
  source = "./modules/02-kubeconfig"
  cloud_provider = var.cloud_provider
  depends_on = [module.k3s]
}
