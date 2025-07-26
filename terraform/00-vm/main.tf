# AWS Provider
module "vm_aws" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  source = "./modules/aws"
  providers = {
    aws = aws
  }
}

# Azure Provider
module "vm_azure" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "./modules/azure"
  providers = {
    azurerm = azurerm
  }
}

# DigitalOcean Provider
module "vm_digitalocean" {
  count  = var.cloud_provider == "digitalocean" ? 1 : 0
  source = "./modules/digitalocean"
  providers = {
    digitalocean = digitalocean
  }
}

# Google Cloud Provider
module "vm_google_cloud" {
  count  = var.cloud_provider == "google_cloud" ? 1 : 0
  source = "./modules/google_cloud"
  providers = {
    google = google
  }
}

# Hetzner Provider
module "vm_hetzner" {
  count  = var.cloud_provider == "hetzner" ? 1 : 0
  source = "./modules/hetzner"
  providers = {
    hcloud = hcloud
  }
}

# Lima Provider
module "vm_lima" {
  count  = var.cloud_provider == "lima" ? 1 : 0
  source = "./modules/lima"
}

# Local Provider
module "vm_local" {
  count  = var.cloud_provider == "local" ? 1 : 0
  source = "./modules/local"
}

# Oracle Provider
module "vm_oracle" {
  count  = var.cloud_provider == "oracle" ? 1 : 0
  source = "./modules/oracle"
  providers = {
    oci = oci
  }
}

# Vultr Provider
module "vm_vultr" {
  count  = var.cloud_provider == "vultr" ? 1 : 0
  source = "./modules/vultr"
  providers = {
    vultr = vultr
  }
}

# Consolidate outputs from the active provider
locals {
  # Get the outputs from whichever module is active
  active_vm = coalesce(
    try(module.vm_aws[0], null),
    try(module.vm_azure[0], null),
    try(module.vm_digitalocean[0], null),
    try(module.vm_google_cloud[0], null),
    try(module.vm_hetzner[0], null),
    try(module.vm_lima[0], null),
    try(module.vm_local[0], null),
    try(module.vm_oracle[0], null),
    try(module.vm_vultr[0], null)
  )
}
