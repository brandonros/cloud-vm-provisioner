#!/usr/bin/env just --justfile

# Cloud VM Provisioner - Justfile
# This replicates the functionality of ./cli script

set shell := ["bash", "-euo", "pipefail", "-c"]
set export

# Default cloud provider (can be overridden with env var)
export CLOUD_PROVIDER := env_var_or_default("CLOUD_PROVIDER", "vultr")
export TF_SKIP_PROVIDER_VERIFY := "true"
export ARM_SUBSCRIPTION_ID := "16c3f0f7-3a06-449e-8ac6-ec2d63078996"

script_path := justfile_directory()

# Default recipe - shows available commands
default:
    @just --list

# Run all stages: vm, k3s, platform, workloads, routing
all: check-deps check-ssh-key check-cloud-creds vm wait-and-accept k3s create-tunnel platform workloads routing

# Stage 1: Provision VM infrastructure
vm: check-deps check-ssh-key check-cloud-creds
    #!/usr/bin/env bash
    set -e
    echo "🚀 Provisioning VM infrastructure..."
    cd {{ script_path }}/terraform/00-vm-${CLOUD_PROVIDER}
    terraform init
    terraform apply -auto-approve

# Stage 2: Install K3s on the VM
k3s: check-instance-state
    #!/usr/bin/env bash
    set -e
    echo "🚀 Installing K3s cluster..."
    cd {{ script_path }}/terraform/01-k3s-install
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Stage 3: Deploy platform services (legacy - deploys all)
platform-legacy: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying platform services (legacy)..."
    cd {{ script_path }}/terraform/02-platform
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# === Individual Platform Services ===

# Core infrastructure services
platform-gateway-api: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Gateway API..."
    cd {{ script_path }}/terraform/02-platform-gateway-api
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-cert-manager: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying cert-manager..."
    cd {{ script_path }}/terraform/02-platform-cert-manager
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-traefik: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Traefik..."
    cd {{ script_path }}/terraform/02-platform-traefik
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-metrics-server: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Metrics Server..."
    cd {{ script_path }}/terraform/02-platform-metrics-server
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Database services
platform-postgresql: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying PostgreSQL..."
    cd {{ script_path }}/terraform/02-platform-postgresql
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-pgbouncer: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying PgBouncer..."
    cd {{ script_path }}/terraform/02-platform-pgbouncer
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-postgrest: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying PostgREST..."
    cd {{ script_path }}/terraform/02-platform-postgrest
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-postgres-exporter: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Postgres Exporter..."
    cd {{ script_path }}/terraform/02-platform-postgres-exporter
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Monitoring services
platform-grafana: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Grafana..."
    cd {{ script_path }}/terraform/02-platform-grafana
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-mimir: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Mimir..."
    cd {{ script_path }}/terraform/02-platform-mimir
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-alloy: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Alloy..."
    cd {{ script_path }}/terraform/02-platform-alloy
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-node-exporter: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Node Exporter..."
    cd {{ script_path }}/terraform/02-platform-node-exporter
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-kube-state-metrics: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Kube State Metrics..."
    cd {{ script_path }}/terraform/02-platform-kube-state-metrics
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Observability services
platform-loki: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Loki..."
    cd {{ script_path }}/terraform/02-platform-loki
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

platform-tempo: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying Tempo..."
    cd {{ script_path }}/terraform/02-platform-tempo
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Messaging services
platform-rabbitmq: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying RabbitMQ..."
    cd {{ script_path }}/terraform/02-platform-rabbitmq
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# === Service Groups ===

# Deploy core infrastructure (essential networking & security)
platform-core: platform-gateway-api platform-cert-manager platform-traefik platform-metrics-server
    @echo "✅ Core platform services deployed"

# Deploy database stack
platform-database: platform-postgresql platform-pgbouncer platform-postgrest platform-postgres-exporter
    @echo "✅ Database services deployed"

# Deploy monitoring stack
platform-monitoring: platform-grafana platform-mimir platform-alloy platform-node-exporter platform-kube-state-metrics
    @echo "✅ Monitoring services deployed"

# Deploy observability stack
platform-observability: platform-loki platform-tempo
    @echo "✅ Observability services deployed"

