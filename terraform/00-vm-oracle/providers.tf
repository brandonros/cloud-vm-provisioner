terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.18.0"
    }
  }
}

# Oracle Cloud Infrastructure Provider
provider "oci" {
  # Configuration comes from environment variables or OCI config file
  # TF_VAR_tenancy_ocid, TF_VAR_user_ocid, TF_VAR_private_key_path, 
  # TF_VAR_fingerprint, TF_VAR_region should be set in environment
}