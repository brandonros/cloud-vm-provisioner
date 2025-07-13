variable "domain" {
  type        = string
  description = "Domain"
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 0
}

# Let's Encrypt issuer - only created when protocol_type is "https" (for TLS certificates)
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/issuer.yaml",
      {
        app_name = var.app_name
        domain   = var.domain
      }
    )
  )
}

# TLS Certificate - only created when protocol_type is "https"
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
        domain   = var.domain
      }
    )
  )
}

# HTTPS Gateway - only created when protocol_type is "https"
resource "kubernetes_manifest" "https_gateway" {  
  depends_on = [
    kubernetes_manifest.domain_prod_tls_certificate,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/https-gateway.yaml",
      {
        app_name = var.app_name
        domain   = var.domain
      }
    )
  )
}