terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.42.0"
    }
  }
}

# Google Cloud Provider
provider "google" {
  # GOOGLE_APPLICATION_CREDENTIALS comes from env var (path to service account key)
  # Or use gcloud auth application-default login
}