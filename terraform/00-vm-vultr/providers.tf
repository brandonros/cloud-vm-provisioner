terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

# Vultr Provider
provider "vultr" {
  # API key comes from VULTR_API_KEY env var
}