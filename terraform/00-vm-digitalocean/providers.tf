terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.43.0"
    }
  }
}

# DigitalOcean Provider
provider "digitalocean" {
  # DIGITALOCEAN_TOKEN comes from env var
}