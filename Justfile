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

# Run all stages: vm, k3s, platform, workloads
all: check-deps check-ssh-key check-cloud-creds vm wait-and-accept k3s create-tunnel platform workloads

# Stage 1: Provision VM infrastructure
vm: check-deps check-ssh-key check-cloud-creds
    #!/usr/bin/env bash
    set -e
    echo "🚀 Provisioning VM infrastructure..."
    cd {{ script_path }}/terraform/00-vm
    terraform init
    terraform apply -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}"

# Stage 2: Install K3s on the VM
k3s: check-instance-state
    #!/usr/bin/env bash
    set -e
    echo "🚀 Installing K3s cluster..."
    cd {{ script_path }}/terraform/01-k3s
    terraform init
    terraform apply -auto-approve

# Stage 3: Deploy platform services
platform: check-tunnel
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying platform services..."
    cd {{ script_path }}/terraform/02-platform
    terraform init
    terraform apply -auto-approve

# Stage 4: Deploy workloads
workloads:
    #!/usr/bin/env bash
    set -e
    echo "🚀 Deploying workloads..."
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
    cd {{ script_path }}/terraform/00-vm
    terraform init
    terraform destroy -auto-approve -var="cloud_provider=${CLOUD_PROVIDER}" || true
    
    # Clean up temp files
    rm -f /tmp/vm_info.txt
    rm -rf {{ script_path }}/terraform/01-k3s/kubeconfig
    
    # Clean up all tfstate files
    cd {{ script_path }}/terraform
    find ./00-vm ./01-k3s ./02-platform ./03-workloads \
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
    cd {{ script_path }}/terraform/00-vm
    
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

# Deploy applications only (platform + workloads)  
apps: platform workloads
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
    for stage in 00-vm 01-k3s 02-platform 03-workloads; do
        echo "📋 Planning ${stage}..."
        cd {{ script_path }}/terraform/${stage}
        terraform init
        if [ "${stage}" = "00-vm" ]; then
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
        vm)       dir="00-vm" ;;
        k3s)      dir="01-k3s" ;;
        platform) dir="02-platform" ;;
        workloads) dir="03-workloads" ;;
        *) echo "❌ Unknown stage: {{ stage }}"; exit 1 ;;
    esac
    
    echo "💥 Destroying {{ stage }}..."
    cd {{ script_path }}/terraform/${dir}
    terraform init
    if [ "${dir}" = "00-vm" ]; then
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
    
    for s in vm k3s platform workloads; do
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