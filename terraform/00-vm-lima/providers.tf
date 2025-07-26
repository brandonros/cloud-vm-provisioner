terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

# Lima uses null provider for local VM management
# No explicit provider configuration needed