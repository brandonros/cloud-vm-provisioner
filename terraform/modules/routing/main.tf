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
}

variable "protocol_type" {
  type        = string
  description = "Protocol type: 'http', 'https' or 'tcp'"
  default     = "http"
  validation {
    condition     = contains(["http", "https", "tcp"], var.protocol_type)
    error_message = "Protocol type must be either 'http', 'https' or 'tcp'."
  }
}

# HTTP Route - only created when protocol_type is "http"
resource "kubernetes_manifest" "app_http_route" {
  count = var.protocol_type == "http" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-route.yaml",
      {
        app_name = var.app_name,
        domain   = var.domain,
        container_port = var.container_port
      }
    )
  )
}

# HTTP Redirect Route - only created when protocol_type is "http"
resource "kubernetes_manifest" "app_http_redirect_route" {
  count = var.protocol_type == "https" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-redirect-route.yaml",
      {
        app_name = var.app_name,
        domain   = var.domain
      }
    )
  )
}

# HTTPS Route - only created when protocol_type is "http"  
resource "kubernetes_manifest" "app_https_route" {
  count = var.protocol_type == "https" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/https-route.yaml",
      {
        app_name       = var.app_name,
        domain         = var.domain,
        container_port = var.container_port
      }
    )
  )
}

# TCP Route - only created when protocol_type is "tcp"
resource "kubernetes_manifest" "app_tcp_route" {
  count = var.protocol_type == "tcp" ? 1 : 0
  
  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/tcp-route.yaml",
      {
        app_name       = var.app_name,
        container_port = var.container_port
      }
    )
  )
}

# Reference Grant for HTTP/HTTPS - only created when protocol_type is "http"
resource "kubernetes_manifest" "app_http_reference_grant" {
  count = var.protocol_type == "http" || var.protocol_type == "https" ? 1 : 0
  
  depends_on = [
    kubernetes_manifest.app_https_route,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/http-reference-grant.yaml",
      {
        app_name = var.app_name
      }
    )
  )
}

# Reference Grant for TCP - only created when protocol_type is "tcp"
resource "kubernetes_manifest" "app_tcp_reference_grant" {
  count = var.protocol_type == "tcp" ? 1 : 0
  
  depends_on = [
    kubernetes_manifest.app_tcp_route,
  ]

  manifest = yamldecode(
    templatefile(
      "${path.module}/manifests/tcp-reference-grant.yaml",
      {
        app_name = var.app_name
      }
    )
  )
}