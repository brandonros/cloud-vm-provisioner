terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.42.0"
    }
  }
}

provider "google" {
  credentials = file("~/gcp/service-account-key.json")
  project = "hyperswitch-poc"
  region  = "us-east1" # Set your desired region
}

resource "google_compute_instance" "my_instance" {
  name         = "my-instance"
  machine_type = "n2-standard-2" # 2 vCPUs, 8.0 GiB, nested virtualization, $0.0971/hr
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12" # Debian 12 x64
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "109486927228315081685:${file("~/.ssh/id_rsa.pub")}"
  }

  // Enable nested virtualization
  advanced_machine_features {
    enable_nested_virtualization = true
  }
}

output "instance_username" {
  value = "109486927228315081685" # from gcloud compute os-login describe-profile --project=hyperswitch-poc
}

output "instance_ipv4" {
  value = google_compute_instance.my_instance.network_interface[0].access_config[0].nat_ip
}
