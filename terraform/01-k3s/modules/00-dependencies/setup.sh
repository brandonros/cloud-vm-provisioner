#!/bin/bash

# Update package list
sudo apt-get update

# Install needrestart
sudo apt-get install -y needrestart

# Configure for automatic restarts in non-interactive environments
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

# Install k9s
if ! command -v k9s &> /dev/null; then
    wget https://github.com/derailed/k9s/releases/download/v0.40.5/k9s_linux_amd64.deb
    sudo apt install -y ./k9s_linux_*.deb
    rm k9s_linux_*.deb
else
    echo "k9s is already installed"
fi

# Install helm
if ! command -v helm &> /dev/null; then
    wget https://get.helm.sh/helm-v3.17.2-linux-amd64.tar.gz
    tar -xf helm-v3.17.2-linux-amd64.tar.gz
    sudo install -m 755 linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64
else
    echo "helm is already installed"
fi
