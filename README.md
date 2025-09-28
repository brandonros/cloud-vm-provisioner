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

## Examples

```shell
$ cargo install just
$ just
Available recipes:
    all                         # Run all stages: vm, k3s, platform, workloads, routing
    apps                        # Deploy applications only (platform + workloads + routing)
    check-cloud-creds           # Check cloud provider credentials
    check-deps                  # Check required dependencies
    check-instance-state        # Check that instance state is loaded
    check-ssh-key               # Check SSH key exists
    check-tunnel                # Check that tunnel is running
    cleanup                     # Clean up all resources and local state
    connect                     # Connect to the provisioned instance via SSH
    create-tunnel               # Create SSH tunnel for K3s API access
    default                     # Default recipe - shows available commands
    destroy stage               # Destroy specific stage
    from stage                  # Run from a specific stage onwards
    info                        # Show current instance details
    infra                       # Deploy infrastructure only (VM + K3s)
    k3s                         # Stage 2: Install K3s on the VM
    load-instance-details       # Load instance details from terraform output
    platform                    # Deploy all platform services in logical order
    platform-alloy
    platform-cert-manager
    platform-core               # Deploy core infrastructure (essential networking & security)
    platform-database           # Deploy database stack
    platform-gateway-api        # Core infrastructure services
    platform-grafana            # Monitoring services
    platform-kube-state-metrics
    platform-loki               # Observability services
    platform-metrics-server
    platform-mimir
    platform-monitoring         # Deploy monitoring stack
    platform-nginx              # Web services
    platform-node-exporter
    platform-observability      # Deploy observability stack
    platform-pgbouncer
    platform-postgres-exporter
    platform-stalwart           # E-mail services
    platform-postgresql         # Database services
    platform-mssql         
    platform-postgrest
    platform-rabbitmq           # Messaging services
    platform-tempo
    platform-traefik
    routing                     # Deploy all routing configurations
    routing-grafana
    routing-nginx
    routing-postgresql
    routing-postgrest
    routing-rpc-consumer
    routing-rpc-dispatcher
    vm                          # Stage 1: Provision VM infrastructure
    wait-and-accept             # Wait for host and accept SSH key
    workload-rpc-consumer
    workload-rpc-dispatcher
    workloads                   # Deploy all workloads
```

### Create and connect to a new VM

```
$ just vm wait-and-accept connect
```

### Create a VM with k3s provisioned

```
just vm wait-and-accept create-tunnel k3s platform-core platform-nginx routing-nginx
```

### Clean up

```
just vm cleanup
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
