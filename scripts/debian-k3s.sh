#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# load config
. $SCRIPT_PATH/config.sh

# get instance details
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform apply -auto-approve
instance_ipv4=$(terraform output -raw instance_ipv4)
instance_username=$(terraform output -raw instance_username)
cd ../../

# clone debian-k3s
rm -rf /tmp/debian-k3s
git clone --single-branch --branch graphite git@github.com:brandonros/debian-k3s.git /tmp/debian-k3s
pushd /tmp/debian-k3s

# check for existing tunnel and spawn if needed
if ! pgrep -f "ssh.*-L 6443:localhost:6443.*$instance_ipv4" > /dev/null; then
    echo "Starting SSH tunnel..."
    ssh -fN -L 6443:localhost:6443 $instance_username@$instance_ipv4
else
    echo "SSH tunnel already running"
fi

# set kubeconfig
export DEPLOY_MODE="cloud"
export INSTANCE_IPV4="$instance_ipv4"
export SERVER_FILES_PATH="$SCRIPT_PATH/../server-files"

# rollout
/tmp/debian-k3s/scripts/deploy.sh

# clean up
popd
rm -rf /tmp/debian-k3s
