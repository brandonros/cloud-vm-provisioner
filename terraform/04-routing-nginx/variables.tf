variable "cloud_provider" {
  description = "The cloud provider used for VM provisioning"
  type        = string
  default     = "local"
  
  validation {
    condition = contains([
      "aws",
      "azure",
      "digitalocean",
      "google_cloud",
      "hetzner",
      "lima",
      "local",
      "oracle",
      "vultr"
    ], var.cloud_provider)
    error_message = "Invalid cloud provider. Must be one of: aws, azure, digitalocean, google_cloud, hetzner, lima, local, oracle, vultr"
  }
}

variable "duckdns_token" {
  type        = string
  description = "DuckDNS token for DNS management"
  default     = ""
}

variable "enable_dns" {
  type        = bool
  description = "Whether to manage DNS records"
  default     = true
}

variable "enable_tls" {
  type        = bool
  description = "Whether to enable TLS certificates"
  default     = true
}

variable "enable_routing" {
  type        = bool
  description = "Whether to enable routing/ingress"
  default     = true
}