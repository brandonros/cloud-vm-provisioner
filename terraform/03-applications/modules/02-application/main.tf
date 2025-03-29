variable "domain" {
  type = string
  description = "Domain"
}

variable "app_name" {
  type = string
  description = "Application name"
} 

variable "container_port" {
  type = number
  description = "Container port"
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

resource "helm_release" "app" {  
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

resource "kubernetes_manifest" "app_http_route" {
  depends_on = [
    helm_release.app,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-route.yaml",
      {
        app_name = var.app_name
      }
    )
  )
}

resource "kubernetes_manifest" "app_https_route" {  
  depends_on = [
    helm_release.app,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/https-route.yaml",
      {
        app_name = var.app_name
        domain = var.domain
      }
    )
  )
}

resource "kubernetes_manifest" "app_reference_grant" {  
  depends_on = [
    kubernetes_manifest.app_https_route,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/reference-grant.yaml",
      {
        app_name = var.app_name
      }
    )
  )
}