# Deploy all platform services in logical order
platform: platform-core platform-database platform-monitoring platform-observability platform-rabbitmq
    @echo "✅ All platform services deployed"

# === Individual Workload Services ===

workload-rpc-consumer: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying RPC Consumer..."
    cd {{ script_path }}/terraform/03-workload-rpc-consumer
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

workload-rpc-dispatcher: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying RPC Dispatcher..."
    cd {{ script_path }}/terraform/03-workload-rpc-dispatcher
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Deploy all workloads
workloads: workload-rpc-consumer workload-rpc-dispatcher
    @echo "✅ All workloads deployed"

# === Layer 4: Routing/DNS/TLS Services ===

routing-postgresql: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Configuring PostgreSQL routing..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/04-routing-postgresql
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" -var="duckdns_token=${DUCKDNS_TOKEN:-}" -var="enable_dns=${ENABLE_DNS:-false}" -var="enable_tls=${ENABLE_TLS:-false}"

routing-grafana: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Configuring Grafana routing..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/04-routing-grafana
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" -var="duckdns_token=${DUCKDNS_TOKEN:-}" -var="enable_dns=${ENABLE_DNS:-false}" -var="enable_tls=${ENABLE_TLS:-false}"

routing-postgrest: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Configuring PostgREST routing..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/04-routing-postgrest
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" -var="duckdns_token=${DUCKDNS_TOKEN:-}" -var="enable_dns=${ENABLE_DNS:-false}" -var="enable_tls=${ENABLE_TLS:-false}"

routing-rpc-consumer: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Configuring RPC Consumer routing..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/04-routing-rpc-consumer
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" -var="duckdns_token=${DUCKDNS_TOKEN:-}" -var="enable_dns=${ENABLE_DNS:-false}" -var="enable_tls=${ENABLE_TLS:-false}"

routing-rpc-dispatcher: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Configuring RPC Dispatcher routing..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/04-routing-rpc-dispatcher
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" -var="duckdns_token=${DUCKDNS_TOKEN:-}" -var="enable_dns=${ENABLE_DNS:-false}" -var="enable_tls=${ENABLE_TLS:-false}"

# Deploy all routing configurations
routing: routing-postgresql routing-grafana routing-postgrest routing-rpc-consumer routing-rpc-dispatcher
    @echo "✅ All routing configurations deployed"

# Stage 4: Deploy workloads (legacy - for compatibility)
workloads-legacy:
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying workloads (legacy)..."
    export TF_VAR_duckdns_token="${DUCKDNS_TOKEN:-}"
    cd {{ script_path }}/terraform/03-workloads
    terraform init
    terraform apply -auto-approve

# Connect to the provisioned instance via SSH
connect: load-instance-details
    #!/usr/bin/env bash
    set -e
    source /tmp/vm_info.txt
    ssh -p ${instance_ssh_port} ${instance_username}@${instance_ipv4}

# Clean up all resources and local state
cleanup:
    #!/usr/bin/env bash
    set -e
    echo "🧹 Cleaning up resources..."
    
    # Kill SSH tunnels
    if pgrep -f "ssh.*-L 6443:localhost:6443.*" > /dev/null; then
        pkill -f "ssh.*-L 6443:localhost:6443.*" || true
    fi
    
    # Destroy VM infrastructure
    cd {{ script_path }}/terraform/00-vm-${CLOUD_PROVIDER}
    terraform init
    terraform destroy -auto-approve || true
    
    # Clean up temp files
    rm -f /tmp/vm_info.txt
    rm -rf {{ script_path }}/terraform/01-k3s-install/kubeconfig
    
    # Clean up all tfstate files  
    cd {{ script_path }}/terraform
    find ./00-vm-* ./01-k3s-install ./02-platform-* ./03-workload-* ./03-workloads ./04-routing-* \
        -type d -name ".terraform" -exec rm -rf {} \; -prune \
        -o -type f -name ".terraform.lock.hcl" -delete \
        -o -type f -name "*.tfstate" -delete \
        -o -type f -name "*.tfstate.backup" -delete

# --- Helper recipes ---

