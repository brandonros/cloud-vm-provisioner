# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a cloud VM provisioner that uses Terraform to set up multi-cloud infrastructure with K3s Kubernetes clusters and a complete observability stack. The project supports AWS, Azure, DigitalOcean, Google Cloud, Hetzner, Lima (local VMs), Oracle, and Vultr.

## Core Commands

The main interface is the `./cli` bash script:

- `./cli create` - Full deployment pipeline: provisions VM, installs K3s, deploys platform services, and workloads
- `./cli connect` - SSH into the provisioned instance  
- `./cli cleanup` - Destroys all infrastructure and cleans up local state files
- `./cli help` - Show usage information

### Environment Variables

Set `CLOUD_PROVIDER` to one of: `aws`, `azure`, `digitalocean`, `google_cloud`, `hetzner`, `lima`, `local`, `oracle`, `vultr`

Each provider requires specific credentials (see README.md for details).

## Architecture

The project uses a 4-stage Terraform deployment pipeline:

### Stage 1: VM Provisioning (`terraform/00-vm/`)
- Modular cloud provider implementations in `modules/` subdirectory
- Each provider module outputs: `instance_ipv4`, `instance_username`, `instance_ssh_port`
- Currently configured to use `local` provider (see `main.tf:5`)

### Stage 2: K3s Installation (`terraform/01-k3s/`)
- `00-dependencies`: Installs required packages via `setup.sh`
- `01-k3s`: Installs K3s cluster via `install.sh` 
- `02-kubeconfig`: Retrieves kubeconfig file for cluster access

### Stage 3: Platform Services (`terraform/02-platform/`)
- Deploys core infrastructure: cert-manager, traefik, gateway-api
- Observability stack: grafana, loki, tempo, mimir, alloy
- Metrics collection: node-exporter, kube-state-metrics
- Database stack: postgresql, pgbouncer, postgrest, postgres-exporter
- Uses Helm provider with YAML manifests in `manifests/` directory

### Stage 4: Workloads (`terraform/03-workloads/`)
- Application deployment with configurable routing, DNS, and TLS
- Modular design: `dns/`, `gateway/`, `routing/`, `tls/` modules
- Applications defined in `local.applications` block
- Routing configuration in `local.routing_config` block

## Key Components

### CLI Script (`./cli`)
- Handles dependency checks, credential validation, SSH key management
- Manages SSH tunnels for K3s API access (port 6443)
- Orchestrates the 4-stage deployment pipeline
- Handles cleanup of Terraform state and temporary files

### State Management
- Uses local Terraform backends
- Cross-stage state sharing via `terraform_remote_state` data sources
- State files: `terraform.tfstate` in each stage directory

### Provider Modules
Cloud provider implementations are in `terraform/00-vm/modules/[provider]/`. Each must implement the standard output interface for seamless switching between providers.

## Development Notes

- No package.json, Makefile, or formal build system - uses bash and Terraform directly
- No formal testing framework - validation happens through deployment
- Configuration is primarily environment variable driven
- The project uses Terraform remote state data sources for inter-stage communication