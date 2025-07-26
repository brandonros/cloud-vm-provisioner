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