# Check required dependencies
check-deps:
    #!/usr/bin/env bash
    set -e
    dependencies=("terraform" "ssh" "telnet" "jq")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ $cmd is not installed"
            exit 1
        fi
    done
    echo "✅ All dependencies installed"

# Check SSH key exists
check-ssh-key:
    #!/usr/bin/env bash
    set -e
    if [ ! -e "$HOME/.ssh/id_rsa.pub" ]; then
        echo "❌ SSH key does not exist at $HOME/.ssh/id_rsa.pub"
        echo "Note: Azure does not support id_ed25519"
        exit 1
    fi
    echo "✅ SSH key found"

# Check cloud provider credentials
check-cloud-creds:
    #!/usr/bin/env bash
    set -e
    case "${CLOUD_PROVIDER}" in
        google_cloud)
            if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
                echo "❌ GOOGLE_APPLICATION_CREDENTIALS is not set"
                exit 1
            fi
            ;;
        vultr)
            if [ -z "${VULTR_API_KEY:-}" ]; then
                echo "❌ VULTR_API_KEY is not set"
                exit 1
            fi
            ;;
        azure)
            if [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
                echo "❌ ARM_SUBSCRIPTION_ID is not set"
                exit 1
            fi
            ;;
        digitalocean)
            if [ -z "${DIGITALOCEAN_TOKEN:-}" ]; then
                echo "❌ DIGITALOCEAN_TOKEN is not set"
                exit 1
            fi
            ;;
        hetzner)
            if [ -z "${HCLOUD_TOKEN:-}" ]; then
                echo "❌ HCLOUD_TOKEN is not set"
                exit 1
            fi
            ;;
        aws)
            if [ -z "${AWS_ACCESS_KEY_ID:-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
                echo "❌ AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY is not set"
                exit 1
            fi
            ;;
        lima)
            if ! command -v limactl &> /dev/null; then
                echo "❌ limactl is not installed"
                exit 1
            fi
            ;;
        local)
            echo "ℹ️  Using local provider"
            ;;
        oracle)
            echo "ℹ️  TODO: check for Oracle private key file"
            ;;
        *)
            echo "❌ Unknown cloud provider: ${CLOUD_PROVIDER}"
            exit 1
            ;;
    esac
    echo "✅ Cloud credentials verified for ${CLOUD_PROVIDER}"

# Load instance details from terraform output
load-instance-details:
    #!/usr/bin/env bash
    set -e
    cd {{ script_path }}/terraform/00-vm-${CLOUD_PROVIDER}
    
    # Check if terraform outputs exist
    if [ "$(terraform output -json 2>/dev/null)" = "{}" ]; then
        echo "❌ No terraform outputs found. Have you run 'just vm'?"
        exit 1
    fi
    
    # Get outputs and save to temp file
    instance_ipv4=$(terraform output -raw instance_ipv4 2>/dev/null) || { echo "❌ instance_ipv4 output not found"; exit 1; }
    instance_username=$(terraform output -raw instance_username 2>/dev/null) || { echo "❌ instance_username output not found"; exit 1; }
    instance_ssh_port=$(terraform output -raw instance_ssh_port 2>/dev/null) || { echo "❌ instance_ssh_port output not found"; exit 1; }
    
    # Save to temp file for other recipes
    cat > /tmp/vm_info.txt << EOF
    export instance_ipv4="${instance_ipv4}"
    export instance_username="${instance_username}"
    export instance_ssh_port="${instance_ssh_port}"
    EOF
    
    echo "✅ Instance details loaded"

# Wait for host and accept SSH key
wait-and-accept: load-instance-details
    #!/usr/bin/env bash
    set -e
    source /tmp/vm_info.txt
    
    # Wait for host to be available
    echo "⏳ Waiting for ${instance_ipv4} to become available on port ${instance_ssh_port}..."
    while ! (echo > /dev/tcp/${instance_ipv4}/${instance_ssh_port}) 2>/dev/null; do
        sleep 1
    done
    echo "✅ ${instance_ipv4} is now available"
    
    # Remove old fingerprint if exists
    if ssh-keygen -F ${instance_ipv4} > /dev/null 2>&1; then
        ssh-keygen -R ${instance_ipv4}
    fi
    
    # Accept new SSH fingerprint
    ssh-keyscan -H -p ${instance_ssh_port} ${instance_ipv4} >> ~/.ssh/known_hosts
    echo "✅ SSH key accepted"

