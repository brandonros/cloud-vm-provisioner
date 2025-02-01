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
if [[ "$OSTYPE" == "darwin"* ]]
then
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
else
    echo "TODO: delete k3s-server-ca certificates on non-macOS systems"
fi

# remove entries from /etc/hosts
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]
then
    if grep -q "grafana.debian-k3s" /etc/hosts; then
        sudo sed -i '' "/grafana.debian-k3s/d" /etc/hosts
        echo "Removed hosts entries containing grafana.debian-k3s"
    else
        echo "No hosts entries containing grafana.debian-k3s found"
    fi
else
    echo "TODO: remove entries from /etc/hosts on non-macOS and non-Linux systems"
fi
