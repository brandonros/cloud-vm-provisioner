#!/bin/bash

# Update package list
sudo apt-get update

# Upgrade all installed packages to their latest versions
sudo apt-get -y upgrade

# Dist-upgrade all installed packages to their latest versions
sudo apt-get -y dist-upgrade

# Install required packages
sudo apt-get -y install acl htop psmisc netcat-traditional

# Remove unused packages
sudo apt-get -y autoremove

# Install k9s
wget https://github.com/derailed/k9s/releases/download/v0.40.5/k9s_linux_amd64.deb
sudo apt install -y ./k9s_linux_*.deb
rm k9s_linux_*.deb

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found, installing k3s..."
    
    # install k3s
    curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server --disable=traefik --disable=metrics-server" sh -
    
    # trust cluster ssl
    echo "trusting cluster ssl"
    sudo cp /var/lib/rancher/k3s/server/tls/server-ca.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    
    # add coredns in the cluster to node dns resolution chain
    if ! sudo grep -q "nameserver 10.43.0.10" /etc/resolvconf/resolv.conf.d/tail; then
        echo "adding coredns to dns resolution chain"
        echo "nameserver 10.43.0.10" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail > /dev/null
        sudo resolvconf -u
    fi
    
    echo "k3s installation complete"
else
    echo "kubectl already installed, skipping installation"
fi

# Configure kubeconfig for user
USER_HOME="/home/debian"
KUBE_CONFIG="$USER_HOME/.kube/config"

# Check if kubeconfig exists
if [ ! -f "$KUBE_CONFIG" ]; then
    echo "Kubeconfig not found, configuring..."
    
    # Get kubeconfig from root
    KUBECONFIG=$(sudo k3s kubectl config view --raw)
    
    # Create .kube directory if it doesn't exist
    mkdir -p "$USER_HOME/.kube" 2> /dev/null
    
    # Write kubeconfig
    echo "$KUBECONFIG" > "$KUBE_CONFIG"
    chmod 600 "$KUBE_CONFIG"
    
    # Add to .bashrc if not already there
    if ! grep -q "export KUBECONFIG=$KUBE_CONFIG" "$USER_HOME/.bashrc"; then
        echo "export KUBECONFIG=$KUBE_CONFIG" >> "$USER_HOME/.bashrc"
    fi
    
    echo "Kubeconfig configured for user"
else
    echo "Kubeconfig already exists, skipping configuration"
fi

# Wait for k3s to be rolled out
export KUBECONFIG="$KUBE_CONFIG"
echo "Waiting for k3s components to be rolled out..."

# Wait for deployments to be created
kubectl wait deployment -n kube-system coredns --for create --timeout=300s
kubectl wait deployment -n kube-system local-path-provisioner --for create --timeout=300s

# Wait for deployments to be available
kubectl wait deployment -n kube-system coredns --for condition=Available=True --timeout=300s
kubectl wait deployment -n kube-system local-path-provisioner --for condition=Available=True --timeout=300s

echo "k3s components are ready"
