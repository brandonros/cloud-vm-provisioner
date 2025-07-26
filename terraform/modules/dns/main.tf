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

module "duckdns_updater" {
  source = "../helm-release"
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
