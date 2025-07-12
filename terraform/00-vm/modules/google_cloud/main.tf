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
  project = "kubevirt-poc" # create this manually
  region  = "us-east1" # Set your desired region
}

variable "os_login_user_id" {
  type        = string
  default     = "109486927228315081685" # from gcloud compute os-login describe-profile
}

resource "google_compute_instance" "my_instance" {
  name         = "my-instance"
  machine_type = "t2d-standard-4" # 4 vCPUs, 16.0 GiB, $0.1690/hr
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
    ssh-keys = "${var.os_login_user_id}:${file("~/.ssh/id_rsa.pub")}"
  }

  // Enable nested virtualization
  advanced_machine_features {
    enable_nested_virtualization = true
  }
}
