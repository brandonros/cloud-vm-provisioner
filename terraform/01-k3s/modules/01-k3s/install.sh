#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found, installing k3s..."
    
    # install k3s
    curl -sfL https://get.k3s.io | sudo INSTALL_K3S_VERSION="v1.33.1+k3s1" INSTALL_K3S_EXEC="server --disable=traefik --disable=metrics-server" sh -
    
    # trust cluster ssl
    echo "trusting cluster ssl"
    sudo cp /var/lib/rancher/k3s/server/tls/server-ca.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    
    # add coredns in the cluster to node dns resolution chain
    # TODO: edit /etc/systemd/resolved.conf
    # TODO: sudo systemctl restart systemd-resolved
    
    echo "k3s installation complete"
else
    echo "kubectl already installed, skipping installation"
fi

# Configure kubeconfig for user
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
