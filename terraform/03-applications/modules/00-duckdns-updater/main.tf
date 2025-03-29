variable "duckdns_token" {
  type = string
  description = "DuckDNS token"
}

variable "duckdns_domain" {
  type = string
  description = "DuckDNS domain"
}

variable "app_name" {
  type = string
  description = "Application name"
}

locals {
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/duckdns-updater.yaml",
      {
        app_name = var.app_name
        duckdns_domain = var.duckdns_domain
        duckdns_token = var.duckdns_token
      }
    )
  )
}

resource "helm_release" "duckdns_updater" {  
  name       = local.manifest.metadata.name
  repository = local.manifest.spec.repo
  chart      = local.manifest.spec.chart
  namespace  = local.manifest.spec.targetNamespace
  version    = local.manifest.spec.version
  values = [
    local.manifest.spec.valuesContent
  ]
  create_namespace = local.manifest.spec.createNamespace
  wait_for_jobs = true
}
