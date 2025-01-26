#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# load config
. $SCRIPT_PATH/config.sh

# Destroy the resources
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform destroy -auto-approve
cd ../../

# Cleanup server-files
rm -rf $SCRIPT_PATH/../server-files

# Cleanup kustomize certs
rm -rf $SCRIPT_PATH/../kustomize/cert-manager/certs

# delete k3s-server-ca certificates
CERTS=$(security find-certificate -a -c "k3s-server-ca" | grep "alis" | cut -d'"' -f4)
if [ -z "$CERTS" ]; then
    echo "No k3s-server-ca certificates found"
    exit 0
fi
for cert in $CERTS; do
    echo "Found certificate: $cert"
    echo "Deleting..."
     if sudo security delete-certificate -c "$cert"; then
        echo "Successfully deleted $cert"
    else
        echo "Failed to delete $cert"
    fi
done

# remove entries from /etc/hosts
if grep -q "grafana.debian-k3s" /etc/hosts; then
    sudo sed -i '' "/grafana.debian-k3s/d" /etc/hosts
    echo "Removed hosts entries containing grafana.debian-k3s"
fi
