# cloud-vm-provisioner
Terraform configurations for provisioning VMs across cloud providers

## How to use

```
$ ./cli help
Usage: cli <command>

Commands:
  create      Create a new instance
  apply       Apply Kubernetes manifests to the instance
  connect     SSH into the instance
  cleanup     Destroy the instance and clean up local files
  help        Show this help message
```

## Supported cloud providers

* AWS
* Azure
* DigitalOcean
* Google Cloud
* Hetzner
* Lima (VM)
* Oracle
* Vultr

## Environment variables

### Cloud provider
* `CLOUD_PROVIDER`

### AWS
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

### Azure
* `ARM_SUBSCRIPTION_ID`

### Digital Ocean
* `DIGITALOCEAN_TOKEN`

### Google Cloud
* `GOOGLE_APPLICATION_CREDENTIALS`

### Hetzner
* `HCLOUD_TOKEN`

### Oracle
* `OCI_PRIVATE_KEY_PATH`
* `OCI_FINGERPRINT`
* `OCI_TENANCY_OCID`
* `OCI_USER_OCID`
* `OCI_REGION`

### Vultr
* `VULTR_API_KEY`

### DuckDNS
* `DUCKDNS_TOKEN`
* `DUCKDNS_WORDPRESS_DOMAIN`
* `DUCKDNS_PDF_GENERATOR_DOMAIN`
