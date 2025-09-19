#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

echo "Starting k3s installation process..."

# ====================================
# Step 1: Install system dependencies
# ====================================
echo "Installing system dependencies..."

# Update package list
sudo apt-get update

# Install + configure needrestart to restart daemons after library updates.
sudo apt-get install -y needrestart
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

# Upgrade all installed packages to their latest versions
sudo -E apt-get -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo needrestart -r a

# Install required packages to help debug issues
sudo apt-get -y install acl htop psmisc netcat-traditional

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_K9S="amd64"
    ARCH_HELM="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_K9S="arm64"
    ARCH_HELM="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Install k9s
K9S_VERSION="v0.50.11"
if ! command -v k9s &> /dev/null; then
    wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_linux_${ARCH_K9S}.deb
    sudo apt install -y ./k9s_linux_*.deb
    rm k9s_linux_*.deb
else
    echo "k9s is already installed"
fi

# Install helm
HELM_VERSION="v3.18.3"
if ! command -v helm &> /dev/null; then
    wget https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH_HELM}.tar.gz
    tar -xf helm-${HELM_VERSION}-linux-${ARCH_HELM}.tar.gz
    sudo install -m 755 linux-${ARCH_HELM}/helm /usr/local/bin/helm
    rm -rf linux-${ARCH_HELM}
else
    echo "helm is already installed"
fi

echo "System dependencies installed successfully"

# ====================================
# Step 2: Install k3s
# ====================================
echo "Installing k3s..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found, installing k3s..."
    
    # install k3s
    curl -sfL https://get.k3s.io | sudo INSTALL_K3S_VERSION="v1.33.4+k3s1" INSTALL_K3S_EXEC="server --disable=traefik --disable=metrics-server" sh -
    
    # trust cluster ssl
    echo "trusting cluster ssl"
    sudo cp /var/lib/rancher/k3s/server/tls/server-ca.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    
    echo "k3s installation complete"
else
    echo "kubectl already installed, skipping installation"
fi

# ====================================
# Step 3: Configure kubeconfig
# ====================================
echo "Configuring kubeconfig..."

KUBE_CONFIG="$HOME/.kube/config"

# Check if kubeconfig exists
if [ ! -f "$KUBE_CONFIG" ]; then
    echo "Kubeconfig not found, configuring..."
    
    # Get kubeconfig from root
    KUBECONFIG=$(sudo k3s kubectl config view --raw)
    
    # Create .kube directory if it doesn't exist
    mkdir -p "$HOME/.kube" 2> /dev/null
    
    # Write kubeconfig
    echo "$KUBECONFIG" > "$KUBE_CONFIG"
    chmod 600 "$KUBE_CONFIG"
    
    # Add to .bashrc if not already there
    if ! grep -q "export KUBECONFIG=$KUBE_CONFIG" "$HOME/.bashrc"; then
        echo "export KUBECONFIG=$KUBE_CONFIG" >> "$HOME/.bashrc"
    fi
    
    echo "Kubeconfig configured for user"
else
    echo "Kubeconfig already exists, skipping configuration"
fi

# ====================================
# Step 4: Wait for k3s to be ready
# ====================================
export KUBECONFIG="$KUBE_CONFIG"
echo "Waiting for k3s components to be rolled out..."

# Wait for deployments to be created
kubectl wait deployment -n kube-system coredns --for create --timeout=300s
kubectl wait deployment -n kube-system local-path-provisioner --for create --timeout=300s

# Wait for deployments to be available
kubectl wait deployment -n kube-system coredns --for condition=Available=True --timeout=300s
kubectl wait deployment -n kube-system local-path-provisioner --for condition=Available=True --timeout=300s

echo "✅ k3s installation and configuration complete!"
echo "k3s components are ready"