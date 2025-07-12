#!/bin/bash

# Update package list
sudo apt-get update

# Install + configure needrestart to restart daemons after library updates.
sudo apt-get install -y needrestart
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

# Upgrade all installed packages to their latest versions
sudo apt-get -y upgrade
sudo needrestart -r a

# Dist-upgrade all installed packages to their latest versions
# sudo apt-get -y dist-upgrade
# TODO: i think this is bad practice because we don't reboot into the new kernel after

# Install required packages to help debug issues
sudo apt-get -y install acl htop psmisc netcat-traditional

# Remove unused packages
sudo apt-get -y autoremove

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
K9S_VERSION="v0.50.7"
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
