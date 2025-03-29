variable "domain" {
  type = string
  description = "Domain"
}

variable "app_name" {
  type = string
  description = "Application name"
}

resource "kubernetes_manifest" "http_gateway" {
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-gateway.yaml",
      {
        app_name = var.app_name
        domain = var.domain
      }
    )
  )
}

resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  depends_on = [
    kubernetes_manifest.http_gateway,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/issuer.yaml",
      {
        app_name = var.app_name
        domain = var.domain
      }
    )
  )
}

resource "kubernetes_manifest" "domain_prod_tls_certificate" {
  depends_on = [
    kubernetes_manifest.letsencrypt_prod_issuer,
  ]

  timeouts {
    create = "10m"
    update = "10m"
  }

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/certificate.yaml",
      {
        app_name = var.app_name
        domain = var.domain
      }
    )
  )
}

resource "kubernetes_manifest" "https_gateway" {
  depends_on = [
    kubernetes_manifest.domain_prod_tls_certificate,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/https-gateway.yaml",
      {
        app_name = var.app_name
        domain = var.domain
      }
    )
  )
}
