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

resource "kubernetes_namespace" "duckdns_updater" {
  metadata {
    name = "${var.app_name}-duckdns-updater"
  }
}

# Create a Kubernetes secret for the DuckDNS token
resource "kubernetes_secret" "duckdns_token" {
  depends_on = [
    kubernetes_namespace.duckdns_updater,
  ]

  metadata {
    name      = "duckdns-token"
    namespace = "${var.app_name}-duckdns-updater"
  }

  data = {
    token = var.duckdns_token
  }
}

locals {
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/duckdns-updater.yaml",
      {
        app_name = var.app_name
        duckdns_domain = var.duckdns_domain
      }
    )
  )
}

resource "helm_release" "duckdns_updater" {  
  depends_on = [
    kubernetes_namespace.duckdns_updater,
    kubernetes_secret.duckdns_token,
  ]

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
