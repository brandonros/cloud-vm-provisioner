terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

# Local uses null provider for local development
# No explicit provider configuration needed