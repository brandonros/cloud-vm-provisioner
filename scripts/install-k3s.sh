#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo)"
    exit 1
fi

# install k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --disable=traefik --disable=metrics-server" sh -

# wait for k3s to be ready
max_retries=10
retry_count=0
while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    if [ $retry_count -eq $max_retries ]; then
        echo >&2 "Timeout waiting for k3s to be ready after $max_retries attempts"
        exit 1
    fi
    echo "Waiting for k3s to be ready... (attempt $((retry_count + 1))/$max_retries)"
    sleep 6
    retry_count=$((retry_count + 1))
done

# trust cluster ssl
cp /var/lib/rancher/k3s/server/tls/server-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# add coredns in the cluster to node dns resolution chain
apt-get install -y systemd-resolved
echo "DNS=10.43.0.10" | tee -a /etc/systemd/resolved.conf
systemctl restart systemd-resolved

# copy kubeconfig to home directory for root
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# copy kubeconfig to home directory for debian user
mkdir -p /home/debian/.kube
cp /etc/rancher/k3s/k3s.yaml /home/debian/.kube/config
chown -R debian:debian /home/debian/.kube

# install k9s
wget https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.deb
apt install -y ./k9s_linux_amd64.deb
rm k9s_linux_amd64.deb
