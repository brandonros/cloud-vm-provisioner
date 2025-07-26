terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Hetzner Cloud Provider
provider "hcloud" {
  # HCLOUD_TOKEN comes from env var
}