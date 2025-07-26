terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.6"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 6.18"
    }
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Azure Provider
provider "azurerm" {
  features {}
}

# DigitalOcean Provider
provider "digitalocean" {
}

# Google Cloud Provider
provider "google" {
  credentials = file("~/gcp/service-account-key.json")
  project = "kubevirt-poc"
  region  = "us-east1"
}

# Hetzner Cloud Provider
provider "hcloud" {
}

# Oracle Cloud Provider
provider "oci" {
  # These should be set as environment variables:
  # OCI_TENANCY_OCID
  # OCI_USER_OCID
  # OCI_PRIVATE_KEY_PATH
  # OCI_FINGERPRINT
  # OCI_REGION
}

# Vultr Provider
provider "vultr" {
}