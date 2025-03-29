module "dependencies" {
  source = "./modules/00-dependencies"
}

module "k3s" {
  source = "./modules/01-k3s"
  depends_on = [module.dependencies]
}

module "kubeconfig" {
  source = "./modules/02-kubeconfig"
  depends_on = [module.k3s]
}
