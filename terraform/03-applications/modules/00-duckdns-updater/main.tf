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

variable "manifest" {
  description = "The parsed manifest configuration"
  type = object({
    metadata = object({
      name      = string
      namespace = string
    })
    spec = object({
      repo            = string
      chart           = string
      version         = string
      targetNamespace = string
      createNamespace = bool
      valuesContent   = string
    })
  })
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

resource "helm_release" "duckdns_updater" {  
  depends_on = [
    kubernetes_namespace.duckdns_updater,
    kubernetes_secret.duckdns_token,
  ]

  name       = var.manifest.metadata.name
  repository = var.manifest.spec.repo
  chart      = var.manifest.spec.chart
  namespace  = var.manifest.spec.targetNamespace
  version    = var.manifest.spec.version
  values = [
    var.manifest.spec.valuesContent
  ]
  create_namespace = var.manifest.spec.createNamespace
  wait_for_jobs = true
}
