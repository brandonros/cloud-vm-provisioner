terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.43.0"
    }
  }
}

provider "digitalocean" {
    // depends on DIGITALOCEAN_TOKEN
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a new Droplet using the SSH key
resource "digitalocean_droplet" "droplet1" {
  image    = "debian-12-x64"
  name     = "droplet1"
  region   = "nyc3"
  size     = "s-4vcpu-16gb-amd" # 4 vCPU, 16 GB, $0.125/hr
  ssh_keys = [digitalocean_ssh_key.ssh_key.fingerprint]
}
