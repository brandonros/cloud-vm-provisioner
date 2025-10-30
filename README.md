# cloud-vm-provisioner
Terraform configurations for provisioning VMs across cloud providers

## Requirements

* Terraform
* ssh
* nc
* helm

## How to use

```
$ just
Available recipes:
    cleanup
    deploy chart='' release='' namespace='' kubeconfig='' repo='' version=''
    fetch-kubeconfig server_ip=''
    go
    install-gateway-api kubeconfig=''
    provision-vm
```

## Supported cloud providers

* AWS
* Azure
* DigitalOcean
* Google Cloud
* Hetzner
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

### DigitalOcean
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