# Create SSH tunnel for K3s API access
create-tunnel: load-instance-details
    #!/usr/bin/env bash
    set -e
    source /tmp/vm_info.txt
    
    # Check if tunnel already exists
    if pgrep -f "ssh.*-L 6443:localhost:6443.*${instance_ipv4}" > /dev/null; then
        echo "✅ SSH tunnel already running"
    else
        echo "🔗 Creating SSH tunnel for K3s API..."
        ssh -fN -L 6443:localhost:6443 -p ${instance_ssh_port} ${instance_username}@${instance_ipv4}
        echo "✅ SSH tunnel created"
    fi

# Check that instance state is loaded
check-instance-state: load-instance-details wait-and-accept
    @echo "✅ Instance state verified"

# Check that tunnel is running
check-tunnel: load-instance-details
    #!/usr/bin/env bash
    set -e
    source /tmp/vm_info.txt
    if ! pgrep -f "ssh.*-L 6443:localhost:6443.*${instance_ipv4}" > /dev/null; then
        echo "❌ SSH tunnel not running. Run 'just create-tunnel' first"
        exit 1
    fi
    echo "✅ SSH tunnel is active"

# --- Stage Groups ---

# Deploy infrastructure only (VM + K3s)
infra: vm wait-and-accept k3s create-tunnel
    @echo "✅ Infrastructure deployed"

# Deploy applications only (platform + workloads + routing)  
apps: platform workloads routing
    @echo "✅ Applications deployed"

# --- Utility Commands ---

# Show current instance details
info: load-instance-details
    #!/usr/bin/env bash
    source /tmp/vm_info.txt
    echo "Instance Details:"
    echo "  IP: ${instance_ipv4}"
    echo "  Username: ${instance_username}"
    echo "  SSH Port: ${instance_ssh_port}"
    echo "  Cloud Provider: ${CLOUD_PROVIDER}"

# Plan all terraform changes without applying
plan-all: check-deps check-ssh-key check-cloud-creds
    #!/usr/bin/env bash
    set -e
    stages=("00-vm-${CLOUD_PROVIDER}" "01-k3s-install" "02-platform" "03-workloads")
    for stage in "${stages[@]}"; do
        echo "📋 Planning ${stage}..."
        cd {{ script_path }}/terraform/${stage}
        terraform init
        if [ "${stage}" = "01-k3s-install" ] || [ "${stage}" = "02-platform" ]; then
            terraform plan -var="cloud_provider=${CLOUD_PROVIDER}" || true
        else
            terraform plan || true
        fi
        echo ""
    done

# Destroy specific stage
destroy stage: 
    #!/usr/bin/env bash
    set -e
    case "{{ stage }}" in
        vm)       dir="00-vm-${CLOUD_PROVIDER}" ;;
        k3s)      dir="01-k3s-install" ;;
        platform) dir="02-platform" ;;
        workloads) dir="03-workloads" ;;
        workloads-legacy) dir="03-workloads" ;;
        *) echo "❌ Unknown stage: {{ stage }}"; exit 1 ;;
    esac
    
    echo "💥 Destroying {{ stage }}..."
    cd {{ script_path }}/terraform/${dir}
    terraform init
    if [ "${dir}" = "01-k3s-install" ] || [ "${dir}" = "02-platform" ]; then
        terraform destroy -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"
    else
        terraform destroy -auto-approve
    fi

# Run from a specific stage onwards
from stage:
    #!/usr/bin/env bash
    set -e
    stages=()
    found=false
    
    for s in vm k3s platform workloads routing; do
        if [ "$s" = "{{ stage }}" ] || [ "$found" = true ]; then
            found=true
            stages+=($s)
        fi
    done
    
    if [ "$found" = false ]; then
        echo "❌ Unknown stage: {{ stage }}"
        exit 1
    fi
    
    echo "🚀 Running from {{ stage }} onwards: ${stages[@]}"
    for s in "${stages[@]}"; do
        just $s
    done