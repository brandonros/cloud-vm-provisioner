variable "domain" {
  type        = string
  description = "Domain"
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "protocol_type" {
  type        = string
  description = "Protocol type: 'http' or 'tcp'"
  default     = "http"
  validation {
    condition     = contains(["http", "tcp"], var.protocol_type)
    error_message = "Protocol type must be either 'http' or 'tcp'."
  }
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 0
}

# HTTP Gateway - only created when protocol_type is "http"
resource "kubernetes_manifest" "http_gateway" {
  count = var.protocol_type == "http" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-gateway.yaml",
      {
        app_name = var.app_name
        domain   = var.domain
      }
    )
  )
}

# TCP Gateway - only created when protocol_type is "tcp"
resource "kubernetes_manifest" "tcp_gateway" {
  count = var.protocol_type == "tcp" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/tcp-gateway.yaml",
      {
        app_name = var.app_name
        container_port = var.container_port
      }
    )
  )
}

# Let's Encrypt issuer - only created when protocol_type is "http" (for TLS certificates)
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  count = var.protocol_type == "http" ? 1 : 0
  
  depends_on = [
    kubernetes_manifest.http_gateway,
  ]

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

# TLS Certificate - only created when protocol_type is "http"
resource "kubernetes_manifest" "domain_prod_tls_certificate" {
  count = var.protocol_type == "http" ? 1 : 0
  
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

# HTTPS Gateway - only created when protocol_type is "http"
resource "kubernetes_manifest" "https_gateway" {
  count = var.protocol_type == "http" ? 1 : 0
  
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