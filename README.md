# cloud-vm-provisioner
Terraform configurations for provisioning VMs across cloud providers

## Requirements

* Terraform
* ssh
* nc
* jq

## How to use

```
$ ./cli help
Usage: cli <command>

Commands:
  create      Create a new instance
  connect     SSH into the instance
  cleanup     Destroy the instance and clean up local files
  help        Show this help message
```

## Example

```shell
./cli create
cp terraform/01-k3s/modules/02-kubeconfig/kubeconfig ~/.kube/config
sudo kubefwd svc -n grafana -n rabbitmq  -n alloy
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
